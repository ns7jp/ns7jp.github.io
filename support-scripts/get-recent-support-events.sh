#!/usr/bin/env bash
#
# get-recent-support-events.sh
# ============================================================================
# journald (systemd) から直近の警告 / エラーを CSV 形式で抽出します。
# PowerShell 版 Get-RecentSupportEvents.ps1 の Linux 対応版にあたります。
#
# 抽出条件:
#   - 過去 N 時間 (既定 24 時間)
#   - priority <= warning (emerg / alert / crit / err / warning)
#
# 想定:
#   - systemd を採用したディストリ (Ubuntu 16.04 以降, RHEL 7 以降など)
#   - journalctl で読み取り可能な権限 (一般ユーザーでも自分のログは読める)
#
# 用途:
#   - サーバー不調・サービス異常終了・OOM Kill 等の調査における一次確認
#   - チケット添付用の構造化抽出 (CSV)
# ============================================================================

set -euo pipefail

HOURS=24
OUTPUT_PATH=""
MAX_RECORDS=200

usage() {
  cat <<USAGE
使用方法: $0 [-H HOURS] [-n MAX_RECORDS] [-o OUTPUT_PATH]

オプション:
  -H  さかのぼる時間数 (既定: 24)
  -n  抽出する最大件数 (既定: 200)
  -o  CSV の保存先 (省略時は標準出力)
USAGE
}

while getopts "H:n:o:h" opt; do
  case "$opt" in
    H) HOURS="$OPTARG" ;;
    n) MAX_RECORDS="$OPTARG" ;;
    o) OUTPUT_PATH="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

# ---------------------------- 前提チェック ----------------------------
if ! command -v journalctl >/dev/null 2>&1; then
  echo "ERROR: journalctl が見つかりません。systemd を採用していないシステムでは未対応です。" >&2
  exit 2
fi

# ---------------------------- ログ抽出 ----------------------------
# --priority=warning は warning(4) 以上の重大度 (emerg=0 〜 warning=4) を抽出します。
# --output=json で機械可読形式にしてから、必要列だけ抽出 → CSV 化します。
# メッセージは長すぎるとチケットで読みにくいため 500 文字まで切ります。

raw_json="$(journalctl --no-pager \
  --priority=warning \
  --since="${HOURS} hours ago" \
  --output=json 2>/dev/null \
  | tail -n "$MAX_RECORDS" \
  || true)"

# ---------------------------- CSV 整形 ----------------------------
CSV_OUT="$(
  RAW_JSON="$raw_json" \
  HOURS_VAL="$HOURS" \
  python3 - <<'PYEOF'
import csv, io, json, os, sys, datetime

PRIORITY_NAMES = {
    "0": "emerg", "1": "alert", "2": "crit", "3": "err",
    "4": "warning", "5": "notice", "6": "info", "7": "debug",
}

raw = os.environ.get("RAW_JSON", "")
hours_val = os.environ.get("HOURS_VAL", "")

records = []
for line in raw.splitlines():
    line = line.strip()
    if not line:
        continue
    try:
        rec = json.loads(line)
    except json.JSONDecodeError:
        continue

    # __REALTIME_TIMESTAMP はマイクロ秒の epoch
    ts_us = rec.get("__REALTIME_TIMESTAMP", "0")
    try:
        ts_iso = datetime.datetime.utcfromtimestamp(int(ts_us) / 1_000_000).strftime("%Y-%m-%dT%H:%M:%SZ")
    except (ValueError, TypeError):
        ts_iso = ""

    priority = str(rec.get("PRIORITY", ""))
    level = PRIORITY_NAMES.get(priority, priority)
    unit = rec.get("_SYSTEMD_UNIT", "") or rec.get("SYSLOG_IDENTIFIER", "")
    message = rec.get("MESSAGE", "")
    if isinstance(message, list):
        # journald がバイナリメッセージを配列で返す場合がある
        message = "".join(chr(c) for c in message if isinstance(c, int))
    if len(message) > 500:
        message = message[:497] + "..."

    records.append({
        "TimeUTC": ts_iso,
        "Level": level,
        "Unit": unit,
        "Host": rec.get("_HOSTNAME", ""),
        "Message": message,
    })

# CSV 出力 (UTF-8, BOM なし。Excel で日本語を正しく開きたい場合は呼び出し側で iconv)
out = io.StringIO()
writer = csv.DictWriter(out, fieldnames=["TimeUTC", "Level", "Unit", "Host", "Message"])
writer.writeheader()
for r in records:
    writer.writerow(r)
print(out.getvalue(), end="")

# 件数を stderr に出すと運用者が把握しやすい
print(f"# Extracted {len(records)} record(s) from the last {hours_val} hour(s)", file=sys.stderr)
PYEOF
)"

# ---------------------------- 出力 ----------------------------
if [[ -n "$OUTPUT_PATH" ]]; then
  printf '%s' "$CSV_OUT" > "$OUTPUT_PATH"
  echo "Saved support events to $OUTPUT_PATH"
else
  printf '%s' "$CSV_OUT"
fi
