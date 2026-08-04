#!/usr/bin/env python3
"""Fetch every catalog list of every source through the real HTTP route.

Written after a row silently vanished from the home screen: a genre list carries
``params``, the route's ``_parse_params`` used ``json`` without importing it, and
the resulting 500 made the client hide the row as errored.  Nothing caught it —
the service-level tests called ``CatalogService.fetch`` directly, and the manual
curl checks happened to use lists that carry no params.

The lesson is the shape of the check, not the specific bug: a list is only
verified when it is fetched *the way the client fetches it*, over HTTP, with its
own declared params attached.  This walks all of them.

    python scripts/catalog_smoke.py [--base http://localhost:8000] [--source ID]

Exit status is non-zero when any list fails, so it can gate a release.
"""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any, Dict, List

try:
    import requests
except ImportError:  # pragma: no cover
    sys.exit("requests is required: pip install requests")


def check_list(
    base: str, source_id: str, definition: Dict[str, Any], media_type: str
) -> tuple[bool, str]:
    params: Dict[str, Any] = {"media_type": media_type, "limit": 40}
    if definition.get("params"):
        params["params"] = json.dumps(definition["params"])

    url = f"{base}/api/v1/catalog/source/{source_id}/{definition['id']}"
    try:
        response = requests.get(url, params=params, timeout=180)
    except Exception as exc:  # noqa: BLE001
        return False, f"request failed: {exc}"

    if response.status_code != 200:
        return False, f"HTTP {response.status_code}"

    try:
        body = response.json()
    except ValueError:
        return False, "response was not JSON"

    if body.get("error"):
        return False, f"error={body['error']}"

    count = body.get("count")
    if count is None:
        return False, "response has no 'count'"

    # An empty list is reported but not failed: a source can legitimately have
    # nothing right now (an unconfigured plugin, a dead upstream), and that is a
    # different problem from a list that cannot be fetched at all.
    return True, f"count={count}{' EMPTY' if count == 0 else ''}"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="http://localhost:8000")
    parser.add_argument("--source", help="only check this source id")
    args = parser.parse_args()

    base = args.base.rstrip("/")
    defs = requests.get(f"{base}/api/v1/catalog/definitions", timeout=60).json()

    failures: List[str] = []
    empties: List[str] = []
    checked = 0

    for source in defs.get("sources", []):
        if args.source and source["id"] != args.source:
            continue
        print(f"\n{source['id']}  ({source['kind']}, {len(source['lists'])} lists)")
        for definition in source["lists"]:
            for media_type in definition.get("media_types", []):
                checked += 1
                ok, detail = check_list(base, source["id"], definition, media_type)
                label = f"{definition['id']} [{media_type}]"
                if not ok:
                    failures.append(f"{source['id']}/{label}: {detail}")
                    print(f"  FAIL {label:40s} {detail}")
                elif "EMPTY" in detail:
                    empties.append(f"{source['id']}/{label}")
                    print(f"  warn {label:40s} {detail}")

    print(f"\nchecked {checked} list/media-type combinations")
    print(f"  empty:    {len(empties)}")
    print(f"  failures: {len(failures)}")
    for failure in failures:
        print(f"    {failure}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
