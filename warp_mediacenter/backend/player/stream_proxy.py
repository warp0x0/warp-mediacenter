"""Local pre-buffering HTTP proxy for remote media streams.

Downloads the remote URL into a temp file as fast as the CDN allows,
then serves it to VLC via a loopback HTTP server that fully supports
byte-range requests.

Key design decisions
--------------------
* ``start()`` blocks until the CDN returns response headers so that
  ``Content-Length`` is known before VLC makes its first connection —
  VLC requires ``Content-Length`` to seek and to correctly identify the
  container format.
* The proxy URL includes the original filename from the CDN URL
  (e.g. ``http://127.0.0.1:9200/The.Dark.Knight.2008.mkv``).  VLC uses
  the extension as a demuxer hint; without it VLC may refuse to play.
* The handler speaks HTTP/1.1 with proper ``Connection`` and
  ``Content-Range`` headers so VLC can seek at will.
* Forward-seek bypass: when VLC seeks more than 64 MB past the current
  download head (e.g. reading the moov atom from the tail of an MP4
  before playback), the proxy fetches that specific range directly from
  the CDN rather than waiting for the linear download to reach it.
"""

from __future__ import annotations

import http.server
import os
import re
import socket
import socketserver
import tempfile
import threading
import time
from pathlib import Path
from typing import Optional
from urllib.parse import quote, unquote, urlparse

import requests

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)

_PROXY_HOST = "127.0.0.1"
_PROXY_PORT_BASE = 9200
_DOWNLOAD_CHUNK = 2 * 1024 * 1024   # 2 MB per read from CDN
_STREAM_DIR = "/tmp/warp-mediacenter/streams"

# When a range request starts this many bytes beyond the current download
# head, bypass the temp file and fetch from the CDN directly.
_FORWARD_SEEK_BYPASS = 64 * 1024 * 1024  # 64 MB

# WKWebView / AVFoundation only supports a specific set of MIME types.
# If we advertise an unsupported type (e.g. video/x-matroska for MKV files),
# WKWebView immediately rejects the source with MEDIA_ERR_SRC_NOT_SUPPORTED
# (error code 4) without reading a single byte.
# For those types we fall back to application/octet-stream, which triggers
# WKWebView's content-sniffing path and is more permissive.
_WKWEBVIEW_SUPPORTED_VIDEO_TYPES = frozenset({
    "video/mp4",
    "video/quicktime",
    "video/webm",
    "video/ogg",
    "video/3gpp",
    "video/3gpp2",
    "video/mpeg",
})

# Extension → MIME for formats natively supported by WKWebView.
# .mkv is intentionally absent — serve it as octet-stream so WKWebView
# content-sniffs rather than outright refusing video/x-matroska.
_EXT_TO_WKWEBVIEW_MIME: dict[str, str] = {
    ".mp4": "video/mp4",
    ".m4v": "video/mp4",
    ".mov": "video/quicktime",
    ".qt":  "video/quicktime",
    ".webm": "video/webm",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _find_proxy_port(base: int) -> int:
    for port in range(base, base + 30):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind((_PROXY_HOST, port))
                return port
            except OSError:
                continue
    return base


class _ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True

    def handle_error(self, request, client_address) -> None:  # type: ignore[override]
        """Suppress ConnectionResetError noise.

        VLC commonly resets the TCP connection after receiving a range response
        (normal HTTP/1.1 behaviour).  Without this override, Python's default
        handler prints a full traceback for every such reset, polluting the
        server logs with non-actionable noise.
        """
        import sys
        if sys.exc_info()[0] is ConnectionResetError:
            return
        super().handle_error(request, client_address)


# ---------------------------------------------------------------------------
# Proxy
# ---------------------------------------------------------------------------

class StreamProxy:
    """Pre-buffering proxy for a single remote media URL.

    Lifecycle::

        proxy = StreamProxy()          # start HTTP server once
        url = proxy.start(cdn_url)     # begin download, return local URL
        # pass url to VLC …
        proxy.stop()                   # abort download + delete temp file
        proxy.close()                  # permanent shutdown (call on adapter close)
    """

    def __init__(self) -> None:
        self._port: int = _find_proxy_port(_PROXY_PORT_BASE)

        # Per-stream mutable state (reset by start())
        self._cdn_url: str = ""
        self._filename: str = "stream"
        self._content_type: str = "application/octet-stream"  # updated once CDN headers arrive
        self._tmpfile: Optional[str] = None
        self._total_size: int = 0       # 0 = unknown until download thread sets it
        # Byte offset in the file where the current download session started.
        # 0 for full-file downloads; > 0 for resume-from-offset downloads.
        self._download_start: int = 0
        # _written tracks the absolute file position up to which we have data.
        # For full-file downloads it equals bytes written; for offset downloads
        # it starts at _download_start and grows from there.
        self._written: int = 0          # highest byte offset available in temp file
        self._max_served: int = 0       # highest byte offset served to VLC so far
        self._download_done: bool = False
        self._download_error: Optional[str] = None
        self._download_thread: Optional[threading.Thread] = None
        self._stop_flag: bool = False

        self._lock = threading.Lock()
        # Pulsed whenever more data has been written — wakes blocked serve threads
        self._data_event = threading.Event()
        # Set once the download thread has received CDN response headers
        self._headers_ready = threading.Event()
        # Optional callback for non-sequential piece availability (libtorrent path).
        # Called with a byte offset; returns True if that byte is in a downloaded piece.
        self._is_byte_available: Optional[callable] = None

        self._server: Optional[_ThreadedHTTPServer] = None
        self._server_thread: Optional[threading.Thread] = None
        self._start_server()

    # ------------------------------------------------------------------
    # Public interface
    # ------------------------------------------------------------------

    @property
    def local_url(self) -> str:
        """Loopback URL with the original filename for VLC's demuxer hint."""
        return f"http://{_PROXY_HOST}:{self._port}/{quote(self._filename, safe='')}"

    @property
    def bytes_downloaded(self) -> int:
        with self._lock:
            return max(0, self._written - self._download_start)

    @property
    def buffer_ahead(self) -> int:
        """Bytes downloaded beyond the furthest position VLC has read so far.

        When this value is large VLC can decode freely; when it approaches
        zero VLC will stall waiting for more data from the proxy.
        """
        with self._lock:
            return max(0, self._written - self._max_served)

    @property
    def download_complete(self) -> bool:
        with self._lock:
            return self._download_done

    def is_active_for(self, url: str) -> bool:
        """Return True if this proxy is currently downloading *url* and the temp file still exists."""
        with self._lock:
            return (
                self._cdn_url == url
                and self._tmpfile is not None
                and not self._stop_flag
            )

    def snapshot(self) -> dict:
        """Return an atomic snapshot of download progress."""
        with self._lock:
            total = self._total_size
            written = self._written
            dl_start = self._download_start
            error = self._download_error
            bytes_dl = max(0, written - dl_start)
            remaining = total - dl_start if total > 0 else 0
            if remaining > 0:
                pct = round(bytes_dl / remaining * 100, 1)
            elif total > 0:
                pct = 100.0
            else:
                pct = 0.0
            return {
                "url": self._cdn_url,
                "bytes_downloaded": bytes_dl,
                "total_size": total,
                # Bytes from the download offset to EOF — the denominator for
                # percentage calculation and for showing progress in the UI.
                # Equals total_size for full-file downloads; smaller for resume downloads.
                "remaining_size": remaining,
                "percent": pct,
                "active": bool(self._cdn_url) and self._tmpfile is not None and not self._stop_flag,
                "download_complete": self._download_done,
                "error": error,
            }

    def start(self, url: str, start_percent: float = 0.0) -> str:
        """Begin downloading *url* and return the local proxy URL.

        Blocks up to 10 s for the CDN to return response headers so that
        ``Content-Length`` is populated before VLC makes its first request.

        If *start_percent* (0–100) is given and the CDN supports range
        requests, the download begins at that byte offset so that the first
        20 % of **remaining** content is buffered before playback starts.
        Byte-range requests for content before the offset (e.g. the container
        header read by mpv/VLC) are served directly from the CDN.
        """
        self.stop()  # clean up any previous stream

        # Extract filename from URL so VLC gets a format/extension hint
        raw_name = os.path.basename(unquote(urlparse(url).path)) or "stream"
        self._filename = raw_name.split("?")[0] or "stream"

        Path(_STREAM_DIR).mkdir(parents=True, exist_ok=True)
        fd, path = tempfile.mkstemp(suffix=".stream", dir=_STREAM_DIR)
        os.close(fd)

        # Resolve the byte offset via a HEAD request when a resume point is given.
        download_start = 0
        if start_percent > 0:
            try:
                head = requests.head(
                    url, timeout=10, allow_redirects=True,
                    headers={"User-Agent": "VLC/3.0 LibVLC/3.0"},
                )
                cl = int(head.headers.get("Content-Length", 0))
                if cl > 0:
                    download_start = int(start_percent / 100.0 * cl)
                    log.info(
                        "stream_proxy_resume_offset",
                        start_percent=start_percent,
                        total_mb=cl // (1024 * 1024),
                        offset_mb=download_start // (1024 * 1024),
                    )
            except Exception as exc:
                log.warning("stream_proxy_head_failed", error=str(exc)[:120])

        with self._lock:
            self._cdn_url = url
            self._tmpfile = path
            self._content_type = "application/octet-stream"
            self._total_size = 0
            self._download_start = download_start
            # _written starts at download_start so _wait_for(n) correctly waits
            # until byte n has been written to the temp file.
            self._written = download_start
            self._max_served = 0
            self._download_done = False
            self._download_error = None
            self._stop_flag = False
        self._data_event.clear()
        self._headers_ready.clear()

        self._download_thread = threading.Thread(
            target=self._download_loop,
            daemon=True,
            name="stream-dl",
        )
        self._download_thread.start()

        # Wait until the CDN has returned response headers (so Content-Length
        # is known) before we hand the local URL to VLC.
        self._headers_ready.wait(timeout=10)

        local = self.local_url
        log.info(
            "stream_proxy_started",
            url=url[:80],
            local_url=local,
            filename=self._filename,
            content_length_mb=self._total_size // (1024 * 1024) if self._total_size else 0,
            download_start_mb=download_start // (1024 * 1024) if download_start else 0,
        )
        return local

    def stop(self) -> None:
        """Abort current download and delete the temp file."""
        self._is_byte_available = None  # release any reference held by libtorrent callback
        with self._lock:
            self._stop_flag = True
            tmpfile = self._tmpfile
            self._tmpfile = None
        # Wake any blocked serve threads so they notice stop_flag
        self._data_event.set()
        self._headers_ready.set()  # unblock start() if it's still waiting

        if self._download_thread is not None:
            self._download_thread.join(timeout=3)
            self._download_thread = None

        if tmpfile and os.path.exists(tmpfile):
            try:
                os.unlink(tmpfile)
            except OSError:
                pass

        with self._lock:
            self._stop_flag = False
            self._download_start = 0
        log.info("stream_proxy_stopped", deleted_file=tmpfile or "(none)")

    def start_local(
        self,
        file_path: str,
        total_size: int,
        get_written: "Callable[[], int]",
        is_done: "Callable[[], bool]",
        is_byte_available: "Optional[Callable[[int], bool]]" = None,
    ) -> str:
        """Serve a local file that is being written by an external process (e.g. libtorrent).

        Mirrors start() but skips the CDN download — a background thread polls
        get_written() to advance _written so the same _stream_from stalling
        logic works without any changes to the HTTP server code.

        ``is_byte_available(byte_offset) -> bool`` is an optional callback for
        non-sequential downloaders (libtorrent).  When provided it is consulted
        in _wait_for() and _stream_from() so that pieces downloaded out of
        order (tail moov atom, file header) can be served immediately without
        waiting for the sequential watermark to reach their byte positions.
        """
        self.stop()

        filename = os.path.basename(file_path)
        ext = os.path.splitext(filename)[1].lower()

        self._is_byte_available = is_byte_available

        with self._lock:
            self._cdn_url = ""          # no CDN — bypass the backward-seek CDN path
            self._tmpfile = file_path
            self._filename = filename
            self._content_type = _EXT_TO_WKWEBVIEW_MIME.get(ext, "application/octet-stream")
            self._total_size = total_size
            self._download_start = 0
            self._written = get_written()
            self._max_served = 0
            self._download_done = False
            self._download_error = None
            self._stop_flag = False
        self._data_event.clear()
        self._headers_ready.clear()

        self._download_thread = threading.Thread(
            target=self._local_poll_loop,
            args=(get_written, is_done),
            daemon=True,
            name="local-file-poll",
        )
        self._download_thread.start()

        # Total size is already known — unblock any caller waiting on headers.
        self._headers_ready.set()

        local = self.local_url
        log.info(
            "stream_proxy_local_started",
            file=file_path,
            local_url=local,
            total_mb=total_size // (1024 * 1024),
        )
        return local

    def close(self) -> None:
        """Permanently shut down proxy (call once, when adapter is destroyed)."""
        self.stop()
        if self._server is not None:
            self._server.shutdown()
            self._server = None

    # ------------------------------------------------------------------
    # Download loop (background thread)
    # ------------------------------------------------------------------

    def _local_poll_loop(
        self,
        get_written: "Callable[[], int]",
        is_done: "Callable[[], bool]",
    ) -> None:
        """Poll the external writer (libtorrent) and advance _written."""
        while not self._stop_flag:
            written = get_written()
            done = is_done()
            with self._lock:
                self._written = written
                if done:
                    self._download_done = True
            self._data_event.set()
            if done:
                log.info("stream_proxy_local_download_complete", written_mb=written // (1024 * 1024))
                break
            time.sleep(0.25)

    def _download_loop(self) -> None:
        url = self._cdn_url
        tmpfile = self._tmpfile
        download_start = self._download_start
        if not tmpfile:
            self._headers_ready.set()
            return
        try:
            req_headers: dict = {"User-Agent": "VLC/3.0 LibVLC/3.0"}
            if download_start > 0:
                req_headers["Range"] = f"bytes={download_start}-"

            log.info("stream_proxy_cdn_connecting", url=url[:100], offset_mb=download_start // (1024 * 1024) if download_start else 0)
            resp = requests.get(url, stream=True, timeout=30, headers=req_headers)
            resp.raise_for_status()

            total_mb = 0
            # For range responses, get total from Content-Range: bytes X-Y/Z
            cr = resp.headers.get("Content-Range", "")
            if cr:
                m = re.match(r"bytes\s+\d+-\d+/(\d+)", cr)
                if m:
                    with self._lock:
                        self._total_size = int(m.group(1))
                    total_mb = self._total_size // (1024 * 1024)
            else:
                cl = resp.headers.get("Content-Length")
                if cl:
                    with self._lock:
                        self._total_size = int(cl)
                    total_mb = int(cl) // (1024 * 1024)

            # Determine the Content-Type to serve.
            #
            # WKWebView/AVFoundation accepts only a specific MIME whitelist.
            # Advertising an unsupported type (e.g. video/x-matroska for MKV)
            # causes an immediate MEDIA_ERR_SRC_NOT_SUPPORTED (code 4) with
            # no bytes read. For those types we fall back to
            # application/octet-stream, which triggers WKWebView's
            # content-sniffing path and is more permissive.
            cdn_ct = resp.headers.get("Content-Type", "").lower().split(";")[0].strip()
            if cdn_ct in _WKWEBVIEW_SUPPORTED_VIDEO_TYPES:
                # CDN told us something WKWebView can handle natively.
                self._content_type = cdn_ct
            else:
                # CDN returned application/octet-stream or an unsupported
                # video type (e.g. video/x-matroska).  Resolve from the
                # filename extension; if still unsupported (e.g. .mkv, .avi),
                # keep application/octet-stream for content-sniffing.
                ext = os.path.splitext(self._filename)[1].lower()
                self._content_type = _EXT_TO_WKWEBVIEW_MIME.get(
                    ext, "application/octet-stream"
                )

            log.info(
                "stream_proxy_cdn_headers",
                status=resp.status_code,
                content_type=self._content_type,
                content_length_mb=total_mb,
                tmpfile=tmpfile,
            )

            # Unblock start() now that headers are available
            self._headers_ready.set()

            # Log download progress every _LOG_EVERY_MB megabytes
            _LOG_EVERY_MB = 25
            _next_log_mb = _LOG_EVERY_MB

            with open(tmpfile, "wb") as f:
                if download_start > 0:
                    # Seek the temp file so content lands at the right offset.
                    f.seek(download_start)

                for chunk in resp.iter_content(chunk_size=_DOWNLOAD_CHUNK):
                    if self._stop_flag:
                        log.info("stream_proxy_download_aborted", written_mb=self._written // (1024 * 1024))
                        break
                    if chunk:
                        f.write(chunk)
                        f.flush()
                        with self._lock:
                            self._written += len(chunk)
                            written = self._written
                            total = self._total_size
                        self._data_event.set()

                        written_mb = written // (1024 * 1024)
                        if written_mb >= _next_log_mb:
                            dl_start = download_start
                            remaining = total - dl_start if total > 0 else 0
                            bytes_dl = written - dl_start
                            pct = f"{bytes_dl / remaining * 100:.1f}%" if remaining > 0 else "?%"
                            log.info(
                                "stream_proxy_download_progress",
                                written_mb=written_mb,
                                total_mb=total // (1024 * 1024) if total else 0,
                                percent=pct,
                            )
                            _next_log_mb = written_mb + _LOG_EVERY_MB

            with self._lock:
                self._download_done = True
            self._data_event.set()
            log.info(
                "stream_proxy_download_complete",
                mb=self._written // (1024 * 1024),
                tmpfile=tmpfile,
            )

        except Exception as exc:
            self._headers_ready.set()  # always unblock start()
            with self._lock:
                self._download_error = str(exc)
                self._download_done = True
            self._data_event.set()
            log.error("stream_proxy_download_error", error=str(exc)[:200])

    # ------------------------------------------------------------------
    # HTTP server
    # ------------------------------------------------------------------

    def _start_server(self) -> None:
        proxy = self

        class _Handler(http.server.BaseHTTPRequestHandler):
            # Speak HTTP/1.1 so we can send proper Content-Length +
            # keep-alive / close headers; VLC requires this for seekable files.
            protocol_version = "HTTP/1.1"

            # ── State snapshot ────────────────────────────────────────

            def _snap(self):
                with proxy._lock:
                    return (
                        proxy._tmpfile,
                        proxy._cdn_url,
                        proxy._total_size,
                        proxy._written,
                        proxy._download_done,
                        proxy._stop_flag,
                    )

            def _wait_for(self, min_bytes: int, timeout: float = 60.0) -> bool:
                deadline = time.time() + timeout
                iba = proxy._is_byte_available
                while time.time() < deadline:
                    _, _, _, written, done, stopped = self._snap()
                    if written >= min_bytes or done or stopped:
                        return True
                    # Non-sequential fallback: libtorrent may have the piece
                    # at min_bytes even though the sequential watermark hasn't
                    # reached it yet (tail moov atom, head file-header pieces).
                    if iba and iba(min_bytes):
                        return True
                    time.sleep(0.05)
                return False

            # ── Request handlers ──────────────────────────────────────

            def do_HEAD(self):  # noqa: N802
                tmpfile, _, total, _, _, _ = self._snap()
                if not tmpfile:
                    self.send_error(503, "No stream active")
                    return
                self.send_response(200)
                self._common_headers(total)
                if total:
                    self.send_header("Content-Length", str(total))
                self.end_headers()

            def do_GET(self):  # noqa: N802
                rng = self.headers.get("Range", "")
                if rng:
                    self._serve_range(rng)
                else:
                    self._serve_full()

            # ── Common headers ────────────────────────────────────────

            def _common_headers(self, total: int) -> None:
                self.send_header("Content-Type", proxy._content_type)
                self.send_header("Accept-Ranges", "bytes")
                # Keep the TCP connection open for subsequent VLC requests.
                # Use close only when size is unknown (chunked-like streaming).
                self.send_header("Connection", "keep-alive" if total else "close")

            # ── Full (non-range) response ─────────────────────────────

            def _serve_full(self) -> None:
                tmpfile, _, total, _, _, _ = self._snap()
                if not tmpfile:
                    self.send_error(503, "No stream active")
                    return

                self.send_response(200)
                self._common_headers(total)
                if total:
                    self.send_header("Content-Length", str(total))
                self.end_headers()

                try:
                    with open(tmpfile, "rb") as f:
                        self._stream_from(f, end_offset=None)
                except (BrokenPipeError, ConnectionResetError):
                    pass
                except Exception as exc:
                    log.debug("proxy_full_serve_err", error=str(exc)[:120])

            # ── Range (206) response ──────────────────────────────────

            def _serve_range(self, rng_hdr: str) -> None:
                tmpfile, cdn_url, total, written, done, _ = self._snap()
                if not tmpfile:
                    self.send_error(503, "No stream active")
                    return

                m = re.match(r"bytes=(\d+)-(\d*)", rng_hdr)
                if not m:
                    self.send_error(400, "Bad Range header")
                    return

                start = int(m.group(1))
                end: Optional[int] = int(m.group(2)) if m.group(2) else None
                if end is None and total:
                    end = total - 1

                log.debug(
                    "proxy_range_request",
                    start_mb=f"{start / (1024*1024):.1f}",
                    end_mb=f"{end / (1024*1024):.1f}" if end is not None else "?",
                    written_mb=f"{written / (1024*1024):.1f}",
                    total_mb=f"{total / (1024*1024):.1f}" if total else "?",
                    buffer_ahead_mb=f"{max(0, written - start) / (1024*1024):.1f}",
                )

                # Forward-seek bypass: VLC sometimes seeks to the tail of the
                # file to read MP4 moov atom metadata.  If the requested start
                # is far beyond the download head, fetch directly from the CDN.
                if not done and cdn_url and start > written + _FORWARD_SEEK_BYPASS:
                    log.info(
                        "proxy_forward_seek_cdn",
                        start_mb=start // (1024 * 1024),
                        written_mb=written // (1024 * 1024),
                    )
                    self._range_from_cdn(cdn_url, start, end, total)
                    return

                # Backward-offset bypass: when a resume download started at a
                # byte offset (e.g. 60%), the temp file has no content before
                # that offset.  Requests for the file header (e.g. MP4 moov
                # atom, MKV EBML header) land here — serve them from the CDN.
                dl_start = proxy._download_start
                if cdn_url and dl_start > 0 and start < dl_start:
                    log.info(
                        "proxy_backward_offset_cdn",
                        start_mb=start // (1024 * 1024),
                        offset_mb=dl_start // (1024 * 1024),
                    )
                    self._range_from_cdn(cdn_url, start, end, total)
                    return

                # Normal: wait until the download has reached start
                if not self._wait_for(start + 1):
                    self.send_error(503, "Timed out waiting for stream data")
                    return

                # Re-snap after wait (total may now be known)
                _, _, total, _, _, _ = self._snap()
                if end is None and total:
                    end = total - 1

                content_len = (end - start + 1) if end is not None else None

                self.send_response(206)
                self._common_headers(total)
                if content_len is not None:
                    self.send_header("Content-Length", str(content_len))
                if total:
                    self.send_header(
                        "Content-Range",
                        f"bytes {start}-{end if end is not None else '*'}/{total}",
                    )
                self.end_headers()

                try:
                    with open(tmpfile, "rb") as f:
                        f.seek(start)
                        self._stream_from(f, end_offset=end)
                except (BrokenPipeError, ConnectionResetError):
                    pass
                except Exception as exc:
                    log.debug("proxy_range_serve_err", error=str(exc)[:120])

            # ── CDN bypass for forward seeks ──────────────────────────

            def _range_from_cdn(
                self,
                cdn_url: str,
                start: int,
                end: Optional[int],
                total: int,
            ) -> None:
                rng = f"bytes={start}-{end}" if end is not None else f"bytes={start}-"
                try:
                    r = requests.get(
                        cdn_url, stream=True, timeout=30,
                        headers={"Range": rng, "User-Agent": "VLC/3.0"},
                    )
                    r.raise_for_status()

                    cr = r.headers.get("Content-Range", "")
                    cl = r.headers.get("Content-Length", "")

                    self.send_response(206)
                    self.send_header("Content-Type", proxy._content_type)
                    self.send_header("Accept-Ranges", "bytes")
                    if cl:
                        self.send_header("Content-Length", cl)
                        self.send_header("Connection", "keep-alive")
                    else:
                        self.send_header("Connection", "close")
                    if cr:
                        self.send_header("Content-Range", cr)
                    elif total:
                        self.send_header(
                            "Content-Range",
                            f"bytes {start}-{end if end is not None else '*'}/{total}",
                        )
                    self.end_headers()

                    for chunk in r.iter_content(chunk_size=65536):
                        if chunk:
                            self.wfile.write(chunk)

                except (BrokenPipeError, ConnectionResetError):
                    pass
                except Exception as exc:
                    log.debug("cdn_range_err", error=str(exc)[:120])

            # ── Streaming loop ────────────────────────────────────────

            def _stream_from(self, f, *, end_offset: Optional[int]) -> None:
                CHUNK = 65536
                while True:
                    if end_offset is not None:
                        remaining = end_offset - f.tell() + 1
                        if remaining <= 0:
                            break
                        read_sz = min(CHUNK, remaining)
                    else:
                        read_sz = CHUNK

                    # Pre-read gate: if we're at or beyond the sequential
                    # watermark, only read when the piece is confirmed on disk.
                    # Without this, libtorrent's pre-allocated (zero-filled)
                    # file regions are read and served as valid data, causing
                    # "Corrupt file" / HEVC decode errors in mpv.
                    # For the CDN path (no is_byte_available), _written tracks
                    # actual sequential bytes so cur >= written is a true stall.
                    _, _, _, written, done, stopped = self._snap()
                    cur = f.tell()
                    if not done and not stopped and cur >= written:
                        iba = proxy._is_byte_available
                        if not (iba and iba(cur)):
                            time.sleep(0.05)
                            continue

                    data = f.read(read_sz)
                    if data:
                        self.wfile.write(data)
                        # Update the high-water mark of bytes served to VLC so
                        # the adapter's buffer watchdog can track lead vs lag.
                        pos = f.tell()
                        with proxy._lock:
                            if pos > proxy._max_served:
                                proxy._max_served = pos
                        continue

                    # No data from read — OS hasn't flushed yet (CDN race) or
                    # file is truly empty at this position.
                    _, _, _, written, done, stopped = self._snap()
                    cur = f.tell()

                    if done or stopped:
                        break
                    if cur >= written:
                        iba = proxy._is_byte_available
                        if iba and iba(cur):
                            pass  # piece is on disk; retry read immediately
                        else:
                            time.sleep(0.05)
                    # else: written > cur but read() returned empty; retry immediately

            # ── Silence HTTP access log ───────────────────────────────

            def log_message(self, format, *args):  # noqa: A002
                pass

        self._server = _ThreadedHTTPServer((_PROXY_HOST, self._port), _Handler)
        self._server_thread = threading.Thread(
            target=self._server.serve_forever,
            daemon=True,
            name="stream-proxy-srv",
        )
        self._server_thread.start()
        log.info("stream_proxy_server_started", port=self._port)
