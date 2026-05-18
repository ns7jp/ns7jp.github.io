"""healthcheck-cli の単体テスト。

外部依存を入れず、標準ライブラリの http.client でサーバーを叩く。
"""
from __future__ import annotations

import http.client
import json
import socket
import threading
import time
from contextlib import contextmanager

import pytest

from src.main import Metrics, make_handler, tcp_probe
from http.server import ThreadingHTTPServer


def _free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


@contextmanager
def run_server():
    """テスト用にバックグラウンドで HTTP サーバーを起動する。"""
    port = _free_port()
    metrics = Metrics()
    server = ThreadingHTTPServer(("127.0.0.1", port), make_handler(metrics))
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        # サーバーが listen し終えるのを軽く待つ
        for _ in range(20):
            try:
                with socket.create_connection(("127.0.0.1", port), timeout=0.5):
                    break
            except OSError:
                time.sleep(0.05)
        yield port, metrics
    finally:
        server.shutdown()
        server.server_close()


def _get(port: int, path: str) -> tuple[int, dict[str, str], str]:
    conn = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
    try:
        conn.request("GET", path)
        resp = conn.getresponse()
        body = resp.read().decode("utf-8")
        return resp.status, dict(resp.getheaders()), body
    finally:
        conn.close()


# ---------- Metrics ----------

def test_metrics_initial_state_is_empty():
    m = Metrics()
    rendered = m.render()
    assert "healthcheck_uptime_seconds" in rendered
    assert "healthcheck_http_requests_total" in rendered
    assert "healthcheck_probe_total" in rendered


def test_metrics_increments_request_counter():
    m = Metrics()
    m.record_request("/healthz", 200)
    m.record_request("/healthz", 200)
    m.record_request("/nope", 404)
    rendered = m.render()
    assert 'healthcheck_http_requests_total{path="/healthz",status="200"} 2' in rendered
    assert 'healthcheck_http_requests_total{path="/nope",status="404"} 1' in rendered


def test_metrics_probe_counter_tracks_reachable():
    m = Metrics()
    m.record_probe(True)
    m.record_probe(False)
    m.record_probe(True)
    rendered = m.render()
    assert 'healthcheck_probe_total{reachable="true"} 2' in rendered
    assert 'healthcheck_probe_total{reachable="false"} 1' in rendered


# ---------- TCP probe ----------

def test_tcp_probe_reachable_when_target_open():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        _, port = listener.getsockname()
        result = tcp_probe("127.0.0.1", port, timeout=1.0)
    assert result == {"host": "127.0.0.1", "port": port, "reachable": True}


def test_tcp_probe_unreachable_returns_error():
    # 1 番ポートは通常閉じている。OS によっては EACCES。どちらも reachable=False。
    result = tcp_probe("127.0.0.1", 1, timeout=0.3)
    assert result["reachable"] is False
    assert "error" in result


# ---------- HTTP endpoints ----------

def test_healthz_returns_ok():
    with run_server() as (port, _):
        status, headers, body = _get(port, "/healthz")
    assert status == 200
    assert headers["Content-Type"] == "application/json"
    assert json.loads(body) == {"status": "ok"}


def test_readyz_returns_ready():
    with run_server() as (port, _):
        status, _, body = _get(port, "/readyz")
    assert status == 200
    assert json.loads(body) == {"status": "ready"}


def test_unknown_path_returns_404():
    with run_server() as (port, _):
        status, _, body = _get(port, "/nope")
    assert status == 404
    assert json.loads(body) == {"error": "not found"}


def test_probe_returns_400_when_args_missing():
    with run_server() as (port, _):
        status, _, body = _get(port, "/probe")
    assert status == 400
    assert "error" in json.loads(body)


def test_probe_returns_400_when_port_invalid():
    with run_server() as (port, _):
        status, _, body = _get(port, "/probe?host=127.0.0.1&port=abc")
    assert status == 400


def test_probe_returns_reachable_for_open_port():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        _, target_port = listener.getsockname()
        with run_server() as (port, _):
            status, _, body = _get(port, f"/probe?host=127.0.0.1&port={target_port}")
    assert status == 200
    payload = json.loads(body)
    assert payload["reachable"] is True
    assert payload["port"] == target_port


def test_metrics_endpoint_exposes_prometheus_format():
    with run_server() as (port, _):
        # 何度かエンドポイントを叩いてカウンタを動かす
        for _ in range(3):
            _get(port, "/healthz")
        _get(port, "/nope")
        status, headers, body = _get(port, "/metrics")

    assert status == 200
    assert headers["Content-Type"].startswith("text/plain")
    # /healthz と /nope と /metrics 自身がカウントされる
    assert 'healthcheck_http_requests_total{path="/healthz",status="200"} 3' in body
    assert 'healthcheck_http_requests_total{path="/nope",status="404"} 1' in body
    assert "healthcheck_uptime_seconds" in body


def test_probe_metrics_increments_on_successful_probe():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        _, target_port = listener.getsockname()
        with run_server() as (port, _):
            _get(port, f"/probe?host=127.0.0.1&port={target_port}")
            _, _, body = _get(port, "/metrics")
    assert 'healthcheck_probe_total{reachable="true"} 1' in body


def test_metrics_response_lines_are_well_formed():
    """Prometheus exposition format の最低限のフォーマット検証。"""
    m = Metrics()
    m.record_request("/healthz", 200)
    rendered = m.render()
    for line in rendered.strip().splitlines():
        if line.startswith("#"):
            assert line.startswith(("# HELP ", "# TYPE "))
        else:
            # メトリクス本体は "name{labels} value" 形式
            assert " " in line, f"malformed metric line: {line}"
