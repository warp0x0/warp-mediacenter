from __future__ import annotations

from datetime import datetime, timezone
from types import SimpleNamespace
from typing import Any, Dict

import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import sys
import asyncio

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import httpx

from warp_mediacenter.backend.api.app import create_app
from warp_mediacenter.backend.api.middleware import init_container


PAYLOAD_BYTES = (b"warp-mediacenter-phase6-smoke-" * 64)


class _RangeHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self) -> None:  # noqa: N802
        total = len(PAYLOAD_BYTES)
        range_header = self.headers.get("Range")
        if range_header:
            start = 0
            end = total - 1
            try:
                raw = range_header.replace("bytes=", "")
                start_str, end_str = raw.split("-", 1)
                if start_str:
                    start = int(start_str)
                if end_str:
                    end = int(end_str)
            except Exception:
                self.send_response(416)
                self.end_headers()
                return

            if start < 0 or end >= total or start > end:
                self.send_response(416)
                self.end_headers()
                return

            body = PAYLOAD_BYTES[start : end + 1]
            self.send_response(206)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Content-Range", f"bytes {start}-{end}/{total}")
            self.end_headers()
            self.wfile.write(body)
            return

        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Length", str(total))
        self.end_headers()
        self.wfile.write(PAYLOAD_BYTES)

    def log_message(self, format: str, *args: Any) -> None:  # noqa: A002
        return


def _start_range_server() -> tuple[HTTPServer, str]:
    server = HTTPServer(("127.0.0.1", 0), _RangeHandler)
    host, port = server.server_address
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server, f"http://{host}:{port}/media.bin"


class _FakePreloadManager:
    def __init__(self, upstream_url: str) -> None:
        self._upstream_url = upstream_url
        self._sessions: Dict[str, SimpleNamespace] = {}

    def create_session(
        self,
        stream_url: str,
        *,
        title: str | None = None,
        media_kind: str | None = None,
        start_percent: float = 0.0,
    ) -> SimpleNamespace:
        session_id = f"s{len(self._sessions) + 1}"
        session = SimpleNamespace(
            session_id=session_id,
            created_at=datetime.now(timezone.utc),
            proxy=SimpleNamespace(local_url=self._upstream_url),
            title=title,
            media_kind=media_kind,
        )
        self._sessions[session_id] = session
        return session

    def get_status(self, session_id: str) -> Dict[str, Any]:
        if session_id not in self._sessions:
            raise KeyError(session_id)
        return {
            "session_id": session_id,
            "url": self._upstream_url,
            "active": True,
            "bytes_downloaded": len(PAYLOAD_BYTES),
            "total_size": len(PAYLOAD_BYTES),
            "percent": 100.0,
            "download_complete": True,
            "error": None,
            "state": "ready",
            "title": "Smoke",
            "media_kind": "movie",
            "buffer_ahead_bytes": len(PAYLOAD_BYTES),
            "active_streams": 1,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }

    def stop_session(self, session_id: str) -> bool:
        return self._sessions.pop(session_id, None) is not None

    def acquire_stream(self, session_id: str) -> SimpleNamespace:
        session = self._sessions.get(session_id)
        if session is None:
            raise KeyError(session_id)
        return session

    def release_stream(self, session_id: str) -> None:
        return


class _FakeScrobbleResult:
    def __init__(self, action: str, progress: float) -> None:
        self.action = action
        self.progress = progress

    def model_dump(self, mode: str = "json") -> Dict[str, Any]:
        return {
            "action": self.action,
            "progress": self.progress,
            "media_type": "movie",
            "media": {"id": "fake", "type": "movie", "title": "Fake", "source": "trakt"},
        }


class _FakeTraktManager:
    def scrobble(
        self,
        *,
        media_type: Any,
        media: Dict[str, Any],
        progress: float,
        action: str,
        show: Dict[str, Any] | None = None,
    ) -> _FakeScrobbleResult:
        return _FakeScrobbleResult(action=action, progress=progress)


async def _run_contract_checks(app: Any) -> None:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://testserver") as client:
        created = await client.post(
            "/api/v1/player/preload/session",
            json={"stream_url": "https://example.com/video.mp4", "title": "Smoke", "media_kind": "movie"},
        )
        assert created.status_code == 200, created.text
        created_payload = created.json()
        session_id = created_payload["session_id"]

        status = await client.get(f"/api/v1/player/preload/session/{session_id}/status")
        assert status.status_code == 200, status.text
        status_payload = status.json()
        assert status_payload["state"] in {"preloading", "ready", "stopped", "error"}

        stream = await client.get(
            f"/api/v1/player/preload/session/{session_id}/stream",
            headers={"Range": "bytes=0-9"},
        )
        assert stream.status_code == 206, stream.text
        assert len(stream.content) == 10

        start = await client.post(
            "/api/v1/player/scrobble/start",
            json={
                "session_id": session_id,
                "media_type": "movie",
                "media": {"title": "Smoke", "ids": {"tmdb": 1}},
                "progress": 0,
            },
        )
        assert start.status_code == 200, start.text
        assert start.json().get("ok") is True

        stop = await client.post(
            "/api/v1/player/scrobble/stop",
            json={
                "session_id": session_id,
                "media_type": "movie",
                "media": {"title": "Smoke", "ids": {"tmdb": 1}},
                "progress": 42.5,
            },
        )
        assert stop.status_code == 200, stop.text
        assert stop.json().get("ok") is True

        deleted = await client.delete(f"/api/v1/player/preload/session/{session_id}")
        assert deleted.status_code == 200, deleted.text
        assert deleted.json().get("removed") is True


def main() -> None:
    server, upstream_url = _start_range_server()
    try:
        container = init_container(
            preload_session_manager=_FakePreloadManager(upstream_url),
            trakt_manager=_FakeTraktManager(),
        )
        app = create_app(container=container)

        asyncio.run(_run_contract_checks(app))

        print("Phase 6 contract smoke test: PASS")
    finally:
        server.shutdown()


if __name__ == "__main__":
    main()
