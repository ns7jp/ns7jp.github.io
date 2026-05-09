#!/usr/bin/env bash
#
# test-security-baseline.sh
# ============================================================================
# Linux サーバーのセキュリティ基本設定を読み取り、現状を JSON で出力します。
# PowerShell 版 Test-SecurityBaseline.ps1 の Linux 対応版にあたります。
#
# 確認項目:
#   1. SSH    — PermitRootLogin / PasswordAuthentication / Port
#   2. ホストファイアウォール — ufw (Debian系) または firewalld (RHEL系) の状態
#   3. fail2ban — インストール状況とサービス稼働状態
#   4. 自動セキュリティ更新 — unattended-upgrades / dnf-automatic
#   5. 強制アクセス制御 — SELinux (getenforce) または AppArmor (aa-status)
#   6. 監査 — auditd の稼働状態
#   7. パッケージ更新の鮮度 — apt/dnf キャッシュの最終更新日時
#
# 想定:
#   - 設定変更は一切行いません (確認・記録のみ)
#   - 一部の項目は root 権限 / sudo がないと取得できない (例: sshd_config, aa-status)
#     その場合は Status を "Unknown" として記録する
#
# 用途:
#   - サーバー受領時のベースライン確認
#   - 月次のセキュリティ棚卸し
#   - インシデント後の現状記録
# ============================================================================

set -euo pipefail

OUTPUT_PATH=""

usage() {
  cat <<USAGE
使用方法: $0 [-o OUTPUT_PATH]

オプション:
  -o  結果 JSON の保存先 (省略時は標準出力)
  -h  このヘルプを表示
USAGE
}

while getopts "o:h" opt; do
  case "$opt" in
    o) OUTPUT_PATH="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

# ---------------------------- ヘルパ ----------------------------
# sshd_config から指定キーの値を取得 (大小無視。コメント行は除外)
sshd_value() {
  local key="$1"
  if [[ -r /etc/ssh/sshd_config ]]; then
    grep -iE "^\s*${key}\s+" /etc/ssh/sshd_config 2>/dev/null \
      | grep -v '^\s*#' | tail -1 | awk '{print $2}'
  fi
}

# サービスの稼働状態を取得
service_state() {
  local name="$1"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl is-active "$name" 2>/dev/null || echo "inactive"
  else
    echo "Unknown"
  fi
}

# ---------------------------- SSH 設定 ----------------------------
ssh_root="$(sshd_value PermitRootLogin)"
ssh_password="$(sshd_value PasswordAuthentication)"
ssh_port="$(sshd_value Port)"
[[ -z "$ssh_root" ]]     && ssh_root="default(prohibit-password)"
[[ -z "$ssh_password" ]] && ssh_password="default(yes)"
[[ -z "$ssh_port" ]]     && ssh_port="22"

# ---------------------------- ファイアウォール ----------------------------
fw_kind="none"; fw_state="Unknown"; fw_rule_count=""
if command -v ufw >/dev/null 2>&1; then
  fw_kind="ufw"
  fw_state="$(ufw status 2>/dev/null | awk '/^Status:/{print $2}')"
  fw_rule_count="$(ufw status numbered 2>/dev/null | grep -c '^\[' || true)"
elif command -v firewall-cmd >/dev/null 2>&1; then
  fw_kind="firewalld"
  fw_state="$(firewall-cmd --state 2>/dev/null || echo Unknown)"
  fw_rule_count="$(firewall-cmd --list-all 2>/dev/null | grep -cE '^\s+(services|ports):' || true)"
elif command -v iptables >/dev/null 2>&1; then
  fw_kind="iptables"
  fw_rule_count="$(iptables -S 2>/dev/null | wc -l || echo 0)"
  fw_state="rules: ${fw_rule_count}"
fi

# ---------------------------- fail2ban ----------------------------
f2b_installed=false; f2b_state="not-installed"
if command -v fail2ban-client >/dev/null 2>&1 || dpkg -l fail2ban >/dev/null 2>&1 || rpm -q fail2ban >/dev/null 2>&1; then
  f2b_installed=true
  f2b_state="$(service_state fail2ban)"
fi

# ---------------------------- 自動更新 ----------------------------
auto_update_kind="none"; auto_update_state="Unknown"
if [[ -f /etc/apt/apt.conf.d/50unattended-upgrades ]] || dpkg -l unattended-upgrades >/dev/null 2>&1; then
  auto_update_kind="unattended-upgrades"
  auto_update_state="$(service_state unattended-upgrades)"
elif command -v dnf-automatic >/dev/null 2>&1 || rpm -q dnf-automatic >/dev/null 2>&1; then
  auto_update_kind="dnf-automatic"
  auto_update_state="$(service_state dnf-automatic.timer)"
fi

# ---------------------------- MAC (SELinux / AppArmor) ----------------------------
mac_kind="none"; mac_state="Unknown"
if command -v getenforce >/dev/null 2>&1; then
  mac_kind="SELinux"
  mac_state="$(getenforce 2>/dev/null || echo Unknown)"
elif command -v aa-status >/dev/null 2>&1; then
  mac_kind="AppArmor"
  if aa-status --enabled 2>/dev/null; then
    mac_state="enabled"
  else
    mac_state="disabled"
  fi
fi

# ---------------------------- auditd ----------------------------
audit_state="$(service_state auditd 2>/dev/null || echo Unknown)"

# ---------------------------- パッケージキャッシュ鮮度 ----------------------------
pkg_cache_age="Unknown"
if [[ -r /var/cache/apt/pkgcache.bin ]]; then
  mtime="$(stat -c %Y /var/cache/apt/pkgcache.bin 2>/dev/null || echo 0)"
  now="$(date +%s)"
  pkg_cache_age="$(( (now - mtime) / 86400 )) days"
elif command -v dnf >/dev/null 2>&1 && [[ -d /var/cache/dnf ]]; then
  mtime="$(stat -c %Y /var/cache/dnf 2>/dev/null || echo 0)"
  now="$(date +%s)"
  pkg_cache_age="$(( (now - mtime) / 86400 )) days"
fi

# ---------------------------- JSON 整形 ----------------------------
JSON_OUT="$(
  CHECKED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  HOSTNAME_VAL="$(hostname)" \
  SSH_ROOT="$ssh_root" \
  SSH_PASSWORD="$ssh_password" \
  SSH_PORT="$ssh_port" \
  FW_KIND="$fw_kind" \
  FW_STATE="$fw_state" \
  FW_RULE_COUNT="$fw_rule_count" \
  F2B_INSTALLED="$f2b_installed" \
  F2B_STATE="$f2b_state" \
  AUTO_UPDATE_KIND="$auto_update_kind" \
  AUTO_UPDATE_STATE="$auto_update_state" \
  MAC_KIND="$mac_kind" \
  MAC_STATE="$mac_state" \
  AUDIT_STATE="$audit_state" \
  PKG_CACHE_AGE="$pkg_cache_age" \
  python3 - <<'PYEOF'
import json, os

def status_for(key, value):
    """項目ごとの判定ロジック。OK / Warning / Unknown を返す。"""
    v = (value or "").strip().lower()
    if not v or v in ("unknown", ""):
        return "Unknown"
    if key == "PermitRootLogin":
        return "OK" if v in ("no", "prohibit-password", "default(prohibit-password)") else "Warning"
    if key == "PasswordAuthentication":
        return "OK" if v in ("no",) else "Warning"
    if key == "FirewallState":
        return "OK" if v in ("active", "running") else "Warning"
    if key == "Fail2banState":
        return "OK" if v == "active" else "Warning"
    if key == "AutoUpdateState":
        return "OK" if v in ("active", "activating") else "Warning"
    if key == "MACState":
        return "OK" if v in ("enforcing", "enabled") else "Warning"
    if key == "AuditdState":
        return "OK" if v == "active" else "Warning"
    return "Unknown"

ssh_root = os.environ.get("SSH_ROOT", "")
ssh_password = os.environ.get("SSH_PASSWORD", "")
fw_kind = os.environ.get("FW_KIND", "none")
fw_state = os.environ.get("FW_STATE", "")
f2b_installed = os.environ.get("F2B_INSTALLED", "false") == "true"
f2b_state = os.environ.get("F2B_STATE", "")
auto_kind = os.environ.get("AUTO_UPDATE_KIND", "none")
auto_state = os.environ.get("AUTO_UPDATE_STATE", "")
mac_kind = os.environ.get("MAC_KIND", "none")
mac_state = os.environ.get("MAC_STATE", "")
audit_state = os.environ.get("AUDIT_STATE", "")

checks = [
    {"Name": "SSH PermitRootLogin", "Value": ssh_root,
     "Status": status_for("PermitRootLogin", ssh_root)},
    {"Name": "SSH PasswordAuthentication", "Value": ssh_password,
     "Status": status_for("PasswordAuthentication", ssh_password)},
    {"Name": "SSH Port", "Value": os.environ.get("SSH_PORT", ""), "Status": "OK"},
    {"Name": f"Firewall ({fw_kind})", "Value": fw_state,
     "Status": status_for("FirewallState", fw_state) if fw_kind != "none" else "Warning"},
    {"Name": "Fail2ban",
     "Value": f2b_state if f2b_installed else "not-installed",
     "Status": status_for("Fail2banState", f2b_state) if f2b_installed else "Warning"},
    {"Name": f"Auto Update ({auto_kind})", "Value": auto_state,
     "Status": status_for("AutoUpdateState", auto_state) if auto_kind != "none" else "Warning"},
    {"Name": f"MAC ({mac_kind})", "Value": mac_state,
     "Status": status_for("MACState", mac_state) if mac_kind != "none" else "Warning"},
    {"Name": "Auditd", "Value": audit_state, "Status": status_for("AuditdState", audit_state)},
    {"Name": "Package Cache Age", "Value": os.environ.get("PKG_CACHE_AGE", ""), "Status": "OK"},
]

statuses = [c["Status"] for c in checks]
overall = "OK" if all(s == "OK" for s in statuses) else \
          "Warning" if "Warning" in statuses else "Unknown"

result = {
    "CheckedAt": os.environ.get("CHECKED_AT", ""),
    "Hostname":  os.environ.get("HOSTNAME_VAL", ""),
    "FirewallRuleCount": os.environ.get("FW_RULE_COUNT", "") or None,
    "Checks": checks,
    "Overall": overall,
}

print(json.dumps(result, ensure_ascii=False, indent=2))
PYEOF
)"

# ---------------------------- 出力 ----------------------------
if [[ -n "$OUTPUT_PATH" ]]; then
  printf '%s\n' "$JSON_OUT" > "$OUTPUT_PATH"
  echo "Saved security baseline result to $OUTPUT_PATH"
else
  printf '%s\n' "$JSON_OUT"
fi
