from __future__ import annotations

"""Small stdlib HTTP helpers for subtitle provider adapters."""

from typing import Any, Optional
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import json

from warp_mediacenter.backend.player.exceptions import SubtitleDownloadError, SubtitleProviderUnavailable


_ISO3_TO_ISO1 = {
    "eng": "en", "fra": "fr", "fre": "fr", "deu": "de", "ger": "de", "spa": "es",
    "ita": "it", "por": "pt", "rus": "ru", "jpn": "ja", "zho": "zh", "chi": "zh",
    "kor": "ko", "nld": "nl", "dut": "nl", "swe": "sv", "nor": "no", "dan": "da",
    "fin": "fi", "pol": "pl", "ces": "cs", "cze": "cs", "slk": "sk", "hun": "hu",
    "ron": "ro", "rum": "ro", "tur": "tr", "ara": "ar", "heb": "he", "tha": "th",
    "ind": "id", "vie": "vi", "ukr": "uk", "hrv": "hr", "srp": "sr", "bul": "bg",
    "ell": "el", "gre": "el", "cat": "ca", "slv": "sl",
}
_ISO1_TO_ENGLISH = {
    "en": "english", "fr": "french", "de": "german", "es": "spanish", "it": "italian",
    "pt": "portuguese", "ru": "russian", "ja": "japanese", "zh": "chinese", "ko": "korean",
    "nl": "dutch", "sv": "swedish", "no": "norwegian", "da": "danish", "fi": "finnish",
    "pl": "polish", "cs": "czech", "sk": "slovak", "hu": "hungarian", "ro": "romanian",
    "tr": "turkish", "ar": "arabic", "he": "hebrew", "th": "thai", "id": "indonesian",
    "vi": "vietnamese", "uk": "ukrainian", "hr": "croatian", "sr": "serbian", "bg": "bulgarian",
    "el": "greek", "ca": "catalan", "sl": "slovenian",
}


def iso1_language(value: str) -> str:
    raw = (value or "eng").strip().lower().replace("_", "-")
    if len(raw) == 2:
        return raw
    return _ISO3_TO_ISO1.get(raw, raw[:2] or "en")


def english_language(value: str) -> str:
    return _ISO1_TO_ENGLISH.get(iso1_language(value), value.lower() or "english")


def json_request(
    method: str,
    url: str,
    *,
    params: Optional[dict[str, Any]] = None,
    headers: Optional[dict[str, str]] = None,
    body: Optional[dict[str, Any]] = None,
    timeout: int = 30,
) -> tuple[int, dict[str, str], Any]:
    full_url = url + (("?" + urlencode({k: v for k, v in (params or {}).items() if v is not None and v != ""})) if params else "")
    payload = json.dumps(body).encode("utf-8") if body is not None else None
    request = Request(full_url, data=payload, method=method, headers=headers or {})
    try:
        with urlopen(request, timeout=timeout) as response:
            text = response.read().decode("utf-8", errors="replace")
            return response.status, dict(response.headers), json.loads(text) if text else {}
    except HTTPError as exc:
        text = exc.read().decode("utf-8", errors="replace")
        try:
            payload_json = json.loads(text)
        except Exception:
            payload_json = {"error": text[:300]}
        return exc.code, dict(exc.headers), payload_json
    except URLError as exc:
        raise SubtitleProviderUnavailable(f"HTTP request failed for {url}: {exc.reason}") from exc


def bytes_request(url: str, *, headers: Optional[dict[str, str]] = None, timeout: int = 45) -> tuple[int, dict[str, str], bytes]:
    final_headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
        **(headers or {}),
    }
    request = Request(url, headers=final_headers)
    try:
        with urlopen(request, timeout=timeout) as response:
            return response.status, dict(response.headers), response.read()
    except HTTPError as exc:
        payload = exc.read()
        raise SubtitleDownloadError(f"Download failed ({exc.code}) from {url}: {payload[:120]!r}") from exc
    except URLError as exc:
        raise SubtitleDownloadError(f"Download failed from {url}: {exc.reason}") from exc


def require_status(provider: str, action: str, status: int, payload: Any) -> None:
    if 200 <= status < 300:
        return
    message = payload
    if isinstance(payload, dict):
        error = payload.get("error") or payload.get("message") or payload.get("detail")
        if isinstance(error, dict):
            message = error.get("message") or error
        elif error:
            message = error
    raise SubtitleProviderUnavailable(f"{provider} {action} failed ({status}): {message}")
