"""healthcheck-cli: HTTP / TCP / DNS 到達性を JSON で返す軽量 HTTP サーバー。

Lab 用のサンプル。標準ライブラリのみで構成し、コンテナ化の練習台にする。
Prometheus 形式の /metrics も exposition format で出力する (text/plain 0.0.4)。

エンドポイント:
    GET /healthz                 - liveness (常に 200)
    GET /readyz                  - readiness (常に 200。実際には依存先 ping)
    GET /probe?host=<h>&port=<p> - TCP 接続到達性チェック
    GET /metrics                 - Prometheus exposition format
"""

from __future__ import annotations

import argparse
import json
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse


class Metrics:
    """スレッドセーフな最小カウンタ実装。

    依存を入れたくないので prometheus_client を使わず手書きする。
    本番では prometheus_client を入れる前提だが、ここでは「Prometheus exposition format
    がどう書かれているか」 を読み手に示すのが目的。
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._started_at = time.time()
        self.requests_total: dict[tuple[str, int], int] = {}
        self.probe_total: dict[bool, int] = {True: 0, False: 0}

    def record_request(self, path: str, status: int) -> None:
        with self._lock:
            key = (path, status)
            self.requests_total[key] = self.requests_total.get(key, 0) + 1

    def record_probe(self, reachable: bool) -> None:
        with self._lock:
            self.probe_total[reachable] = self.probe_total.get(reachable, 0) + 1

    def render(self) -> str:
        lines: list[str] = []
        lines.append("# HELP healthcheck_uptime_seconds プロセス起動からの経過秒")
        lines.append("# TYPE healthcheck_uptime_seconds counter")
        lines.append(f"healthcheck_uptime_seconds {time.time() - self._started_at:.3f}")
        lines.append("# HELP healthcheck_http_requests_total path/status ごとの HTTP リクエスト数")
        lines.append("# TYPE healthcheck_http_requests_total counter")
        with self._lock:
            for (path, status), count in sorted(self.requests_total.items()):
                lines.append(
                    f'healthcheck_http_requests_total{{path="{path}",status="{status}"}} {count}'
                )
            lines.append("# HELP healthcheck_probe_total TCP probe の到達/失敗カウンタ")
            lines.append("# TYPE healthcheck_probe_total counter")
            for reachable, count in self.probe_total.items():
                label = "true" if reachable else "false"
                lines.append(f'healthcheck_probe_total{{reachable="{label}"}} {count}')
        return "\n".join(lines) + "\n"


def tcp_probe(host: str, port: int, timeout: float = 2.0) -> dict:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        sock.connect((host, port))
        return {"host": host, "port": port, "reachable": True}
    except (OSError, socket.timeout) as exc:
        return {"host": host, "port": port, "reachable": False, "error": str(exc)}
    finally:
        sock.close()


def make_handler(metrics: Metrics) -> type[BaseHTTPRequestHandler]:
    class Handler(BaseHTTPRequestHandler):
        def _respond(self, status: int, payload: dict | str, content_type: str = "application/json") -> None:
            if isinstance(payload, dict):
                body = json.dumps(payload).encode("utf-8")
            else:
                body = payload.encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self) -> None:
            parsed = urlparse(self.path)
            path = parsed.path
            status = 200

            if path == "/healthz":
                self._respond(200, {"status": "ok"})
            elif path == "/readyz":
                self._respond(200, {"status": "ready"})
            elif path == "/metrics":
                self._respond(200, metrics.render(), content_type="text/plain; version=0.0.4")
            elif path == "/probe":
                params = parse_qs(parsed.query)
                host = (params.get("host") or [""])[0]
                try:
                    port = int((params.get("port") or ["0"])[0])
                except ValueError:
                    status = 400
                    self._respond(status, {"error": "port must be integer"})
                    metrics.record_request(path, status)
                    return
                if not host or not (1 <= port <= 65535):
                    status = 400
                    self._respond(status, {"error": "host and port required"})
                    metrics.record_request(path, status)
                    return
                result = tcp_probe(host, port)
                metrics.record_probe(result["reachable"])
                self._respond(200, result)
            else:
                status = 404
                self._respond(status, {"error": "not found"})

            metrics.record_request(path, status)

        def log_message(self, format: str, *args) -> None:
            print(json.dumps({
                "level": "info",
                "remote": self.address_string(),
                "msg": format % args,
            }), flush=True)

    return Handler


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()

    metrics = Metrics()
    server = ThreadingHTTPServer((args.host, args.port), make_handler(metrics))
    print(json.dumps({"level": "info", "msg": f"listening on {args.host}:{args.port}"}), flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.shutdown()


if __name__ == "__main__":
    main()
