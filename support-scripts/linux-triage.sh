#!/usr/bin/env bash
# linux-triage.sh
# Linux サーバー一次切り分け用の読み取り専用スクリプト。
#
# 想定: 「ログインできない」「サービスが重い」「ディスクが満杯らしい」など、
# 問い合わせを受けた直後に同じ順序で状態を確認し、結果をテキストで残す目的。
#
# 仕様:
#   - 読み取り中心。サービス再起動・設定変更・削除は行わない。
#   - 出力は標準出力 + 任意の保存ファイル（-o）に同時に書き出す。
#   - root でなくても動くが、journalctl・iptables/ufw・dmesg は root 推奨。
#
# 使い方:
#   ./linux-triage.sh                    # 画面に表示のみ
#   ./linux-triage.sh -o triage.log      # ファイルにも保存
#   ./linux-triage.sh -d 60              # 直近60分のログを対象（既定30分）
#
# 終了コード:
#   0  : 全項目 OK もしくは警告のみ
#   1  : ディスク 95% 以上 / load5 > CPU数 など、明確な要対応を検知

set -u

OUTPUT=""
MINUTES=30

while getopts ":o:d:h" opt; do
  case "$opt" in
    o) OUTPUT="$OPTARG" ;;
    d) MINUTES="$OPTARG" ;;
    h)
      sed -n '2,25p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: -$OPTARG" >&2; exit 2 ;;
  esac
done

# tee で標準出力と保存ファイルを同時に扱う
if [[ -n "$OUTPUT" ]]; then
  exec > >(tee -a "$OUTPUT") 2>&1
fi

section() {
  printf '\n==== %s ====\n' "$1"
}

run_safe() {
  # 一部コマンドは存在しない環境もあるため、見つからなければスキップする
  if command -v "$1" >/dev/null 2>&1; then
    "$@"
  else
    echo "(skip) $1 not installed"
  fi
}

EXIT_CODE=0

section "HOST"
echo "hostname : $(hostname)"
echo "datetime : $(date -Is)"
echo "uptime   : $(uptime -p 2>/dev/null || uptime)"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  echo "os       : ${PRETTY_NAME:-unknown}"
fi
echo "kernel   : $(uname -r)"

section "LOAD / CPU"
CPU_CORES=$(nproc 2>/dev/null || echo 1)
echo "cpu cores: ${CPU_CORES}"
LOAD5=$(awk '{print $2}' /proc/loadavg)
echo "loadavg  : $(cat /proc/loadavg)"
# load5 が CPU 数を超えていたら警告
awk -v l="$LOAD5" -v c="$CPU_CORES" 'BEGIN { if (l+0 > c+0) exit 1; else exit 0 }' || {
  echo "WARN: load5 ($LOAD5) exceeds CPU count ($CPU_CORES)"
  EXIT_CODE=1
}

section "MEMORY"
free -h 2>/dev/null || echo "(skip) free not installed"

section "DISK USAGE"
# tmpfs / devtmpfs はノイズになるので除外
df -hPT -x tmpfs -x devtmpfs 2>/dev/null | awk 'NR==1 || $7 !~ /^\/(snap|run)/'
# 使用率 95% 以上のマウントポイントを抽出
HIGH=$(df -PT -x tmpfs -x devtmpfs 2>/dev/null | awk 'NR>1 && $6+0 >= 95 { print $7, $6 }')
if [[ -n "$HIGH" ]]; then
  echo "WARN: high disk usage detected:"
  echo "$HIGH"
  EXIT_CODE=1
fi

section "INODE USAGE"
df -hPi -x tmpfs -x devtmpfs 2>/dev/null | awk 'NR==1 || $6+0 >= 80'

section "TOP PROCESSES (cpu)"
ps -eo pid,user,pcpu,pmem,etime,comm --sort=-pcpu 2>/dev/null | head -n 11

section "TOP PROCESSES (mem)"
ps -eo pid,user,pcpu,pmem,etime,comm --sort=-pmem 2>/dev/null | head -n 11

section "LISTENING PORTS"
if command -v ss >/dev/null 2>&1; then
  ss -tulnp 2>/dev/null | head -n 30
else
  run_safe netstat -tulnp | head -n 30
fi

section "NETWORK"
echo "-- default route --"
ip route show default 2>/dev/null || run_safe route -n
echo "-- dns --"
if [[ -r /etc/resolv.conf ]]; then
  grep -E '^(nameserver|search)' /etc/resolv.conf
fi
echo "-- ping 1.1.1.1 --"
ping -c 2 -W 2 1.1.1.1 >/dev/null 2>&1 && echo "reachable" || echo "WARN: 1.1.1.1 unreachable"
echo "-- dns lookup --"
if command -v dig >/dev/null 2>&1; then
  dig +short +time=2 +tries=1 example.com || true
elif command -v nslookup >/dev/null 2>&1; then
  nslookup example.com 2>&1 | tail -n 5
fi

section "FAILED SERVICES (systemd)"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --failed --no-legend 2>/dev/null || true
else
  echo "(skip) systemctl not present"
fi

section "RECENT KERNEL/SYSTEM ERRORS"
if command -v journalctl >/dev/null 2>&1; then
  journalctl --since "${MINUTES} minutes ago" -p err -n 30 --no-pager 2>/dev/null \
    || echo "(journalctl requires elevated privilege to read all logs)"
else
  run_safe dmesg --level=err -T | tail -n 20
fi

section "RECENT LOGINS"
last -n 5 2>/dev/null | head -n 6 || echo "(skip) last not installed"

section "FIREWALL"
if command -v ufw >/dev/null 2>&1; then
  ufw status 2>/dev/null || echo "(needs sudo)"
elif command -v firewall-cmd >/dev/null 2>&1; then
  firewall-cmd --state 2>/dev/null || echo "(needs sudo)"
else
  echo "(skip) ufw/firewalld not installed"
fi

section "SUMMARY"
if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "result: OK / Warning only"
else
  echo "result: ATTENTION REQUIRED (see WARN entries above)"
fi
if [[ -n "$OUTPUT" ]]; then
  echo "saved to: $OUTPUT"
fi

exit "$EXIT_CODE"
