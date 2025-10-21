"""Media-focused CLI for Warp MediaCenter operations."""

from __future__ import annotations

import argparse
import sys
from datetime import datetime
from typing import Any, MutableMapping, Optional, Sequence

from warp_mediacenter.backend.information_handlers.models import MediaType
from warp_mediacenter.backend.information_handlers.providers import InformationProviders
from warp_mediacenter.backend.information_handlers.trakt_manager import (
    DeviceAuthPollingError,
    TraktManager,
)
from ._utils import (
    build_subparser,
    exit_with_error,
    parse_key_value_pairs,
    print_json,
    require_subcommand,
    to_serializable,
)

from warp_mediacenter.config import settings

_PROVIDERS: Optional[InformationProviders] = None


def _providers() -> InformationProviders:
    global _PROVIDERS
    if _PROVIDERS is None:
        _PROVIDERS = InformationProviders()
    return _PROVIDERS


def _ensure_trakt() -> TraktManager:
    manager = _providers().trakt
    if manager is None:
        error = _providers().trakt_error
        if error is not None:
            exit_with_error(f"Trakt is unavailable: {error}")
        exit_with_error("Trakt configuration is missing. Set TRAKT_CLIENT_ID and TRAKT_CLIENT_SECRET in settings.")
    return manager


def _handle_search_tmdb(args: argparse.Namespace) -> None:
    provider = _providers().tmdb
    if args.media_type == "movie":
        results = provider.search_movies(
            args.query,
            language=args.language,
            page=args.page,
            include_adult=args.include_adult,
        )
    else:
        results = provider.search_shows(
            args.query,
            language=args.language,
            page=args.page,
        )
    print_json(to_serializable(results))


def _handle_search_trakt(args: argparse.Namespace) -> None:
    manager = _ensure_trakt()
    types = [MediaType(args.media_type)] if args.media_type else None
    results = manager.search(
        args.query,
        types=types,
        limit=args.limit,
        year=args.year,
    )
    print_json(to_serializable(results))


def _handle_search_public_domain(args: argparse.Namespace) -> None:
    archives = _providers().public_archives
    params = parse_key_value_pairs(args.param or [])
    try:
        results = archives.fetch(args.source, params=params)
    except Exception as exc:
        exit_with_error(str(exc))
        return
    print_json(to_serializable(results))


def _handle_public_domain_list_sources(_: argparse.Namespace) -> None:
    archives = _providers().public_archives
    print_json(to_serializable(archives.list_sources()))


def _handle_public_domain_curated(args: argparse.Namespace) -> None:
    archives = _providers().public_archives
    if args.catalog:
        try:
            payload = archives.load_curated_catalog(args.catalog)
        except Exception as exc:
            exit_with_error(str(exc))
            return
        print_json(to_serializable(payload))
        return
    print_json(to_serializable(archives.list_curated_catalogs()))


def _handle_tmdb_movie_details(args: argparse.Namespace) -> None:
    provider = _providers().tmdb
    try:
        movie = provider.movie_details(
            args.movie_id,
            language=args.language,
            include_credits=not args.skip_credits,
        )
    except Exception as exc:
        exit_with_error(str(exc))
        return
    print_json(to_serializable(movie))


def _handle_tmdb_show_details(args: argparse.Namespace) -> None:
    provider = _providers().tmdb
    try:
        show = provider.show_details(
            args.show_id,
            language=args.language,
            include_credits=not args.skip_credits,
        )
    except Exception as exc:
        exit_with_error(str(exc))
        return
    print_json(to_serializable(show))


def _handle_trakt_auth_start(_: argparse.Namespace) -> None:
    manager = _ensure_trakt()
    try:
        device = manager.start_device_auth()
    except Exception as exc:
        exit_with_error(str(exc))
        return
    print_json(to_serializable(device))


def _handle_trakt_auth_poll(args: argparse.Namespace) -> None:
    manager = _ensure_trakt()
    try:
        token = manager.poll_device_token(args.device_code)
    except DeviceAuthPollingError as exc:
        payload = {
            "error": exc.error,
            "description": exc.description,
            "retry_interval": exc.retry_interval,
            "should_retry": exc.should_retry,
        }
        print_json(payload)
        if exc.should_retry:
            sys.exit(2)
        sys.exit(1)
    except Exception as exc:
        exit_with_error(str(exc))
        return
    print_json(to_serializable(token))


def _handle_trakt_auth_status(_: argparse.Namespace) -> None:
    manager = _ensure_trakt()
    token = manager.current_token()
    if token is None:
        print_json({"authenticated": False})
        return
    expires_at = manager.token_expires_at()
    payload: MutableMapping[str, Any] = {
        "authenticated": True,
        "token": to_serializable(token),
        "expires_at": expires_at,
        "expires_at_iso": datetime.utcfromtimestamp(expires_at).isoformat() + "Z"
        if expires_at is not None
        else None,
    }
    print_json(payload)


def _handle_trakt_auth_clear(_: argparse.Namespace) -> None:
    manager = _ensure_trakt()
    manager.clear_token()
    print_json({"authenticated": False})


def _handle_trakt_profile(args: argparse.Namespace) -> None:
    manager = _ensure_trakt()
    try:
        profile = manager.get_profile(args.username or "me")
    except Exception as exc:
        exit_with_error(str(exc))
        return
    print_json(to_serializable(profile))


def _handle_trakt_lists(args: argparse.Namespace) -> None:
    manager = _ensure_trakt()
    try:
        lists = manager.get_user_lists(args.username or "me")
    except Exception as exc:
        exit_with_error(str(exc))
        return
    print_json(to_serializable(lists))


def _handle_trakt_history(args: argparse.Namespace) -> None:
    manager = _ensure_trakt()
    media_type = MediaType(args.media_type)
    try:
        history = manager.get_watched_history(
            media_type,
            limit=args.limit,
        )
    except Exception as exc:
        exit_with_error(str(exc))
        return
    print_json(to_serializable(history))


def _handle_endpoints(args: argparse.Namespace) -> None:
    endpoints = settings.get_provider_endpoints(args.service)
    print_json(to_serializable(endpoints))


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="warp-media",
        description="Interact with media providers and catalogs exposed by Warp MediaCenter.",
    )
    subparsers = parser.add_subparsers(dest="command")
    require_subcommand(subparsers)

    # Search -------------------------------------------------------------
    search_parser = build_subparser(subparsers, "search", help="Search across supported providers.")
    search_sub = search_parser.add_subparsers(dest="search_command")
    require_subcommand(search_sub)

    tmdb_search = build_subparser(search_sub, "tmdb", help="Query TMDb for movies or shows.")
    tmdb_search.add_argument("query", help="Text to search for.")
    tmdb_search.add_argument("--media-type", choices=["movie", "show"], default="movie", help="Type of catalog items to search.")
    tmdb_search.add_argument("--language", help="Optional ISO language code for localized results.")
    tmdb_search.add_argument("--page", type=int, default=1, help="Result page to request.")
    tmdb_search.add_argument("--include-adult", action="store_true", help="Include adult titles in movie search results.")
    tmdb_search.set_defaults(func=_handle_search_tmdb)

    trakt_search = build_subparser(search_sub, "trakt", help="Search Trakt (requires OAuth credentials).")
    trakt_search.add_argument("query", help="Text to search for.")
    trakt_search.add_argument("--media-type", choices=[t.value for t in MediaType], help="Restrict search to a specific media type.")
    trakt_search.add_argument("--limit", type=int, default=10, help="Maximum number of results to request.")
    trakt_search.add_argument("--year", type=int, help="Restrict search to a given year.")
    trakt_search.set_defaults(func=_handle_search_trakt)

    public_search = build_subparser(search_sub, "public-domain", help="Fetch media from configured public-domain sources.")
    public_search.add_argument("source", help="Public domain source key to query.")
    public_search.add_argument("--param", action="append", help="Optional KEY=VALUE parameter forwarded to the remote source.")
    public_search.set_defaults(func=_handle_search_public_domain)

    # TMDb ---------------------------------------------------------------
    tmdb_parser = build_subparser(subparsers, "tmdb", help="Interact with TMDb endpoints.")
    tmdb_sub = tmdb_parser.add_subparsers(dest="tmdb_command")
    require_subcommand(tmdb_sub)

    movie_details = build_subparser(tmdb_sub, "movie", help="Fetch detailed information about a TMDb movie by ID.")
    movie_details.add_argument("movie_id", help="TMDb movie identifier.")
    movie_details.add_argument("--language", help="Optional ISO language code for localized details.")
    movie_details.add_argument("--skip-credits", action="store_true", help="Skip retrieving credits to reduce payload size.")
    movie_details.set_defaults(func=_handle_tmdb_movie_details)

    show_details = build_subparser(tmdb_sub, "show", help="Fetch detailed information about a TMDb TV show by ID.")
    show_details.add_argument("show_id", help="TMDb show identifier.")
    show_details.add_argument("--language", help="Optional ISO language code for localized details.")
    show_details.add_argument("--skip-credits", action="store_true", help="Skip retrieving credits to reduce payload size.")
    show_details.set_defaults(func=_handle_tmdb_show_details)

    # Public domain ------------------------------------------------------
    public_parser = build_subparser(subparsers, "public-domain", help="Explore curated and remote public-domain catalogs.")
    public_sub = public_parser.add_subparsers(dest="public_command")
    require_subcommand(public_sub)

    public_list = build_subparser(public_sub, "list-sources", help="List remote public-domain sources.")
    public_list.set_defaults(func=_handle_public_domain_list_sources)

    public_curated = build_subparser(public_sub, "curated", help="List or inspect curated public-domain catalogs bundled locally.")
    public_curated.add_argument("catalog", nargs="?", help="Optional curated catalog key to load.")
    public_curated.set_defaults(func=_handle_public_domain_curated)

    public_fetch = build_subparser(public_sub, "fetch", help="Fetch entries from a remote public-domain source.")
    public_fetch.add_argument("source", help="Public domain source key.")
    public_fetch.add_argument("--param", action="append", help="Optional KEY=VALUE parameter forwarded to the remote source.")
    public_fetch.set_defaults(func=_handle_search_public_domain)

    # Trakt --------------------------------------------------------------
    trakt_parser = build_subparser(subparsers, "trakt", help="Interact with Trakt endpoints (requires OAuth configuration).")
    trakt_sub = trakt_parser.add_subparsers(dest="trakt_command")
    require_subcommand(trakt_sub)

    trakt_auth = build_subparser(trakt_sub, "auth", help="Perform OAuth device flow operations.")
    trakt_auth_sub = trakt_auth.add_subparsers(dest="auth_command")
    require_subcommand(trakt_auth_sub)

    trakt_auth_start = build_subparser(trakt_auth_sub, "start", help="Start the Trakt device authorization flow.")
    trakt_auth_start.set_defaults(func=_handle_trakt_auth_start)

    trakt_auth_poll = build_subparser(trakt_auth_sub, "poll", help="Exchange a device code for an access token.")
    trakt_auth_poll.add_argument("device_code", help="Device code returned by the 'start' command.")
    trakt_auth_poll.set_defaults(func=_handle_trakt_auth_poll)

    trakt_auth_status = build_subparser(trakt_auth_sub, "status", help="Show the current authentication status.")
    trakt_auth_status.set_defaults(func=_handle_trakt_auth_status)

    trakt_auth_clear = build_subparser(trakt_auth_sub, "clear", help="Forget cached OAuth tokens.")
    trakt_auth_clear.set_defaults(func=_handle_trakt_auth_clear)

    trakt_profile = build_subparser(trakt_sub, "profile", help="Fetch the authenticated user's profile or another username.")
    trakt_profile.add_argument("--username", help="Optional Trakt username; defaults to the authenticated user.")
    trakt_profile.set_defaults(func=_handle_trakt_profile)

    trakt_lists = build_subparser(trakt_sub, "lists", help="List Trakt custom lists for a user.")
    trakt_lists.add_argument("--username", help="Optional Trakt username; defaults to the authenticated user.")
    trakt_lists.set_defaults(func=_handle_trakt_lists)

    trakt_history = build_subparser(trakt_sub, "history", help="Show the watched history for the authenticated user.")
    trakt_history.add_argument("--media-type", choices=[t.value for t in MediaType], default=MediaType.MOVIE.value, help="Media type to query.")
    trakt_history.add_argument("--limit", type=int, default=25, help="Maximum number of history entries to fetch.")
    trakt_history.set_defaults(func=_handle_trakt_history)

    trakt_search_cmd = build_subparser(trakt_sub, "search", help="Shortcut for the Trakt search command requiring authentication.")
    trakt_search_cmd.add_argument("query", help="Text to search for.")
    trakt_search_cmd.add_argument("--media-type", choices=[t.value for t in MediaType], help="Restrict search to a specific media type.")
    trakt_search_cmd.add_argument("--limit", type=int, default=10, help="Maximum number of results to request.")
    trakt_search_cmd.add_argument("--year", type=int, help="Restrict search to a given year.")
    trakt_search_cmd.set_defaults(func=_handle_search_trakt)

    # Endpoints ----------------------------------------------------------
    endpoints_parser = build_subparser(subparsers, "endpoints", help="Display configured REST endpoints for a provider service.")
    endpoints_parser.add_argument("service", help="Provider service key (tmdb, trakt, public_domain, ...).")
    endpoints_parser.set_defaults(func=_handle_endpoints)

    return parser


def main(argv: Optional[Sequence[str]] = None) -> None:
    parser = _build_parser()
    args = parser.parse_args(argv)
    handler = getattr(args, "func", None)
    if handler is None:
        parser.print_help()
        return
    handler(args)


if __name__ == "__main__":  # pragma: no cover
    main()
