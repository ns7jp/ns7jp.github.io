#!/usr/bin/env bash
#
# test-disk-capacity.sh
# ============================================================================
# 各マウントポイントの使用率と inode 使用率を確認する読み取り専用スクリプトです。
# PowerShell 版 Test-DiskCapacity.ps1 の Linux 対応版にあたります。
#
# 確認項目:
#   1. ローカルファイルシステムの容量・使用率 (df -B1)
#   2. inode 使用率 (df -i) — 「容量はあるのに書き込めない」現象の検出に必須
#   3. 物理デバイスの SMART 健康状態 (smartctl が利用できる環境のみ。任意)
#
# 想定:
#   - GNU coreutils の df を前提 (FreeBSD などでは出力フォーマットが異なる)
#   - smartctl は smartmontools パッケージで提供。root 権限がないと SMART は読めない
#   - 設定変更は一切行いません
#
# 用途:
#   - 「PC / サーバーが遅い」「ログが書けない」問い合わせの一次確認
#   - 容量逼迫前の棚卸し (定期実行向け)
# ============================================================================

set -euo pipefail

WARNING_PERCENT=80
INODE_WARNING_PERCENT=80
OUTPUT_PATH=""

usage() {
  cat <<USAGE
使用方法: $0 [-w PERCENT] [-i PERCENT] [-o OUTPUT_PATH]

オプション:
  -w  容量警告のしきい値 (既定: 80%)
  -i  inode 警告のしきい値 (既定: 80%)
  -o  結果 JSON の保存先 (省略時は標準出力)
USAGE
}

while getopts "w:i:o:h" opt; do
  case "$opt" in
    w) WARNING_PERCENT="$OPTARG" ;;
    i) INODE_WARNING_PERCENT="$OPTARG" ;;
    o) OUTPUT_PATH="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

# ---------------------------- 容量取得 ----------------------------
fs_lines="$(df -B1 --output=source,fstype,size,used,avail,pcent,target 2>/dev/null \
  | tail -n +2 \
  | awk '$2 != "tmpfs" && $2 != "devtmpfs" && $2 != "squashfs" && $2 != "overlay" && $2 != "" {print}')"

# ---------------------------- inode 取得 ----------------------------
# df は -i と --output を同時指定できないため、--output に inode 列 (itotal/iused/iavail/ipcent) を指定する。
inode_lines="$(df --output=source,fstype,itotal,iused,iavail,ipcent,target 2>/dev/null \
  | tail -n +2 \
  | awk '$2 != "tmpfs" && $2 != "devtmpfs" && $2 != "squashfs" && $2 != "overlay" && $2 != "" {print}' || true)"

# ---------------------------- SMART (任意) ----------------------------
smart_status=""
if command -v smartctl >/dev/null 2>&1; then
  # /dev/sd* または /dev/nvme*n1 を対象に簡易確認
  for dev in $(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk" {print "/dev/"$1}'); do
    health="$(smartctl -H "$dev" 2>/dev/null \
      | awk -F': ' '/SMART overall-health|SMART Health Status/{print $2; exit}' \
      | tr -d ' ')"
    [[ -z "$health" ]] && health="Unknown"
    smart_status+="${dev}|${health}"$'\n'
  done
fi

# ---------------------------- JSON 整形 ----------------------------
JSON_OUT="$(
  CHECKED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  HOSTNAME_VAL="$(hostname)" \
  WARNING_PERCENT="$WARNING_PERCENT" \
  INODE_WARNING_PERCENT="$INODE_WARNING_PERCENT" \
  FS_LINES="$fs_lines" \
  INODE_LINES="$inode_lines" \
  SMART_STATUS="$smart_status" \
  python3 - <<'PYEOF'
import json, os

warn_pct = int(os.environ.get("WARNING_PERCENT", "80") or 80)
inode_warn_pct = int(os.environ.get("INODE_WARNING_PERCENT", "80") or 80)

def parse_capacity(text):
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
            pct = int(pcent.rstrip("%"))
        except ValueError:
            continue
        out.append({
            "Source": source, "Filesystem": fstype, "MountPoint": target,
            "SizeGB": size_gb, "UsedGB": used_gb, "AvailGB": avail_gb,
            "PercentUsed": pct,
            "Status": "Warning" if pct >= warn_pct else "OK",
        })
    return out

def parse_inode(text):
    out = []
    for line in (text or "").strip().splitlines():
        parts = line.split()
        if len(parts) < 7:
            continue
        source, fstype, itotal, iused, iavail, ipcent, target = parts[:7]
        try:
            ipct = int(ipcent.rstrip("%"))
        except ValueError:
            continue
        out.append({
            "Source": source, "MountPoint": target,
            "InodesTotal": itotal, "InodesUsed": iused, "InodesAvailable": iavail,
            "PercentUsed": ipct,
            "Status": "Warning" if ipct >= inode_warn_pct else "OK",
        })
    return out

def parse_smart(text):
    out = []
    for line in (text or "").strip().splitlines():
        parts = line.split("|")
        if len(parts) >= 2:
            health = parts[1]
            status = "OK" if health.upper() in ("PASSED", "OK") else "Warning"
            out.append({"Device": parts[0], "Health": health, "Status": status})
    return out

filesystems = parse_capacity(os.environ.get("FS_LINES", ""))
inodes      = parse_inode(os.environ.get("INODE_LINES", ""))
smart       = parse_smart(os.environ.get("SMART_STATUS", ""))

overall = "OK"
if any(x["Status"] == "Warning" for x in filesystems + inodes + smart):
    overall = "Warning"

result = {
    "CheckedAt": os.environ.get("CHECKED_AT", ""),
    "Hostname":  os.environ.get("HOSTNAME_VAL", ""),
    "Thresholds": {
        "CapacityWarningPercent": warn_pct,
        "InodeWarningPercent": inode_warn_pct,
    },
    "Filesystems": filesystems,
    "Inodes": inodes,
    "Smart": smart,
    "Overall": overall,
}

print(json.dumps(result, ensure_ascii=False, indent=2))
PYEOF
)"

# ---------------------------- 出力 ----------------------------
if [[ -n "$OUTPUT_PATH" ]]; then
  printf '%s\n' "$JSON_OUT" > "$OUTPUT_PATH"
  echo "Saved disk capacity result to $OUTPUT_PATH"
else
  printf '%s\n' "$JSON_OUT"
fi
