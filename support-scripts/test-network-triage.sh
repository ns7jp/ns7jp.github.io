#!/usr/bin/env bash
#
# test-network-triage.sh
# ============================================================================
# Linux ホストでネットワーク疎通の一次切り分けを行う読み取り専用スクリプトです。
# PowerShell 版 Test-NetworkTriage.ps1 の Linux 対応版にあたります。
#
# 確認項目:
#   1. アクティブインターフェースとデフォルトゲートウェイ
#   2. ゲートウェイへの ICMP 応答 (端末側〜LAN 出口の確認)
#   3. 指定宛先への ICMP 応答 (外部 / SaaS への到達性)
#   4. DNS 名前解決 (ゲートウェイ到達できるのに名前解決だけ NG = DNS 設定疑い)
#
# 想定:
#   - iputils の ping が利用可能 (GNU/Linux 標準)
#   - 設定変更は一切行いません
#
# 用途:
#   - 「ネットにつながらない」問い合わせ受付直後の標準確認
#   - チケット添付用の構造化結果 (JSON)
# ============================================================================

set -euo pipefail

TARGETS=("8.8.8.8" "github.com" "microsoft.com")
DNS_NAME="microsoft.com"
PING_COUNT=2
OUTPUT_PATH=""

usage() {
  cat <<USAGE
使用方法: $0 [-t target1,target2,...] [-d DNS_NAME] [-c PING_COUNT] [-o OUTPUT_PATH]

オプション:
  -t  疎通確認の宛先 (カンマ区切り。既定: 8.8.8.8,github.com,microsoft.com)
  -d  DNS 名前解決の対象 (既定: microsoft.com)
  -c  ping 試行回数 (既定: 2)
  -o  結果 JSON の保存先 (省略時は標準出力)
USAGE
}

while getopts "t:d:c:o:h" opt; do
  case "$opt" in
    t) IFS=',' read -ra TARGETS <<< "$OPTARG" ;;
    d) DNS_NAME="$OPTARG" ;;
    c) PING_COUNT="$OPTARG" ;;
    o) OUTPUT_PATH="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

# ---------------------------- 前提チェック ----------------------------
if ! command -v ip >/dev/null 2>&1; then
  echo "ERROR: 'ip' コマンドが見つかりません。iproute2 をインストールしてください。" >&2
  exit 2
fi
if ! command -v ping >/dev/null 2>&1; then
  echo "ERROR: 'ping' コマンドが見つかりません。iputils-ping をインストールしてください。" >&2
  exit 2
fi

# ---------------------------- 経路情報の取得 ----------------------------
default_route="$(ip route show default 2>/dev/null | head -1 || true)"
default_gateway="$(awk '{for(i=1;i<=NF;i++) if($i=="via"){print $(i+1); exit}}' <<< "$default_route")"
active_interface="$(awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}' <<< "$default_route")"

ipv4_address=""
if [[ -n "$active_interface" ]]; then
  ipv4_address="$(ip -4 -o addr show dev "$active_interface" 2>/dev/null \
    | awk '{print $4; exit}' || true)"
fi

# ---------------------------- ping ヘルパ ----------------------------
# 成功時は平均応答時間 (ms) を浮動小数で出力。失敗時は空文字。
ping_avg_ms() {
  local target="$1"
  local out
  if out="$(ping -c "$PING_COUNT" -W 2 "$target" 2>/dev/null)"; then
    # 末尾の "rtt min/avg/max/mdev = .../X.X/.../.." または "round-trip" 行から avg を抽出
    awk -F'[/= ]+' '/rtt|round-trip/{
      for (i=1; i<=NF; i++) if ($i ~ /^[0-9.]+$/) { vals[++n] = $i }
      if (n >= 2) { printf "%.1f", vals[2] }
    }' <<< "$out"
  fi
}

# ---------------------------- ターゲット結果 ----------------------------
TARGET_RESULTS=""
for target in "${TARGETS[@]}"; do
  avg="$(ping_avg_ms "$target")"
  reachable=false
  [[ -n "$avg" ]] && reachable=true
  TARGET_RESULTS+="${target}|${reachable}|${avg:-null}"$'\n'
done

# ---------------------------- ゲートウェイ確認 ----------------------------
GATEWAY_AVG=""
if [[ -n "$default_gateway" ]]; then
  GATEWAY_AVG="$(ping_avg_ms "$default_gateway")"
fi

# ---------------------------- DNS 名前解決 ----------------------------
DNS_STATUS="OK"
DNS_RESULT=""
if dns_out="$(getent hosts "$DNS_NAME" 2>&1)"; then
  DNS_RESULT="$(echo "$dns_out" | head -3 | awk '{print $1}' | tr '\n' ',' | sed 's/,$//')"
else
  DNS_STATUS="Failed: $(echo "$dns_out" | head -1)"
fi

# ---------------------------- JSON 整形 ----------------------------
JSON_OUT="$(
  CHECKED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  HOSTNAME_VAL="$(hostname)" \
  ACTIVE_IFACE="$active_interface" \
  IPV4_ADDR="$ipv4_address" \
  DEFAULT_GW="$default_gateway" \
  GATEWAY_AVG="$GATEWAY_AVG" \
  TARGET_RESULTS="$TARGET_RESULTS" \
  DNS_NAME="$DNS_NAME" \
  DNS_STATUS="$DNS_STATUS" \
  DNS_RESULT="$DNS_RESULT" \
  python3 - <<'PYEOF'
import json, os

def parse_targets(text):
    out = []
    for line in (text or "").strip().splitlines():
        parts = line.split("|")
        if len(parts) >= 3:
            avg = parts[2]
            out.append({
                "Target": parts[0],
                "Reachable": parts[1] == "true",
                "AverageMs": float(avg) if avg not in ("", "null") else None,
            })
    return out

gw_avg = os.environ.get("GATEWAY_AVG", "")
gw_target = os.environ.get("DEFAULT_GW", "") or "No default gateway detected"
gateway_check = {
    "Target": gw_target,
    "Reachable": bool(gw_avg),
    "AverageMs": float(gw_avg) if gw_avg else None,
}

result = {
    "CheckedAt":       os.environ.get("CHECKED_AT", ""),
    "Hostname":        os.environ.get("HOSTNAME_VAL", ""),
    "ActiveInterface": os.environ.get("ACTIVE_IFACE", "") or None,
    "IPv4Address":     os.environ.get("IPV4_ADDR", "") or None,
    "DefaultGateway":  os.environ.get("DEFAULT_GW", "") or None,
    "GatewayCheck":    gateway_check,
    "TargetChecks":    parse_targets(os.environ.get("TARGET_RESULTS", "")),
    "DnsName":         os.environ.get("DNS_NAME", ""),
    "DnsStatus":       os.environ.get("DNS_STATUS", ""),
    "DnsResult":       os.environ.get("DNS_RESULT", ""),
}

print(json.dumps(result, ensure_ascii=False, indent=2))
PYEOF
)"

# ---------------------------- 出力 ----------------------------
if [[ -n "$OUTPUT_PATH" ]]; then
  printf '%s\n' "$JSON_OUT" > "$OUTPUT_PATH"
  echo "Saved network triage result to $OUTPUT_PATH"
else
  printf '%s\n' "$JSON_OUT"
fi
