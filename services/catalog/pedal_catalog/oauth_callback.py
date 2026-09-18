from __future__ import annotations

import html
import threading
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from .tone3000 import Tone3000Error
from .tone3000_service import Tone3000Service


def complete_callback(
    request_target: str,
    expected_path: str,
    service: Tone3000Service,
    lock: threading.Lock,
) -> tuple[int, str, str]:
    parsed = urllib.parse.urlsplit(request_target)
    if parsed.path != expected_path:
        return 404, "Not found", "This callback address is not available."
    values = urllib.parse.parse_qs(parsed.query)
    code = values.get("code", [""])[0]
    state = values.get("state", [""])[0]
    tone_id = values.get("tone_id", [""])[0] or None
    canceled = values.get("canceled", [""])[0].lower() == "true"
    oauth_error = values.get("error", [""])[0]
    if not state:
        return 400, "Connection failed", "Missing authorization response."
    try:
        with lock:
            if not code:
                service.cancel_auth(state)
            else:
                service.complete_auth(code, state, tone_id)
    except Tone3000Error as error:
        return 400, "Connection failed", str(error)
    if oauth_error:
        return 400, "Connection failed", oauth_error
    if canceled or tone_id is None:
        return (
            200,
            "No tone selected",
            "You can close this page and browse again from the pedal.",
        )
    return (
        200,
        "Tone selected",
        "You can close this page and return to the pedal.",
    )


class OAuthCallbackServer:
    """Tiny LAN callback endpoint for the phone/browser OAuth handoff."""

    def __init__(
        self,
        redirect_uri: str,
        service: Tone3000Service,
        lock: threading.Lock,
        *,
        bind_host: str = "0.0.0.0",
    ) -> None:
        parsed = urllib.parse.urlsplit(redirect_uri)
        if parsed.scheme != "http" or not parsed.hostname or parsed.port is None:
            raise ValueError(
                "TONE3000 redirect URI must be an http URL with an explicit port"
            )
        self.path = parsed.path or "/callback"
        self.service = service
        self.lock = lock
        self._server = ThreadingHTTPServer((bind_host, parsed.port), self._handler())
        self._thread: threading.Thread | None = None

    @property
    def address(self) -> tuple[str, int]:
        host, port = self._server.server_address[:2]
        return str(host), int(port)

    def _handler(self):
        owner = self

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self) -> None:  # noqa: N802 - stdlib callback name
                if urllib.parse.urlsplit(self.path).path == "/connect":
                    with owner.lock:
                        destination = owner.service.pending_authorize_url
                    if destination is None:
                        self._page(
                            409,
                            "No login waiting",
                            "Start TONE3000 connection on the pedal first.",
                        )
                        return
                    self.send_response(302)
                    self.send_header("Location", destination)
                    self.send_header("Cache-Control", "no-store")
                    self.end_headers()
                    return
                status, title, detail = complete_callback(
                    self.path, owner.path, owner.service, owner.lock
                )
                if status == 404:
                    self.send_error(404)
                    return
                self._page(status, title, detail)

            def _page(self, status: int, title: str, detail: str) -> None:
                body = (
                    "<!doctype html><meta name=viewport "
                    "content='width=device-width,initial-scale=1'>"
                    "<style>body{font:18px system-ui;background:#171717;color:#fff;"
                    "max-width:34rem;margin:15vh auto;padding:2rem}h1{color:#ed6a2c}</style>"
                    f"<h1>{html.escape(title)}</h1><p>{html.escape(detail)}</p>"
                ).encode()
                self.send_response(status)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(body)

            def log_message(self, format: str, *args: object) -> None:
                return

        return Handler

    def start(self) -> None:
        self._thread = threading.Thread(
            target=self._server.serve_forever,
            name="tone3000-oauth-callback",
            daemon=True,
        )
        self._thread.start()

    def close(self) -> None:
        self._server.shutdown()
        self._server.server_close()
        if self._thread is not None:
            self._thread.join(timeout=2)
