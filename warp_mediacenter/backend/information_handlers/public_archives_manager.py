"""Utilities for aggregating public-domain and Creative Commons media feeds."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, Mapping, Optional, Sequence

import requests
from requests import Response

from warp_mediacenter.backend.information_handlers.cache import InformationProviderCache
from warp_mediacenter.backend.information_handlers.models import (
    CatalogItem,
    LicenseTag,
    MediaModelFacade,
    MediaType,
)
from warp_mediacenter.config import settings

_SERVICE_NAME = "public_domain"
_DEFAULT_TIMEOUT = 20


@dataclass
class SourceDescriptor:
    key: str
    label: str
    base_url: str
    path: str
    default_params: Mapping[str, Any]
    headers: Mapping[str, str]


class PublicArchivesManager:
    """Fetches curated catalog entries from public-domain/CC friendly sources."""

    def __init__(
        self,
        *,
        facade: Optional[MediaModelFacade] = None,
        cache: Optional[InformationProviderCache] = None,
        session: Optional[requests.Session] = None,
    ) -> None:
        self._facade = facade or MediaModelFacade()
        self._cache = cache or InformationProviderCache()
        self._session = session or requests.Session()
        self._session.headers.setdefault("User-Agent", "WarpMC/1.0")
        self._sources = self._load_sources()

    # ------------------------------------------------------------------
    # Discovery helpers
    # ------------------------------------------------------------------
    def list_sources(self) -> Sequence[SourceDescriptor]:
        return list(self._sources.values())

    def get_source(self, key: str) -> Optional[SourceDescriptor]:
        return self._sources.get(key)

    # ------------------------------------------------------------------
    # Remote fetches
    # ------------------------------------------------------------------
    def fetch(self, key: str, *, params: Optional[Mapping[str, Any]] = None) -> Sequence[CatalogItem]:
        descriptor = self.get_source(key)
        if not descriptor:
            raise ValueError(f"Unknown public domain source '{key}'")

        merged_params = dict(descriptor.default_params)
        if params:
            merged_params.update(params)

        cached = self._cache.get(_SERVICE_NAME, f"{key}:{descriptor.path}", merged_params)
        if isinstance(cached, list):
            return [CatalogItem.model_validate(item) for item in cached]

        response = self._request(descriptor, merged_params)
        data = self._parse_response(descriptor, response)
        self._cache.set(
            _SERVICE_NAME,
            f"{key}:{descriptor.path}",
            merged_params,
            [item.model_dump() for item in data],
            status_code=response.status_code,
        )

        return data

    # ------------------------------------------------------------------
    # Local curated payloads
    # ------------------------------------------------------------------
    def list_curated_catalogs(self) -> Sequence[str]:
        catalog_dir = Path(settings.get_public_domain_catalog_dir())
        if not catalog_dir.exists():
            return []

        return sorted(path.stem for path in catalog_dir.glob("*.json"))

    def load_curated_catalog(self, key: str) -> Sequence[CatalogItem]:
        catalog_dir = Path(settings.get_public_domain_catalog_dir())
        path = catalog_dir / f"{key}.json"
        if not path.exists():
            raise FileNotFoundError(f"Curated catalog '{key}' not found at {path}")

        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Invalid JSON payload for catalog '{key}'") from exc

        items_payload: Iterable[Any]
        if isinstance(data, Mapping):
            if "items" in data and isinstance(data["items"], Iterable):
                items_payload = data["items"]
            else:
                items_payload = data.values()
        elif isinstance(data, Iterable):
            items_payload = data
        else:
            return []

        items: list[CatalogItem] = []
        for entry in items_payload:
            if not isinstance(entry, Mapping):
                continue
            media_type = self._resolve_media_type(entry.get("type") or entry.get("media_type"), default=MediaType.MOVIE)
            try:
                items.append(
                    self._facade.catalog_item(
                        entry,
                        source_tag=f"curated.{key}",
                        media_type=media_type,
                    )
                )
            except Exception:  # pragma: no cover - defensive conversion
                continue

        return items

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------
    def _load_sources(self) -> Dict[str, SourceDescriptor]:
        sources = settings.get_public_domain_sources()
        descriptors: Dict[str, SourceDescriptor] = {}
        for key, raw in sources.items():
            label = raw.get("label") or key
            base_url = raw.get("base_url")
            path = raw.get("path") or "/"
            if not base_url:
                continue
            default_params = raw.get("default_params", {}) or {}
            headers = raw.get("headers", {}) or {}
            descriptors[key] = SourceDescriptor(
                key=key,
                label=label,
                base_url=base_url.rstrip("/"),
                path=path,
                default_params=default_params,
                headers=headers,
            )

        return descriptors

    def _request(self, descriptor: SourceDescriptor, params: Mapping[str, Any]) -> Response:
        url = f"{descriptor.base_url}{descriptor.path}"
        try:
            response = self._session.get(
                url,
                params=params,
                headers=dict(descriptor.headers),
                timeout=_DEFAULT_TIMEOUT,
            )
        except requests.RequestException as exc:  # pragma: no cover - network failure
            raise RuntimeError(f"Failed to fetch {descriptor.key} catalog: {exc}") from exc

        if response.status_code >= 400:
            raise RuntimeError(
                f"Public domain source '{descriptor.key}' responded with {response.status_code}"
            )

        return response

    def _parse_response(self, descriptor: SourceDescriptor, response: Response) -> Sequence[CatalogItem]:
        try:
            payload = response.json()
        except ValueError as exc:
            raise RuntimeError(f"{descriptor.key} returned invalid JSON") from exc

        parser = self._parser_for(descriptor.key)

        return parser(descriptor, payload)

    # Individual parsers -------------------------------------------------
    def _parser_for(self, key: str):
        if "internet_archive" in key:
            return self._parse_internet_archive
        if "library_of_congress" in key:
            return self._parse_library_of_congress
        if "smithsonian" in key:
            return self._parse_smithsonian
        if "europeana" in key:
            return self._parse_europeana
        if "wikimedia" in key:
            return self._parse_wikimedia

        return self._parse_generic

    def _parse_internet_archive(
        self,
        descriptor: SourceDescriptor,
        payload: Mapping[str, Any],
    ) -> Sequence[CatalogItem]:
        docs = ((payload.get("response") or {}).get("docs") or [])
        items: list[CatalogItem] = []
        for doc in docs:
            if not isinstance(doc, Mapping):
                continue
            identifier = doc.get("identifier")
            if not identifier:
                continue
            entry = {
                "id": identifier,
                "title": doc.get("title") or identifier,
                "overview": doc.get("description"),
                "year": self._try_int(doc.get("date")),
                "external_url": f"https://archive.org/details/{identifier}",
                "downloads": doc.get("downloads"),
                "license": self._license_from_string(doc.get("licenseurl")),
            }
            media_type = MediaType.SHOW if "tv" in descriptor.key else MediaType.MOVIE
            try:
                items.append(
                    self._facade.catalog_item(
                        entry,
                        source_tag=descriptor.key,
                        media_type=media_type,
                    )
                )
            except Exception:
                continue

        return items

    def _parse_library_of_congress(
        self,
        descriptor: SourceDescriptor,
        payload: Mapping[str, Any],
    ) -> Sequence[CatalogItem]:
        results = payload.get("results") or []
        items: list[CatalogItem] = []
        for result in results:
            if not isinstance(result, Mapping):
                continue
            identifier = result.get("id") or result.get("url")
            if not identifier:
                continue
            entry = {
                "id": identifier,
                "title": result.get("title") or identifier,
                "overview": result.get("description"),
                "external_url": result.get("id") or result.get("url"),
                "genres": result.get("subjects", []),
                "license": self._license_from_string(result.get("rights")),
            }
            media_type = MediaType.SHOW if "television" in descriptor.key else MediaType.MOVIE
            try:
                items.append(
                    self._facade.catalog_item(
                        entry,
                        source_tag=descriptor.key,
                        media_type=media_type,
                    )
                )
            except Exception:
                continue

        return items

    def _parse_smithsonian(
        self,
        descriptor: SourceDescriptor,
        payload: Mapping[str, Any],
    ) -> Sequence[CatalogItem]:
        rows = ((payload.get("response") or {}).get("rows") or [])
        items: list[CatalogItem] = []
        for row in rows:
            if not isinstance(row, Mapping):
                continue
            identifier = row.get("id")
            if not identifier:
                continue
            content = row.get("content") if isinstance(row.get("content"), Mapping) else {}
            descriptive = content.get("descriptiveNonRepeating", {}) if isinstance(content, Mapping) else {}
            title_field = descriptive.get("title")
            if isinstance(title_field, Mapping):
                title_value = title_field.get("content")
            else:
                title_value = title_field
            freetext = content.get("freetext") if isinstance(content, Mapping) else {}
            notes = None
            if isinstance(freetext, Mapping):
                notes_field = freetext.get("notes")
                if isinstance(notes_field, list) and notes_field:
                    notes = notes_field[0].get("content") if isinstance(notes_field[0], Mapping) else notes_field[0]
                elif isinstance(notes_field, str):
                    notes = notes_field
            online_media = descriptive.get("online_media") if isinstance(descriptive, Mapping) else {}
            media_entries = online_media.get("media") if isinstance(online_media, Mapping) else []
            preview_url = None
            if isinstance(media_entries, Iterable):
                for media in media_entries:
                    if not isinstance(media, Mapping):
                        continue
                    if media.get("type") == "Video" and media.get("content"):
                        preview_url = media.get("content")
                        break
            rights = online_media.get("rights") if isinstance(online_media, Mapping) else None
            entry = {
                "id": identifier,
                "title": title_value or row.get("title") or identifier,
                "overview": notes,
                "external_url": descriptive.get("record_link") if isinstance(descriptive, Mapping) else None,
                "poster_url": preview_url,
                "license": self._license_from_string(rights) if rights else LicenseTag.CC0,
            }
            try:
                items.append(
                    self._facade.catalog_item(
                        entry,
                        source_tag=descriptor.key,
                        media_type=MediaType.MOVIE,
                    )
                )
            except Exception:
                continue

        return items

    def _parse_europeana(
        self,
        descriptor: SourceDescriptor,
        payload: Mapping[str, Any],
    ) -> Sequence[CatalogItem]:
        items_payload = payload.get("items") or []
        items: list[CatalogItem] = []
        for item in items_payload:
            if not isinstance(item, Mapping):
                continue
            identifier = item.get("id") or item.get("guid")
            if not identifier:
                continue
            preview = item.get("edmPreview")
            poster_url = None
            if isinstance(preview, Iterable):
                for url in preview:
                    poster_url = url
                    break
            rights = item.get("rights")
            if isinstance(rights, list) and rights:
                rights = rights[0]
            entry = {
                "id": identifier,
                "title": (item.get("title") or [identifier])[0] if isinstance(item.get("title"), list) else item.get("title") or identifier,
                "overview": item.get("dcDescription"),
                "external_url": item.get("guid") or item.get("link"),
                "poster_url": poster_url,
                "license": self._license_from_string(rights),
            }
            try:
                items.append(
                    self._facade.catalog_item(
                        entry,
                        source_tag=descriptor.key,
                        media_type=MediaType.MOVIE,
                    )
                )
            except Exception:
                continue

        return items

    def _parse_wikimedia(
        self,
        descriptor: SourceDescriptor,
        payload: Mapping[str, Any],
    ) -> Sequence[CatalogItem]:
        query = payload.get("query") or {}
        pages = query.get("pages") or {}
        items: list[CatalogItem] = []
        if not isinstance(pages, Mapping):
            return items
        for _, page in pages.items():
            if not isinstance(page, Mapping):
                continue
            page_id = page.get("pageid")
            title = page.get("title")
            imageinfo = page.get("imageinfo") or []
            preview_url = None
            license_tag = LicenseTag.UNKNOWN
            if isinstance(imageinfo, Iterable):
                for info in imageinfo:
                    if not isinstance(info, Mapping):
                        continue
                    preview_url = info.get("url")
                    extmeta = info.get("extmetadata") or {}
                    if isinstance(extmeta, Mapping):
                        license_tag = self._license_from_string(
                            (extmeta.get("LicenseShortName") or {}).get("value")
                            if isinstance(extmeta.get("LicenseShortName"), Mapping)
                            else extmeta.get("LicenseShortName")
                        )
                    break
            if not page_id:
                continue
            fallback_url = None
            if isinstance(title, str):
                fallback_url = f"https://commons.wikimedia.org/wiki/{title.replace(' ', '_')}"
            entry = {
                "id": str(page_id),
                "title": title or str(page_id),
                "poster_url": preview_url,
                "external_url": page.get("fullurl") or fallback_url,
                "license": license_tag,
            }
            try:
                items.append(
                    self._facade.catalog_item(
                        entry,
                        source_tag=descriptor.key,
                        media_type=MediaType.MOVIE,
                    )
                )
            except Exception:
                continue

        return items

    def _parse_generic(
        self,
        descriptor: SourceDescriptor,
        payload: Mapping[str, Any],
    ) -> Sequence[CatalogItem]:
        items: list[CatalogItem] = []
        if isinstance(payload, Mapping):
            iterable = payload.get("items") or payload.get("results") or payload.values()
        elif isinstance(payload, Iterable):
            iterable = payload
        else:
            return items

        for entry in iterable:
            if not isinstance(entry, Mapping):
                continue
            media_type = self._resolve_media_type(entry.get("type"), default=MediaType.MOVIE)
            try:
                items.append(
                    self._facade.catalog_item(
                        entry,
                        source_tag=descriptor.key,
                        media_type=media_type,
                    )
                )
            except Exception:
                continue

        return items

    # Utility helpers ----------------------------------------------------
    def _license_from_string(self, value: Any) -> LicenseTag:
        if isinstance(value, LicenseTag):
            return value
        if not value:
            return LicenseTag.UNKNOWN

        text = str(value).lower()
        if "public domain" in text or "pd" in text:
            return LicenseTag.PUBLIC_DOMAIN
        if "cc0" in text:
            return LicenseTag.CC0
        if "by-nc-sa" in text:
            return LicenseTag.CC_BY_NC_SA
        if "by-nc" in text:
            return LicenseTag.CC_BY_NC
        if "by-sa" in text:
            return LicenseTag.CC_BY_SA
        if "by-nd" in text:
            return LicenseTag.CC_BY_ND
        if "by" in text:
            return LicenseTag.CC_BY

        return LicenseTag.UNKNOWN

    def _try_int(self, value: Any) -> Optional[int]:
        try:
            return int(value)
        except (TypeError, ValueError):
            return None

    def _resolve_media_type(self, value: Any, *, default: MediaType) -> MediaType:
        if isinstance(value, MediaType):
            return value
        if isinstance(value, str):
            normalized = value.lower()
            for mt in MediaType:
                if mt.value == normalized:
                    return mt
        return default


__all__ = ["PublicArchivesManager", "SourceDescriptor"]