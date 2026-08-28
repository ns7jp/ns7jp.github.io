#!/usr/bin/env bash
set -uo pipefail

usage() { echo "Usage: $0 <safe-label> [-- command [args...]]" >&2; exit 2; }
[[ $# -ge 1 ]] || usage
label=$1; shift
[[ "$label" =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]] || { echo "label must match [a-z0-9-] (max 40)" >&2; exit 2; }
[[ ${1:-} != "--" || $# -ge 2 ]] || usage

timestamp=$(date -u +%Y%m%dT%H%M%SZ)
out="infra-evidence/measured/${timestamp}-${label}"
mkdir -p "$out"

{
  echo "status=MEASURED_REVIEW_REQUIRED"
  echo "started_utc=$(date -u +%FT%TZ)"
  echo "git_commit=$(git rev-parse HEAD 2>/dev/null || echo NOT_GIT)"
  echo "git_dirty=$(if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then echo false; else echo true; fi)"
  echo "kernel=$(uname -srmo)"
  [[ -r /etc/os-release ]] && sed -n 's/^\(ID\|VERSION_ID\|PRETTY_NAME\)=/os_\1=/p' /etc/os-release
  command -v systemd-detect-virt >/dev/null && echo "virtualization=$(systemd-detect-virt 2>/dev/null || echo unknown)"
  command -v nproc >/dev/null && echo "cpu_count=$(nproc)"
  command -v free >/dev/null && free -h
  df -h .
} > "$out/metadata.txt"

exit_code=0
if [[ ${1:-} == "--" ]]; then
  shift
  printf '%q ' "$@" > "$out/command.txt"; printf '\n' >> "$out/command.txt"
  "$@" >"$out/stdout.txt" 2>"$out/stderr.txt" || exit_code=$?
else
  echo "preflight only" > "$out/command.txt"
  : > "$out/stdout.txt"; : > "$out/stderr.txt"
fi
echo "$exit_code" > "$out/exit-code.txt"
echo "finished_utc=$(date -u +%FT%TZ)" >> "$out/metadata.txt"
(cd "$out" && sha256sum metadata.txt command.txt stdout.txt stderr.txt exit-code.txt > SHA256SUMS)
echo "Evidence saved to $out"
echo "Review every file for secrets and personal data before committing."
exit "$exit_code"

