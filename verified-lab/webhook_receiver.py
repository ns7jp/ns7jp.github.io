"""Small Alertmanager webhook sink used only by the verified monitoring lab."""

from http.server import BaseHTTPRequestHandler, HTTPServer
import json


class WebhookHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/health":
            self.send_error(404)
            return
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok\n")

    def do_POST(self):
        if self.path != "/alerts":
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", "0"))
        body = json.loads(self.rfile.read(length) or b"{}")
        event = {
            "status": body.get("status"),
            "alerts": [
                alert.get("labels", {}).get("alertname", "unknown")
                for alert in body.get("alerts", [])
            ],
        }
        print(json.dumps(event, sort_keys=True), flush=True)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"accepted\n")

    def log_message(self, _format, *_args):
        return


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), WebhookHandler).serve_forever()
