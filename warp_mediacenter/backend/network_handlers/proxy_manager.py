from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, Optional
from pathlib import Path
import time
import random

from warp_mediacenter.config.settings import (
    PROXY_SETTINGS,
    get_proxy_pool_path,
)



@dataclass
class ProxyState:
    url: str
    successes: int = 0
    failures: int = 0
    score: float = 0.0
    last_used_ts: float = 0.0
    last_good_ts: float = 0.0


@dataclass
class Stickiness:
    proxy_url: str
    expires_at: float


class ProxyManager:
    """
    Keeps a pool of proxies with health scoring + per-domain stickiness.
    Returns a dict suitable for `requests`, e.g. {"http": url, "https": url}.
    """

    def __init__(self):
        cfg = PROXY_SETTINGS or {}

        self.enabled: bool = bool(cfg.get("enabled", False))
        rotation = cfg.get("rotation", {}) or {}
        retry_cfg = cfg.get("retry", {}) or {}
        self.domain_overrides = cfg.get("domains", {}) or {}

        self.stickiness_seconds: int = int(rotation.get("stickiness_seconds", 600))
        self.max_failures_before_rotate: int = int(rotation.get("max_failures_before_rotate", 2))
        self.decay_half_life_seconds: int = int(rotation.get("decay_half_life_seconds", 900))

        self.retry_cfg = {
            "max_attempts": int(retry_cfg.get("max_attempts", 4)),
            "base_backoff_ms": int(retry_cfg.get("base_backoff_ms", 300)),
            "max_backoff_ms": int(retry_cfg.get("max_backoff_ms", 6000)),
            "jitter_ms": int(retry_cfg.get("jitter_ms", 250)),
        }

        pool_cfg = cfg.get("pool", {}) or {}
        self._pool_format: str = pool_cfg.get("format", "host:port:user:pass")
        self._pool_path: Path = Path(pool_cfg.get("file") or get_proxy_pool_path())

        # canonical proxy key -> state
        self._proxies: Dict[str, ProxyState] = {}
        # domain -> sticky mapping referencing canonical proxy key
        self._sticky: Dict[str, Stickiness] = {}

        if self.enabled:
            self._load_pool()

    # ------------------------ public API ------------------------

    def enabled_for_domain(self, domain: str) -> bool:
        return self.enabled and bool(self._proxies)

    def choose(self, domain: str) -> Optional[Dict[str, str]]:
        """
        Return a Requests-ready proxies dict, e.g. {"http": url, "https": url},
        honoring per-domain stickiness.
        """
        if not self.enabled_for_domain(domain):
            return None

        now = time.time()
        st = self._sticky.get(domain)
        if st and st.expires_at > now:
            url = st.proxy_key
            return {"http": url, "https": url}

        best = self._choose_best_state()
        if not best:
            return None

        stick_secs = int(self.domain_overrides.get(domain, {}).get("stickiness_seconds", self.stickiness_seconds))
        self._sticky[domain] = Stickiness(proxy_url=best.url, expires_at=now + stick_secs)
        
        return {"http": best.url, "https": best.url}

    def mark_good(self, proxies: Optional[Dict[str, str]]) -> None:
        key = self._extract_key(proxies)
        if not key:
            return
        st = self._proxies.get(key)
        if not st:
            return
        st.successes += 1
        st.last_good_ts = st.last_used_ts = time.time()
        st.score += 1.0

    def mark_bad(self, proxies: Optional[Dict[str, str]]) -> None:
        key = self._extract_key(proxies)
        if not key:
            return
        st = self._proxies.get(key)
        if not st:
            return
        st.failures += 1
        st.last_used_ts = time.time()
        st.score -= 1.2

        if st.failures >= self.max_failures_before_rotate:
            # clear stickiness pointing to this proxy
            for domain, sticky in list(self._sticky.items()):
                if sticky.proxy_key == key:
                    del self._sticky[domain]

    # ------------------------ internals -------------------------

    def _extract_key(self, proxies: Optional[Dict[str, str]]) -> Optional[str]:
        if not proxies:
            return None
        
        # Prefer https key if present, else http
        return proxies.get("https") or proxies.get("http")

    def _load_pool(self) -> None:
        if not self._pool_path.exists():
            return
        with self._pool_path.open("r", encoding="utf-8") as f:
            lines = [ln.strip() for ln in f if ln.strip()]
        for line in lines:
            url = self._to_requests_proxy_url(line)
            if url:
                # canonical key is the URL string
                self._proxies[url] = ProxyState(url=url)

    def _to_requests_proxy_url(self, raw: str) -> Optional[str]:
        """
        Accepts pool format specified in config (default 'host:port:user:pass').
        Produces 'http://user:pass@host:port' which `requests` understands.
        """
        fmt = self._pool_format
        if fmt == "host:port:user:pass":
            parts = raw.split(":")
            if len(parts) < 4:
                return None
            host, port, user, pwd = parts[0], parts[1], parts[2], ":".join(parts[3:])
            return f"http://{user}:{pwd}@{host}:{port}"
        elif fmt in ("http://user:pass@host:port", "http|https"):
            # already a URL; passthrough
            return raw
        else:
            # unknown format; try to pass-through
            return raw

    def _choose_best_state(self) -> Optional[ProxyState]:
        if not self._proxies:
            return None
        now = time.time()
        for st in self._proxies.values():
            self._decay(st, now)

        ranked = sorted(
            self._proxies.values(),
            key=lambda s: (s.score, -s.failures, random.random()),
            reverse=True
        )
        
        return ranked[0]

    def _decay(self, st: ProxyState, now: float) -> None:
        if self.decay_half_life_seconds <= 0:
            return
        last = st.last_used_ts or now
        dt = max(0.0, now - last)
        if dt <= 0.0:
            return
        halves = dt / float(self.decay_half_life_seconds)
        st.score *= (0.5 ** halves)
