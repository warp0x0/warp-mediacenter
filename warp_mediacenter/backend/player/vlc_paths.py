from __future__ import annotations

"""Helpers for locating and loading the VLC runtime (bundled or system-installed)."""

from pathlib import Path
import os
import shutil
import sys
from typing import Iterable, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.config import settings

log = get_logger(__name__)

_PLATFORM_HINTS: dict[str, tuple[str, ...]] = {
    "win32": ("win64", "win32"),
    "cygwin": ("win64", "win32"),
    "darwin": ("macos-arm64", "macos-x64", "macos"),
    "linux": ("linux-x86_64", "linux"),
}


class VLCRuntimePaths:
    """Container for VLC runtime locations."""

    def __init__(self, root: Path, lib_dir: Path, plugin_dir: Path):
        self.root = root
        self.lib_dir = lib_dir
        self.plugin_dir = plugin_dir

    def as_env(self) -> dict[str, str]:
        return {
            "PYTHON_VLC_MODULE_PATH": str(self.lib_dir),
            "VLC_PLUGIN_PATH": str(self.plugin_dir),
        }


def _candidate_roots(explicit_root: Optional[Path]) -> Iterable[Path]:
    if explicit_root:
        yield explicit_root
    default_root_str = settings.get_vlc_runtime_root()
    default_root = Path(default_root_str) if default_root_str else None
    if default_root:
        yield default_root


def _match_platform(root: Path) -> Optional[Path]:
    if not root.exists():
        return None
    platform_key = sys.platform
    hints = _PLATFORM_HINTS.get(platform_key, ())
    if not hints and platform_key.startswith("linux"):
        hints = _PLATFORM_HINTS.get("linux", ())
    for hint in hints:
        candidate = root / hint
        if candidate.exists():
            return candidate
    # Fall back to root if it already contains lib/plugins
    return root


def resolve_vlc_runtime(explicit_root: Optional[str] = None) -> Optional[VLCRuntimePaths]:
    """Resolve the packaged VLC runtime and configure environment variables."""

    for candidate_root in _candidate_roots(Path(explicit_root) if explicit_root else None):
        platform_root = _match_platform(candidate_root)
        if not platform_root:
            continue
        lib_dir = platform_root / "lib"
        plugin_dir = platform_root / "plugins"
        if not lib_dir.exists() or not plugin_dir.exists():
            log.warning(
                "vlc_runtime_missing_dirs",
                root=str(platform_root),
                lib_exists=lib_dir.exists(),
                plugin_exists=plugin_dir.exists(),
            )
            continue
        runtime = VLCRuntimePaths(candidate_root, lib_dir, plugin_dir)
        _apply_environment(runtime)
        return runtime
    log.error("vlc_runtime_not_found: %s", [str(p) for p in _candidate_roots(Path(explicit_root) if explicit_root else None)])
    return None


def _apply_environment(runtime: VLCRuntimePaths) -> None:
    env_vars = runtime.as_env()
    for key, value in env_vars.items():
        if os.environ.get(key) != value:
            os.environ[key] = value
    _extend_library_path(runtime.lib_dir)


## ---------------------------------------------------------------------------
# System VLC binary detection
# ---------------------------------------------------------------------------

_MACOS_VLC_CANDIDATES: tuple[str, ...] = (
    "/Applications/VLC.app/Contents/MacOS/VLC",
    "/opt/homebrew/bin/vlc",
    "/usr/local/bin/vlc",
)

_LINUX_VLC_CANDIDATES: tuple[str, ...] = (
    "/usr/bin/vlc",
    "/usr/local/bin/vlc",
    "/snap/bin/vlc",
)

_WINDOWS_VLC_CANDIDATES: tuple[str, ...] = (
    r"C:\Program Files\VideoLAN\VLC\vlc.exe",
    r"C:\Program Files (x86)\VideoLAN\VLC\vlc.exe",
)


def find_system_vlc_binary() -> Optional[str]:
    """Return the path to the system-installed VLC executable, or None.

    Search order:
    1. ``shutil.which("vlc")`` — respects PATH (Homebrew, system packages, etc.)
    2. Platform-specific well-known installation paths.
    """
    # PATH-based lookup first (covers Homebrew, package-manager installs, etc.)
    found = shutil.which("vlc")
    if found:
        log.debug("vlc_binary_found_via_which", path=found)
        return found

    if sys.platform == "darwin":
        candidates: tuple[str, ...] = _MACOS_VLC_CANDIDATES
    elif sys.platform.startswith("win"):
        candidates = _WINDOWS_VLC_CANDIDATES
    else:
        candidates = _LINUX_VLC_CANDIDATES

    for candidate in candidates:
        if Path(candidate).exists():
            log.debug("vlc_binary_found_via_path", path=candidate)
            return candidate

    log.warning("vlc_binary_not_found", searched=list(candidates))
    return None


def _extend_library_path(lib_dir: Path) -> None:
    if sys.platform.startswith("win"):
        path_var = "PATH"
    elif sys.platform == "darwin":
        path_var = "DYLD_LIBRARY_PATH"
    else:
        path_var = "LD_LIBRARY_PATH"
    existing = os.environ.get(path_var, "")
    parts = [str(lib_dir)]
    if existing:
        parts.append(existing)
    os.environ[path_var] = os.pathsep.join(parts)
