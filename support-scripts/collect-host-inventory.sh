#!/usr/bin/env bash
#
# collect-host-inventory.sh
# ============================================================================
# Linux ホストの基本情報を JSON 形式で出力する読み取り専用スクリプトです。
# PowerShell 版 Collect-PcInventory.ps1 の Linux 対応版にあたります。
#
# 想定環境:
#   - Ubuntu / Debian / RHEL / CentOS / Fedora など主要な systemd 系 Linux
#   - 設定変更・削除・サービス再起動は一切行いません
#
# 用途:
#   - 問い合わせ受付時に「対象サーバーが何で、どの OS / カーネル / 構成か」を確認する
#   - サーバー入替・棚卸しの初期記録
#   - チケット添付用の機械可読フォーマット (JSON) としての記録
#
# 初学者向けの見方:
#   - set -euo pipefail はエラー発生・未定義変数で即停止する安全モード
#   - /etc/os-release は Linux ディストリ間で標準化されたメタファイル
#   - command -v xxx は xxx コマンドの存在確認 (which より移植性が高い)
#   - JSON 整形は python3 -c で行い、手動エスケープのバグを防ぐ
# ============================================================================

set -euo pipefail

OUTPUT_PATH=""

usage() {
  cat <<USAGE
使用方法: $0 [-o OUTPUT_PATH]

オプション:
  -o PATH   結果 JSON の保存先。省略時は標準出力に書き出す。
  -h        このヘルプを表示する。

例:
  $0                                  # 標準出力に JSON を表示
  $0 -o ./host-inventory.json         # ファイルに保存
USAGE
}

while getopts "o:h" opt; do
  case "$opt" in
    o) OUTPUT_PATH="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

# ---------------------------- データ収集 ----------------------------
collected_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
hostname_val="$(hostname)"

# OS 情報 (/etc/os-release から取得)
os_pretty=""; os_id=""; os_version=""
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  os_pretty="${PRETTY_NAME:-${NAME:-unknown}}"
  os_id="${ID:-unknown}"
  os_version="${VERSION_ID:-unknown}"
fi

kernel_val="$(uname -r)"

# 稼働時間 — uptime -p が無い古い環境は /proc/uptime からフォールバック
if uptime -p >/dev/null 2>&1; then
  uptime_val="$(uptime -p)"
else
  uptime_val="$(awk '{
    d=int($1/86400); h=int(($1%86400)/3600); m=int(($1%3600)/60);
    printf "up %d days, %d hours, %d minutes", d, h, m
  }' /proc/uptime)"
fi

cpu_model="$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null || echo unknown)"
cpu_logical="$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 0)"

mem_total_kb="$(awk '/^MemTotal/{print $2}' /proc/meminfo)"
mem_total_gb="$(awk -v k="$mem_total_kb" 'BEGIN{printf "%.2f", k/1024/1024}')"

timezone_val="$(date +%Z)"

# ファイルシステム使用状況 — tmpfs / overlay / squashfs などの一時 FS を除外
fs_lines="$(df -B1 --output=source,fstype,size,used,avail,pcent,target 2>/dev/null \
  | tail -n +2 \
  | awk '$2 != "tmpfs" && $2 != "devtmpfs" && $2 != "squashfs" && $2 != "overlay" && $2 != "" {print}')"

# IPv4 アドレス (ループバック除外)。古い環境や iproute2 未インストールでも止まらないよう || true で吸収。
ipv4_lines=""
if command -v ip >/dev/null 2>&1; then
  ipv4_lines="$(ip -4 -o addr show 2>/dev/null | awk '$2 != "lo" {print $2"\t"$4}' || true)"
fi

# 直近インストール 5 件 (Debian 系: dpkg.log / RHEL 系: rpm -qa --last)
recent_packages=""
if command -v dpkg-query >/dev/null 2>&1 && compgen -G "/var/log/dpkg.log*" >/dev/null; then
  recent_packages="$(grep ' install ' /var/log/dpkg.log* 2>/dev/null \
    | awk '{print $4}' | tail -5 | tr '\n' ',' | sed 's/,$//')"
elif command -v rpm >/dev/null 2>&1; then
  recent_packages="$(rpm -qa --last 2>/dev/null | head -5 | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')"
fi

# ---------------------------- JSON 整形 ----------------------------
# 値はすべて環境変数経由で python3 に渡し、json.dumps で安全にエスケープする
JSON_OUT="$(
  COLLECTED_AT="$collected_at" \
  HOSTNAME_VAL="$hostname_val" \
  OS_PRETTY="$os_pretty" \
  OS_ID="$os_id" \
  OS_VERSION="$os_version" \
  KERNEL_VAL="$kernel_val" \
  UPTIME_VAL="$uptime_val" \
  CPU_MODEL="$cpu_model" \
  CPU_LOGICAL="$cpu_logical" \
  MEM_TOTAL_GB="$mem_total_gb" \
  TIMEZONE_VAL="$timezone_val" \
  FS_LINES="$fs_lines" \
  IPV4_LINES="$ipv4_lines" \
  RECENT_PACKAGES="$recent_packages" \
  python3 - <<'PYEOF'
import json, os

def parse_filesystems(text):
    out = []
    for line in (text or "").strip().splitlines():
        parts = line.split()
        if len(parts) < 7:
            continue
        source, fstype, size, used, avail, pcent, target = parts[:7]
        try:
            size_gb  = round(int(size) / 1024**3, 2)
            used_gb  = round(int(used) / 1024**3, 2)
            avail_gb = round(int(avail) / 1024**3, 2)
        except ValueError:
            size_gb = used_gb = avail_gb = None
        out.append({
            "Source": source, "Filesystem": fstype, "MountPoint": target,
            "SizeGB": size_gb, "UsedGB": used_gb, "AvailGB": avail_gb,
            "PercentUsed": pcent.rstrip("%"),
        })
    return out

def parse_ipv4(text):
    out = []
    for line in (text or "").strip().splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            out.append({"Interface": parts[0], "Address": parts[1]})
    return out

inventory = {
    "CollectedAt": os.environ.get("COLLECTED_AT", ""),
    "Hostname":    os.environ.get("HOSTNAME_VAL", ""),
    "OS": {
        "Name":    os.environ.get("OS_PRETTY", ""),
        "Id":      os.environ.get("OS_ID", ""),
        "Version": os.environ.get("OS_VERSION", ""),
        "Kernel":  os.environ.get("KERNEL_VAL", ""),
    },
    "Uptime": os.environ.get("UPTIME_VAL", ""),
    "CPU": {
        "Model":        os.environ.get("CPU_MODEL", ""),
        "LogicalCores": int(os.environ.get("CPU_LOGICAL", "0") or 0),
    },
    "Memory": {
        "TotalGB": float(os.environ.get("MEM_TOTAL_GB", "0") or 0),
    },
    "Timezone":       os.environ.get("TIMEZONE_VAL", ""),
    "Filesystems":    parse_filesystems(os.environ.get("FS_LINES", "")),
    "IPv4":           parse_ipv4(os.environ.get("IPV4_LINES", "")),
    "RecentPackages": os.environ.get("RECENT_PACKAGES", ""),
}

print(json.dumps(inventory, ensure_ascii=False, indent=2))
PYEOF
)"

# ---------------------------- 出力 ----------------------------
if [[ -n "$OUTPUT_PATH" ]]; then
  printf '%s\n' "$JSON_OUT" > "$OUTPUT_PATH"
  echo "Saved host inventory to $OUTPUT_PATH"
else
  printf '%s\n' "$JSON_OUT"
fi
