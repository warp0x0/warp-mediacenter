"""Subprocess manager for external services (Torrent-API-Py, etc.)."""

from __future__ import annotations

import subprocess
import time
import signal
import sys
from pathlib import Path
from typing import Optional

import aiohttp

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)


class ServiceManager:
    """Manages external service subprocesses with health checks and graceful shutdown."""

    def __init__(
        self,
        name: str,
        command: list[str],
        health_url: str,
        health_timeout: float = 30.0,
        health_interval: float = 1.0,
    ) -> None:
        self.name = name
        self.command = command
        self.health_url = health_url
        self.health_timeout = health_timeout
        self.health_interval = health_interval
        self._process: Optional[subprocess.Popen] = None

    def start(self) -> None:
        """Start the service subprocess."""
        log.info("service_starting", name=self.name, command=" ".join(self.command))

        self._process = subprocess.Popen(
            self.command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            preexec_fn=None if sys.platform == "win32" else lambda: signal.signal(signal.SIGPIPE, signal.SIG_DFL),
        )

        log.info("service_started", name=self.name, pid=self._process.pid)

    def wait_for_health(self) -> bool:
        """Wait for the service to become healthy.

        Returns True if healthy, False if timeout or process died.
        """
        if self._process is None:
            return False

        start = time.monotonic()
        while time.monotonic() - start < self.health_timeout:
            # Check if process is still running
            if self._process.poll() is not None:
                stdout_data = ""
                try:
                    stdout_data = self._process.stdout.read().decode("utf-8", errors="replace")[:500] if self._process.stdout else ""
                except Exception:
                    pass
                log.error("service_crashed", name=self.name, returncode=self._process.returncode, stderr=stdout_data)
                return False

            # Try health check
            try:
                import requests
                resp = requests.get(self.health_url, timeout=2)
                if resp.status_code == 200:
                    log.info("service_healthy", name=self.name, url=self.health_url)
                    return True
            except Exception:
                pass

            time.sleep(self.health_interval)

        log.error("service_health_timeout", name=self.name, timeout=self.health_timeout)
        return False

    def stop(self) -> None:
        """Gracefully stop the service subprocess."""
        if self._process is None:
            return

        log.info("service_stopping", name=self.name, pid=self._process.pid)

        try:
            self._process.terminate()
            try:
                self._process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                log.warning("service_force_kill", name=self.name)
                self._process.kill()
                self._process.wait(timeout=5)
        except Exception as exc:
            log.error("service_stop_failed", name=self.name, error=str(exc))

        log.info("service_stopped", name=self.name)

    @property
    def is_running(self) -> bool:
        """Check if the service process is still running."""
        if self._process is None:
            return False
        return self._process.poll() is None


class TorrentApiPyManager(ServiceManager):
    """Manages Torrent-API-Py subprocess."""

    def __init__(
        self,
        host: str = "127.0.0.1",
        port: int = 8009,
        executable: Optional[str] = None,
    ) -> None:
        self.host = host
        self.port = port
        self.executable = executable or self._find_executable()

        command = [
            "python",
            self.executable,
            "--host", host,
            "--port", str(port),
        ]

        super().__init__(
            name="torrent-api-py",
            command=command,
            health_url=f"http://{host}:{port}/health",
            health_timeout=30.0,
            health_interval=1.0,
        )

    @staticmethod
    def _find_executable() -> str:
        """Find Torrent-API-Py main.py entry point."""
        import os

        # 1. Env var override
        env_path = os.environ.get("TORRENT_API_MAIN_PATH")
        if env_path:
            p = Path(env_path)
            if p.exists() and p.is_file():
                return str(p)

        # 2. Sibling directory relative to warp-mediacenter project
        project_root = Path(__file__).resolve().parents[3]
        sibling_main = project_root / "Torrent-Api-py" / "main.py"
        if sibling_main.exists() and sibling_main.is_file():
            return str(sibling_main)

        # 3. Common locations
        candidates = [
            str(Path.home() / "Torrent-Api-py" / "main.py"),
            str(Path.home() / "torrent-api-py" / "main.py"),
            "/opt/torrent-api-py/main.py",
        ]
        for path in candidates:
            p = Path(path)
            if p.exists() and p.is_file():
                return str(p)

        return "torrent-api-py"  # Fallback
