#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-monitoring-stack/docker-compose.yml}"
OUTPUT_DIR="${OUTPUT_DIR:-verified-lab/output}"
SUMMARY="$OUTPUT_DIR/verification-summary.txt"

mkdir -p "$OUTPUT_DIR"
: > "$SUMMARY"

log() {
  printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" | tee -a "$SUMMARY"
}

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

cleanup() {
  compose start probe-target >/dev/null 2>&1 || true
  compose logs --no-color > "$OUTPUT_DIR/compose.log" 2>&1 || true
  compose down -v --remove-orphans >/dev/null 2>&1 || true
}
trap cleanup EXIT

poll() {
  local description="$1"
  shift
  for _ in $(seq 1 75); do
    if "$@" >/dev/null 2>&1; then
      log "$description: OK"
      return 0
    fi
    sleep 2
  done
  log "$description: FAILED"
  compose ps >> "$SUMMARY" 2>&1 || true
  return 1
}

prom_value() {
  local query="$1"
  curl -fsSG --data-urlencode "query=$query" \
    http://localhost:9090/api/v1/query |
    jq -r '.data.result[0].value[1] // "missing"'
}

target_is_healthy() {
  test "$(prom_value 'probe_success{job="blackbox-http",service="lab-http-target"}')" = "1"
}

alert_is_firing() {
  test "$(prom_value 'ALERTS{alertname="LabProbeTargetDown",alertstate="firing"}')" = "1"
}

webhook_has_status() {
  compose logs --no-color webhook-receiver |
    grep -Fq "\"status\": \"$1\""
}

log "Starting monitoring stack for verified incident drill"
compose up -d

poll "Prometheus readiness" curl -fsS http://localhost:9090/-/ready
poll "Alertmanager readiness" curl -fsS http://localhost:9093/-/ready
poll "Webhook receiver readiness" curl -fsS http://localhost:18080/health
poll "Baseline external probe success" target_is_healthy

log "Injecting failure: stopping probe-target"
compose stop probe-target
poll "Prometheus alert firing" alert_is_firing
poll "Alertmanager webhook firing delivery" webhook_has_status firing

log "Recovering service: starting probe-target"
compose start probe-target
poll "External probe recovered" target_is_healthy
poll "Alertmanager resolved delivery" webhook_has_status resolved

curl -fsSG --data-urlencode 'query=probe_success{job="blackbox-http",service="lab-http-target"}' \
  http://localhost:9090/api/v1/query > "$OUTPUT_DIR/final-probe-query.json"
compose ps > "$OUTPUT_DIR/final-compose-status.txt"

log "Verified drill completed: health -> failure detection -> notification -> recovery -> resolved notification"
