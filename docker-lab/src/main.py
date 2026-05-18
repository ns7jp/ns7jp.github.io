"""healthcheck-cli: HTTP / TCP / DNS 到達性を JSON で返す軽量 HTTP サーバー。

Lab 用のサンプル。標準ライブラリのみで構成し、コンテナ化の練習台にする。

エンドポイント:
    GET /healthz                 - liveness (常に 200)
    GET /readyz                  - readiness (常に 200。実際には依存先 ping)
    GET /probe?host=<h>&port=<p> - TCP 接続到達性チェック
"""

from __future__ import annotations

import argparse
import json
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse


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


class Handler(BaseHTTPRequestHandler):
    def _respond(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/healthz":
            self._respond(200, {"status": "ok"})
        elif parsed.path == "/readyz":
            self._respond(200, {"status": "ready"})
        elif parsed.path == "/probe":
            params = parse_qs(parsed.query)
            host = (params.get("host") or [""])[0]
            try:
                port = int((params.get("port") or ["0"])[0])
            except ValueError:
                self._respond(400, {"error": "port must be integer"})
                return
            if not host or not (1 <= port <= 65535):
                self._respond(400, {"error": "host and port required"})
                return
            self._respond(200, tcp_probe(host, port))
        else:
            self._respond(404, {"error": "not found"})

    def log_message(self, format: str, *args) -> None:
        # 1 行 JSON ログ (Loki / Promtail で扱いやすい)
        print(json.dumps({
            "level": "info",
            "remote": self.address_string(),
            "msg": format % args,
        }), flush=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(json.dumps({"level": "info", "msg": f"listening on {args.host}:{args.port}"}), flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.shutdown()


if __name__ == "__main__":
    main()
