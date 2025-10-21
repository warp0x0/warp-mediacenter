"""Administrative CLI for inspecting and configuring Warp MediaCenter."""

from __future__ import annotations

import argparse
import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Mapping, Optional

from warp_mediacenter.config import settings
from warp_mediacenter.config.settings import library as library_settings
from warp_mediacenter.config.settings import paths as path_settings
from warp_mediacenter.config.settings import providers as provider_settings
from warp_mediacenter.config.settings.plugins import InstalledPlugin

from ._utils import (
    build_subparser,
    exit_with_error,
    print_json,
    require_subcommand,
    to_serializable,
)


def _load_raw_config_paths() -> Dict[str, Any]:
    config_file = Path(path_settings.__file__).resolve().parent.parent / "config_paths.json"
    if not config_file.exists():
        return {}
    try:
        with config_file.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except json.JSONDecodeError as exc:
        exit_with_error(f"Failed to parse config_paths.json: {exc}")
    return {}


def _write_raw_config_paths(payload: Mapping[str, Any]) -> None:
    config_file = Path(path_settings.__file__).resolve().parent.parent / "config_paths.json"
    config_file.parent.mkdir(parents=True, exist_ok=True)
    with config_file.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True, ensure_ascii=False)


def _refresh_paths() -> Dict[str, str]:
    path_settings.PATHS = path_settings.load_config_paths()
    return dict(path_settings.PATHS)


def _refresh_provider_settings() -> Dict[str, Any]:
    provider_settings.INFORMATION_PROVIDER_SETTINGS = provider_settings.load_information_provider_settings()
    return dict(provider_settings.INFORMATION_PROVIDER_SETTINGS)


def _refresh_proxy_settings() -> Dict[str, Any]:
    provider_settings.PROXY_SETTINGS = provider_settings.load_proxy_settings()
    return dict(provider_settings.PROXY_SETTINGS)


def _settings_payload(reload: bool = False) -> Dict[str, Any]:
    return to_serializable(settings.get_settings(reload=reload))


def _handle_settings_show(args: argparse.Namespace) -> None:
    payload = _settings_payload(reload=args.reload)
    print_json(payload)


def _handle_settings_update(args: argparse.Namespace) -> None:
    payload = library_settings.load_user_settings()
    if args.app_name:
        payload["app_name"] = args.app_name
    if args.env:
        payload["env"] = args.env
    if args.log_level:
        payload["log_level"] = args.log_level
    if args.task_workers is not None:
        payload["task_workers"] = args.task_workers
    library_settings.write_user_settings(payload)
    print_json(_settings_payload(reload=True))


def _handle_settings_library_paths(args: argparse.Namespace) -> None:
    try:
        updated = settings.update_library_path(args.kind, args.path)
    except ValueError as exc:
        exit_with_error(str(exc))
        return
    print_json(to_serializable(updated.library_paths))


def _handle_settings_plugins(args: argparse.Namespace) -> None:
    plugins = settings.get_installed_plugins()
    print_json({plugin_id: to_serializable(plugin) for plugin_id, plugin in plugins.items()})


def _handle_settings_show_paths(_: argparse.Namespace) -> None:
    library_paths = settings.get_settings().library_paths
    print_json(to_serializable(library_paths))


def _handle_paths_show(args: argparse.Namespace) -> None:
    if args.raw:
        payload = _load_raw_config_paths()
    else:
        payload = path_settings.PATHS
    print_json(to_serializable(payload))


def _handle_paths_set(args: argparse.Namespace) -> None:
    raw = _load_raw_config_paths()
    raw[args.key] = args.value
    _write_raw_config_paths(raw)
    refreshed = _refresh_paths()
    print_json(to_serializable(refreshed))


def _handle_paths_reload(_: argparse.Namespace) -> None:
    refreshed = _refresh_paths()
    print_json(to_serializable(refreshed))


def _handle_providers_list(_: argparse.Namespace) -> None:
    payload = provider_settings.list_provider_configs()
    print_json(to_serializable(payload))


def _handle_providers_show(args: argparse.Namespace) -> None:
    config = provider_settings.get_service_config(args.service)
    if config is None:
        exit_with_error(f"Service '{args.service}' is not defined in information provider settings")
        return
    print_json(to_serializable(config))


def _handle_providers_endpoints(args: argparse.Namespace) -> None:
    endpoints = provider_settings.get_provider_endpoints(args.service)
    print_json(to_serializable(endpoints))


def _handle_providers_pipelines(args: argparse.Namespace) -> None:
    if args.pipeline:
        payload = provider_settings.get_pipeline_config(args.pipeline)
        if payload is None:
            exit_with_error(f"Pipeline '{args.pipeline}' not found")
            return
        print_json(to_serializable(payload))
        return
    print_json(to_serializable(provider_settings.INFORMATION_PROVIDER_SETTINGS.get("pipelines", {})))


def _handle_providers_content_lists(args: argparse.Namespace) -> None:
    if args.list_key:
        payload = provider_settings.get_content_list_config(args.list_key)
        if payload is None:
            exit_with_error(f"Content list '{args.list_key}' not found")
            return
        print_json(to_serializable(payload))
        return
    print_json(to_serializable(provider_settings.list_content_lists()))


def _handle_providers_public_domain(args: argparse.Namespace) -> None:
    if args.source_key:
        payload = provider_settings.get_public_domain_source_config(args.source_key)
        if payload is None:
            exit_with_error(f"Public domain source '{args.source_key}' not found")
            return
        print_json(to_serializable(payload))
        return
    print_json(to_serializable(provider_settings.get_public_domain_sources()))


def _handle_providers_reload(_: argparse.Namespace) -> None:
    refreshed = _refresh_provider_settings()
    print_json(to_serializable(refreshed))


def _handle_providers_reload_proxy(_: argparse.Namespace) -> None:
    refreshed = _refresh_proxy_settings()
    print_json(to_serializable(refreshed))


def _handle_providers_proxy(_: argparse.Namespace) -> None:
    print_json(to_serializable(provider_settings.PROXY_SETTINGS))


def _handle_plugins_list(_: argparse.Namespace) -> None:
    plugins = settings.get_installed_plugins()
    print_json({plugin_id: to_serializable(plugin) for plugin_id, plugin in plugins.items()})


def _build_plugin(args: argparse.Namespace) -> InstalledPlugin:
    metadata: Dict[str, Any] = {}
    if args.metadata:
        try:
            metadata_payload = json.loads(args.metadata)
            if isinstance(metadata_payload, Mapping):
                metadata = dict(metadata_payload)
            else:
                exit_with_error("Metadata must be a JSON object")
        except json.JSONDecodeError as exc:
            exit_with_error(f"Failed to parse metadata JSON: {exc}")
    if args.metadata_file:
        path = Path(args.metadata_file)
        if not path.exists():
            exit_with_error(f"Metadata file '{path}' does not exist")
        try:
            metadata_payload = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            exit_with_error(f"Failed to parse metadata file: {exc}")
        if not isinstance(metadata_payload, Mapping):
            exit_with_error("Metadata file must contain a JSON object")
        metadata.update(metadata_payload)

    installed_at = args.installed_at or datetime.utcnow().isoformat() + "Z"
    description = args.description
    return InstalledPlugin(
        plugin_id=args.plugin_id,
        name=args.name or args.plugin_id,
        version=args.version,
        entrypoint=args.entrypoint,
        path=str(Path(args.path).expanduser()),
        installed_at=installed_at,
        description=description,
        estimated_memory_mb=args.estimated_memory,
        metadata=metadata,
    )


def _handle_plugins_register(args: argparse.Namespace) -> None:
    plugin = _build_plugin(args)
    updated = settings.register_installed_plugin(plugin)
    print_json(to_serializable(updated.plugins))


def _handle_plugins_remove(args: argparse.Namespace) -> None:
    updated = settings.remove_installed_plugin(args.plugin_id)
    print_json(to_serializable(updated.plugins))


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="warp-admin",
        description="Administer Warp MediaCenter settings and configuration files.",
    )
    subparsers = parser.add_subparsers(dest="command")
    require_subcommand(subparsers)

    # Settings -----------------------------------------------------------
    settings_parser = build_subparser(subparsers, "settings", help="Inspect and update core runtime settings.")
    settings_sub = settings_parser.add_subparsers(dest="settings_command")
    require_subcommand(settings_sub)

    show_settings = build_subparser(settings_sub, "show", help="Display the effective runtime settings.")
    show_settings.add_argument("--reload", action="store_true", help="Reload configuration files before displaying the settings.")
    show_settings.set_defaults(func=_handle_settings_show)

    update_settings = build_subparser(settings_sub, "update", help="Update user-level settings persisted on disk.")
    update_settings.add_argument("--app-name", help="Application display name.")
    update_settings.add_argument("--env", help="Runtime environment label.")
    update_settings.add_argument("--log-level", help="Logging level (e.g. INFO, DEBUG).")
    update_settings.add_argument("--task-workers", type=int, help="Preferred number of background task workers.")
    update_settings.set_defaults(func=_handle_settings_update)

    paths_settings = build_subparser(settings_sub, "paths", help="Show or change library search paths.")
    paths_settings_sub = paths_settings.add_subparsers(dest="paths_command")
    require_subcommand(paths_settings_sub)

    paths_show = build_subparser(paths_settings_sub, "show", help="Display the configured library paths.")
    paths_show.set_defaults(func=_handle_settings_show_paths)

    paths_set = build_subparser(paths_settings_sub, "set", help="Update a library path for movies or shows.")
    paths_set.add_argument("kind", choices=["movie", "show"], help="Library kind to update.")
    paths_set.add_argument("path", help="Filesystem path for the selected library kind.")
    paths_set.set_defaults(func=_handle_settings_library_paths)

    plugins_settings = build_subparser(settings_sub, "plugins", help="Inspect installed plugins recorded in settings.")
    plugins_settings.set_defaults(func=_handle_settings_plugins)

    # Paths --------------------------------------------------------------
    paths_parser = build_subparser(subparsers, "paths", help="Manage configuration file locations.")
    paths_sub = paths_parser.add_subparsers(dest="paths_command")
    require_subcommand(paths_sub)

    config_show = build_subparser(paths_sub, "show", help="Display configuration file locations.")
    config_show.add_argument("--raw", action="store_true", help="Show the raw config_paths.json payload instead of resolved paths.")
    config_show.set_defaults(func=_handle_paths_show)

    config_set = build_subparser(paths_sub, "set", help="Override a configuration path entry.")
    config_set.add_argument("key", help="Configuration key to override (e.g. information_provider_settings).")
    config_set.add_argument("value", help="Filesystem path or glob expression to store in config_paths.json.")
    config_set.set_defaults(func=_handle_paths_set)

    config_reload = build_subparser(paths_sub, "reload", help="Reload config_paths.json and display the effective mapping.")
    config_reload.set_defaults(func=_handle_paths_reload)

    # Providers ----------------------------------------------------------
    providers_parser = build_subparser(subparsers, "providers", help="Inspect information provider configuration.")
    providers_sub = providers_parser.add_subparsers(dest="providers_command")
    require_subcommand(providers_sub)

    providers_list = build_subparser(providers_sub, "list", help="List configured provider entries.")
    providers_list.set_defaults(func=_handle_providers_list)

    providers_show = build_subparser(providers_sub, "show", help="Display configuration for a specific provider service.")
    providers_show.add_argument("service", help="Provider service key (e.g. tmdb, trakt, public_domain).")
    providers_show.set_defaults(func=_handle_providers_show)

    providers_endpoints = build_subparser(providers_sub, "endpoints", help="Show endpoint configuration for a provider service.")
    providers_endpoints.add_argument("service", help="Provider service key.")
    providers_endpoints.set_defaults(func=_handle_providers_endpoints)

    providers_pipelines = build_subparser(providers_sub, "pipelines", help="Inspect pipeline definitions.")
    providers_pipelines.add_argument("pipeline", nargs="?", help="Optional pipeline key to inspect.")
    providers_pipelines.set_defaults(func=_handle_providers_pipelines)

    providers_content = build_subparser(providers_sub, "content-lists", help="List or inspect curated content lists.")
    providers_content.add_argument("list_key", nargs="?", help="Optional content list key to inspect.")
    providers_content.set_defaults(func=_handle_providers_content_lists)

    providers_public = build_subparser(providers_sub, "public-domain", help="Inspect public domain source configuration.")
    providers_public.add_argument("source_key", nargs="?", help="Optional source key to inspect.")
    providers_public.set_defaults(func=_handle_providers_public_domain)

    providers_reload = build_subparser(providers_sub, "reload", help="Reload information provider JSON configuration.")
    providers_reload.set_defaults(func=_handle_providers_reload)

    providers_proxy = build_subparser(providers_sub, "proxy", help="Show proxy configuration for outbound requests.")
    providers_proxy.set_defaults(func=_handle_providers_proxy)

    providers_proxy_reload = build_subparser(providers_sub, "reload-proxy", help="Reload proxysettings.json and display the payload.")
    providers_proxy_reload.set_defaults(func=_handle_providers_reload_proxy)

    # Plugins ------------------------------------------------------------
    plugins_parser = build_subparser(subparsers, "plugins", help="Manage plugin registry entries.")
    plugins_sub = plugins_parser.add_subparsers(dest="plugins_command")
    require_subcommand(plugins_sub)

    plugins_list = build_subparser(plugins_sub, "list", help="List installed plugins.")
    plugins_list.set_defaults(func=_handle_plugins_list)

    plugins_register = build_subparser(plugins_sub, "register", help="Register a new plugin entry.")
    plugins_register.add_argument("--plugin-id", required=True, help="Unique identifier for the plugin.")
    plugins_register.add_argument("--name", help="Human readable plugin name.")
    plugins_register.add_argument("--version", required=True, help="Plugin version string.")
    plugins_register.add_argument("--entrypoint", required=True, help="Python entrypoint for the plugin.")
    plugins_register.add_argument("--path", required=True, help="Filesystem path to the plugin package.")
    plugins_register.add_argument("--installed-at", help="ISO timestamp for the installation time. Defaults to now.")
    plugins_register.add_argument("--description", help="Optional description of the plugin.")
    plugins_register.add_argument("--estimated-memory", type=float, help="Estimated memory usage in megabytes.")
    plugins_register.add_argument("--metadata", help="Inline JSON object with custom metadata fields.")
    plugins_register.add_argument("--metadata-file", help="Path to a JSON file with metadata to merge.")
    plugins_register.set_defaults(func=_handle_plugins_register)

    plugins_remove = build_subparser(plugins_sub, "remove", help="Remove an installed plugin entry.")
    plugins_remove.add_argument("plugin_id", help="Identifier of the plugin to remove.")
    plugins_remove.set_defaults(func=_handle_plugins_remove)

    return parser


def main(argv: Optional[Any] = None) -> None:
    parser = _build_parser()
    args = parser.parse_args(argv)
    handler = getattr(args, "func", None)
    if handler is None:
        parser.print_help()
        return
    handler(args)


if __name__ == "__main__":  # pragma: no cover
    main()
