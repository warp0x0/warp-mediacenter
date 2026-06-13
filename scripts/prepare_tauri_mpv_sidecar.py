from __future__ import annotations

import argparse
import io
import json
import os
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SIDECAR_ROOT = ROOT / "frontend" / "src-tauri" / "bin" / "macos-arm64"
SIDECAR_LIB = SIDECAR_ROOT / "lib"
SIDECAR_BIN = SIDECAR_ROOT / "mpv-sidecar.bin"

# Tauri sidecar binary — named with target triple so Tauri's bundler picks it up.
# Placed at src-tauri/bin/mpv-aarch64-apple-darwin; Tauri copies it to
# Contents/MacOS/mpv in the final .app bundle.
TAURI_SIDECAR_BIN = ROOT / "frontend" / "src-tauri" / "bin" / "mpv-aarch64-apple-darwin"

# Homebrew fallback source paths
HB_MPV_BIN = Path("/opt/homebrew/bin/mpv")
HB_LIBMPV = Path("/opt/homebrew/lib/libmpv.dylib")

HOMEBREW_API = "https://formulae.brew.sh/api/formula/{name}.json"
GHCR_TOKEN_URL = "https://ghcr.io/token?service=ghcr.io&scope=repository:homebrew/core/{name}:pull"
BOTTLE_PLATFORMS = ("arm64_sequoia", "arm64_sonoma", "arm64_monterey", "arm64_ventura")

TIMEOUT = 60


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return result.stdout


def _copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def _ensure_permissions(files: list[Path], *, mode: int) -> None:
    for f in files:
        f.chmod(mode)


_HB_PREFIX_PLACEHOLDER = "@@HOMEBREW_PREFIX@@"
_HB_PREFIX_REAL = "/opt/homebrew"
_HB_CELLAR_PLACEHOLDER = "@@HOMEBREW_CELLAR@@"
_HB_CELLAR_REAL = "/opt/homebrew/Cellar"


def _normalize_dep(dep_str: str) -> str:
    """Resolve Homebrew placeholders used in raw bottle dylibs.

    Bottles use two distinct placeholders:
      @@HOMEBREW_PREFIX@@  → /opt/homebrew          (top-level prefix)
      @@HOMEBREW_CELLAR@@  → /opt/homebrew/Cellar   (versioned Cellar path)
    Both must be resolved so Path operations and _find_sidecar_match work correctly.
    """
    dep_str = dep_str.replace(_HB_PREFIX_PLACEHOLDER, _HB_PREFIX_REAL)
    dep_str = dep_str.replace(_HB_CELLAR_PLACEHOLDER, _HB_CELLAR_REAL)
    return dep_str


def _otool_deps(path: Path) -> list[tuple[str, Path]]:
    """Return (raw_dep_str, normalized_path) for all Homebrew dylib deps of *path*.

    raw_dep_str is exactly what otool returned (may include Homebrew placeholders).
    normalized_path has placeholders resolved so Path.name gives the dylib filename.
    Both forms are returned so callers can pass the raw form to install_name_tool.
    """
    lines = _run(["otool", "-L", str(path)]).splitlines()
    deps: list[tuple[str, Path]] = []
    for line in lines[1:]:
        raw = line.strip()
        if not raw:
            continue
        dep_str = raw.split(" (", 1)[0]
        if (
            dep_str.startswith("/opt/homebrew/")
            or dep_str.startswith(_HB_PREFIX_PLACEHOLDER)
            or dep_str.startswith(_HB_CELLAR_PLACEHOLDER)
        ) and dep_str.endswith(".dylib"):
            deps.append((dep_str, Path(_normalize_dep(dep_str))))
    return deps


def _find_sidecar_match(dep: Path, sidecar_map: dict[str, str]) -> str | None:
    """Find the best sidecar filename to use when rewriting a dep reference.

    Handles two cases:
    - Exact name match: libavcodec.62.28.101.dylib → libavcodec.62.28.101.dylib
    - SONAME match: libavcodec.62.dylib → libavcodec.62.28.101.dylib
      (the dep uses only the major version; sidecar has the full version)
    """
    base = dep.name

    # Exact match
    if base in sidecar_map:
        return sidecar_map[base]

    # SONAME / major-version prefix match
    # e.g. dep=libavcodec.62.dylib → stem='libavcodec.62' → match 'libavcodec.62.*'
    stem = base.removesuffix(".dylib")
    for name in sidecar_map:
        candidate_stem = name.removesuffix(".dylib")
        if candidate_stem.startswith(stem + ".") or candidate_stem == stem:
            return sidecar_map[name]

    return None


def _codesign_adhoc(files: list[Path]) -> None:
    """Ad-hoc sign each file so macOS will load it after install_name_tool rewrites."""
    for f in files:
        subprocess.run(
            ["codesign", "--force", "--sign", "-", str(f)],
            check=True,
            capture_output=True,
        )


def _otool_all_dylib_deps(path: Path) -> list[tuple[str, str]]:
    """Return (raw_dep_string, dylib_basename) for every non-system dylib dep of *path*.

    Unlike _otool_deps, this includes @rpath/ and @executable_path/ references too,
    which is needed when rewriting an already-processed binary.
    """
    lines = _run(["otool", "-L", str(path)]).splitlines()
    deps: list[tuple[str, str]] = []
    for line in lines[1:]:
        raw = line.strip()
        if not raw:
            continue
        dep_str = raw.split(" (", 1)[0]
        if dep_str.startswith(("/usr/lib", "/System", "/usr/local/lib")):
            continue
        if dep_str.endswith(".dylib"):
            deps.append((dep_str, Path(dep_str).name))
    return deps


def _get_rpaths(binary: Path) -> list[str]:
    """Parse LC_RPATH entries from a Mach-O binary via otool -l."""
    try:
        out = _run(["otool", "-l", str(binary)])
    except subprocess.CalledProcessError:
        return []
    rpaths: list[str] = []
    in_rpath = False
    for line in out.splitlines():
        stripped = line.strip()
        if "LC_RPATH" in stripped:
            in_rpath = True
        elif in_rpath and stripped.startswith("path "):
            rpath = stripped.split("path ", 1)[1].split(" (", 1)[0].strip()
            rpaths.append(rpath)
            in_rpath = False
    return rpaths


def _prepare_tauri_sidecar(dylibs: list[Path]) -> None:
    """Create the Tauri sidecar binary at TAURI_SIDECAR_BIN from SIDECAR_BIN.

    The Tauri sidecar ends up at Contents/MacOS/mpv in the bundle.
    Dylibs end up at Contents/Resources/bin/macos-arm64/lib/.
    We use @rpath/<name> for all dylib references and add two rpath entries:
      - @executable_path/macos-arm64/lib  (dev: binary at bin/, dylibs at bin/macos-arm64/lib/)
      - @executable_path/../Resources/bin/macos-arm64/lib  (production bundle)
    """
    if not SIDECAR_BIN.exists():
        print(f"  [warn] SIDECAR_BIN not found, skipping Tauri sidecar")
        return

    TAURI_SIDECAR_BIN.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SIDECAR_BIN, TAURI_SIDECAR_BIN)
    TAURI_SIDECAR_BIN.chmod(0o755)

    sidecar_map: dict[str, str] = {lib.name: lib.name for lib in dylibs}

    # Rewrite all dylib references to @rpath/<name>
    for raw_str, dep_name in _otool_all_dylib_deps(TAURI_SIDECAR_BIN):
        target = _find_sidecar_match(Path(dep_name), sidecar_map)
        if target:
            subprocess.run(
                ["install_name_tool", "-change", raw_str, f"@rpath/{target}",
                 str(TAURI_SIDECAR_BIN)],
                check=True,
            )

    # Remove all existing rpaths (Homebrew absolute paths)
    for rpath in _get_rpaths(TAURI_SIDECAR_BIN):
        subprocess.run(
            ["install_name_tool", "-delete_rpath", rpath, str(TAURI_SIDECAR_BIN)],
            check=False,
        )

    # Add the two rpaths needed for dev and production bundle
    for rpath in [
        "@executable_path/macos-arm64/lib",
        "@executable_path/../Resources/bin/macos-arm64/lib",
    ]:
        subprocess.run(
            ["install_name_tool", "-add_rpath", rpath, str(TAURI_SIDECAR_BIN)],
            check=False,
        )

    # Ad-hoc sign so macOS accepts the rewritten binary
    subprocess.run(
        ["codesign", "--force", "--sign", "-", str(TAURI_SIDECAR_BIN)],
        check=True, capture_output=True,
    )
    print(f"  Tauri sidecar ready: {TAURI_SIDECAR_BIN}")


def _rewrite_links(executable: Path, dylibs: list[Path]) -> None:
    # Build name → name map for lookup (base names only)
    sidecar_map: dict[str, str] = {lib.name: lib.name for lib in dylibs}

    # Set each dylib's own install name to @rpath/<name>
    for lib in dylibs:
        subprocess.run(
            ["install_name_tool", "-id", f"@rpath/{lib.name}", str(lib)],
            check=True,
        )

    # Rewrite inter-dylib references (raw_str is what install_name_tool -change needs)
    for lib in dylibs:
        for raw_str, norm_path in _otool_deps(lib):
            match = _find_sidecar_match(norm_path, sidecar_map)
            if match:
                subprocess.run(
                    [
                        "install_name_tool",
                        "-change",
                        raw_str,
                        f"@loader_path/{match}",
                        str(lib),
                    ],
                    check=True,
                )

    # Rewrite executable → dylib references
    if executable.exists() and str(executable) != "/dev/null":
        for raw_str, norm_path in _otool_deps(executable):
            match = _find_sidecar_match(norm_path, sidecar_map)
            if match:
                subprocess.run(
                    [
                        "install_name_tool",
                        "-change",
                        raw_str,
                        f"@executable_path/lib/{match}",
                        str(executable),
                    ],
                    check=True,
                )


# ---------------------------------------------------------------------------
# Idempotency
# ---------------------------------------------------------------------------

def _is_sidecar_ready() -> bool:
    """Return True if the sidecar lib is complete, rewritten, AND ad-hoc signed.

    Checks three things:
    1. libmpv.dylib and libmpv.2.dylib exist with enough sibling dylibs.
    2. Install name of libmpv.2.dylib is @rpath/... (not a Homebrew absolute path).
    3. No dylib has un-rewritten @@HOMEBREW_CELLAR@@ or @@HOMEBREW_PREFIX@@ references
       in its dependency list (catches the partial-rewrite failure mode).
    4. Ad-hoc codesign is valid.
    """
    # Must have a reasonable set of dylibs.
    dylibs = list(SIDECAR_LIB.glob("*.dylib"))
    if len(dylibs) <= 5:
        return False

    # Pick a key dylib that is always present regardless of build source.
    # libavcodec is present in Homebrew, official release, and every mpv build.
    # libmpv.dylib is only present in Homebrew builds, not official releases.
    key_dylibs = sorted(SIDECAR_LIB.glob("libavcodec*.dylib"))
    if not key_dylibs:
        return False
    key_dylib = key_dylibs[0]

    # Verify install name is rewritten to @rpath/ (not an absolute path)
    try:
        result = subprocess.run(
            ["otool", "-D", str(key_dylib)],
            capture_output=True, text=True, check=True,
        )
        install_name = result.stdout.splitlines()[-1].strip()
        if not install_name.startswith("@rpath/"):
            return False
    except Exception:
        return False
    # Verify no dylib still has un-rewritten Homebrew placeholder references
    for dylib in dylibs:
        try:
            result = subprocess.run(
                ["otool", "-L", str(dylib)],
                capture_output=True, text=True, check=True,
            )
            for line in result.stdout.splitlines()[1:]:
                dep = line.strip().split(" (", 1)[0]
                if _HB_CELLAR_PLACEHOLDER in dep or _HB_PREFIX_PLACEHOLDER in dep:
                    return False  # still has un-rewritten bottle references
        except Exception:
            return False
    # Verify ad-hoc signature on the key dylib
    try:
        subprocess.run(
            ["codesign", "-v", str(key_dylib)],
            check=True, capture_output=True,
        )
    except Exception:
        return False

    # Verify Tauri sidecar binary exists and is signed
    if not TAURI_SIDECAR_BIN.exists():
        return False
    try:
        subprocess.run(
            ["codesign", "-v", str(TAURI_SIDECAR_BIN)],
            check=True, capture_output=True,
        )
    except Exception:
        return False

    return True


# ---------------------------------------------------------------------------
# Official GitHub release path: extract from mpv-*.zip
# ---------------------------------------------------------------------------

def _is_macho_binary(path: Path) -> bool:
    """Return True if the file starts with a Mach-O or fat-binary magic number."""
    try:
        with open(path, "rb") as f:
            magic = f.read(4)
        return magic in (
            b"\xfe\xed\xfa\xce",  # MH_MAGIC
            b"\xfe\xed\xfa\xcf",  # MH_MAGIC_64
            b"\xce\xfa\xed\xfe",  # MH_CIGAM
            b"\xcf\xfa\xed\xfe",  # MH_CIGAM_64
            b"\xca\xfe\xba\xbe",  # FAT_MAGIC
        )
    except Exception:
        return False


def _rewrite_dylibs_official(dylibs: list[Path]) -> None:
    """Rewrite install names for official-release dylibs (any path format).

    Sets each dylib's own install name to @rpath/<name> and rewrites all
    non-system inter-dylib references to @loader_path/<name>.  Works for
    @rpath/, @executable_path/../Frameworks/, and absolute path formats.
    """
    sidecar_map: dict[str, str] = {lib.name: lib.name for lib in dylibs}

    for lib in dylibs:
        # Own install name → @rpath/<name>
        subprocess.run(
            ["install_name_tool", "-id", f"@rpath/{lib.name}", str(lib)],
            check=True,
        )
        # Inter-dylib references → @loader_path/<name>
        for raw_str, dep_name in _otool_all_dylib_deps(lib):
            if dep_name == lib.name:
                continue
            match = _find_sidecar_match(Path(dep_name), sidecar_map)
            if match:
                subprocess.run(
                    ["install_name_tool", "-change", raw_str,
                     f"@loader_path/{match}", str(lib)],
                    check=True,
                )


def _extract_to_dir(zip_path: Path, dest: Path) -> None:
    """Fully extract a release zip into dest, unwrapping nested tar.gz if present.

    The official mpv macOS release is double-wrapped:
      mpv-vX.Y.Z-macos-*-arm.zip  →  contains mpv.tar.gz  →  contains mpv.app/
    This function handles both single-level zips and this nested format.
    """
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(dest)

    # If the zip contained only a tarball, extract that too
    tarballs = list(dest.glob("*.tar.gz")) + list(dest.glob("*.tar.xz"))
    for tarball in tarballs:
        print(f"  Unwrapping nested archive: {tarball.name}")
        with tarfile.open(tarball) as tf:
            tf.extractall(dest)
        tarball.unlink()


def _prepare_from_official_release(zip_path: Path) -> None:
    """Extract mpv binary + dylibs from an official mpv GitHub release zip.

    Handles the layout produced by the mpv-player/mpv macOS builds:
      mpv.app/Contents/MacOS/mpv          ← the executable
      mpv.app/Contents/MacOS/lib/*.dylib  ← bundled dylibs
      mpv.app/Contents/Frameworks/*.dylib ← extra dylibs (e.g. libMoltenVK)
    The zip may contain a nested mpv.tar.gz — that is unwrapped automatically.
    """
    if not zip_path.exists():
        raise FileNotFoundError(f"Release zip not found: {zip_path}")

    print(f"Extracting from official mpv release: {zip_path.name}")

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)

        _extract_to_dir(zip_path, tmp)

        # Strip Apple quarantine from everything extracted
        subprocess.run(["xattr", "-cr", str(tmp)], check=False)

        # Locate the mpv Mach-O binary (file named 'mpv', not a dylib)
        mpv_bin: Path | None = None
        for candidate in sorted(tmp.rglob("mpv")):
            if candidate.is_file() and not candidate.name.endswith(".dylib"):
                if _is_macho_binary(candidate):
                    mpv_bin = candidate
                    break

        if mpv_bin is None:
            raise RuntimeError(
                "Could not find a Mach-O 'mpv' binary inside the zip.\n"
                "Inspect with:  unzip -l " + str(zip_path)
            )
        print(f"  Found binary : {mpv_bin.relative_to(tmp)}")

        # Collect all dylibs from MacOS/lib/ AND Frameworks/
        raw_dylibs = [d for d in tmp.rglob("*.dylib") if d.is_file()]
        if not raw_dylibs:
            raise RuntimeError("No .dylib files found inside the zip.")
        print(f"  Found {len(raw_dylibs)} dylibs")

        # Find MoltenVK ICD JSON (Vulkan loader needs it to locate libMoltenVK)
        icd_json_src: Path | None = next(tmp.rglob("MoltenVK_icd.json"), None)
        if icd_json_src:
            print(f"  Found ICD JSON: {icd_json_src.relative_to(tmp)}")

        # Wipe existing staging area and copy fresh files
        if SIDECAR_ROOT.exists():
            shutil.rmtree(SIDECAR_ROOT)
        SIDECAR_LIB.mkdir(parents=True, exist_ok=True)

        shutil.copy2(mpv_bin, SIDECAR_BIN)
        SIDECAR_BIN.chmod(0o755)

        copied_dylibs: list[Path] = []
        seen_names: set[str] = set()
        for dylib in raw_dylibs:
            if dylib.name in seen_names:
                continue        # skip duplicate names across Frameworks/ vs lib/
            seen_names.add(dylib.name)
            dst = SIDECAR_LIB / dylib.name
            shutil.copy2(dylib, dst)
            dst.chmod(0o644)
            copied_dylibs.append(dst)

        # Copy MoltenVK ICD JSON and rewrite library_path to the new flat layout.
        # Original: "../../../Frameworks/libMoltenVK.dylib" (relative to original JSON location)
        # New: "./libMoltenVK.dylib" (both JSON and dylib now live in SIDECAR_LIB)
        if icd_json_src:
            icd_dst = SIDECAR_LIB / "MoltenVK_icd.json"
            icd_data = json.loads(icd_json_src.read_text())
            icd_data["ICD"]["library_path"] = "./libMoltenVK.dylib"
            icd_dst.write_text(json.dumps(icd_data, indent=4))
            print(f"  Wrote MoltenVK_icd.json (library_path → ./libMoltenVK.dylib)")

        # Remove quarantine from copied files
        subprocess.run(["xattr", "-cr", str(SIDECAR_ROOT)], check=False)

    _ensure_libmpv_symlink()
    all_dylibs = list(SIDECAR_LIB.glob("*.dylib"))

    print("Rewriting dylib install names...")
    _rewrite_dylibs_official(all_dylibs)

    print("Ad-hoc signing dylibs + binary...")
    _codesign_adhoc(all_dylibs)
    _codesign_adhoc([SIDECAR_BIN])

    print("Preparing Tauri sidecar binary...")
    _prepare_tauri_sidecar(all_dylibs)

    print(f"Prepared {len(all_dylibs)} dylibs from official release → {SIDECAR_LIB}")


# ---------------------------------------------------------------------------
# Primary path: download Homebrew bottles directly (no brew required)
# ---------------------------------------------------------------------------

def _fetch_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": "warp-mediacenter-build/1.0"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return json.load(resp)


def _get_bottle_info(formula_name: str) -> dict | None:
    """Fetch formula metadata and return bottle info for the best available platform."""
    try:
        data = _fetch_json(HOMEBREW_API.format(name=formula_name))
    except Exception as exc:
        print(f"  [warn] Could not fetch formula {formula_name}: {exc}")
        return None

    bottle = data.get("bottle", {}).get("stable", {})
    files = bottle.get("files", {})
    for platform in BOTTLE_PLATFORMS:
        if platform in files:
            return {"formula": formula_name, "platform": platform, **files[platform]}
    return None


def _collect_formula_deps(root_formula: str) -> list[str]:
    """Return root formula + all recursive runtime dependencies (BFS, deduped)."""
    seen: set[str] = set()
    queue: list[str] = [root_formula]
    order: list[str] = []

    while queue:
        name = queue.pop(0)
        if name in seen:
            continue
        seen.add(name)
        order.append(name)
        try:
            data = _fetch_json(HOMEBREW_API.format(name=name))
        except Exception:
            continue
        for dep in data.get("dependencies", []):
            if dep not in seen:
                queue.append(dep)

    return order


def _ghcr_token(formula_name: str) -> str:
    url = GHCR_TOKEN_URL.format(name=formula_name)
    req = urllib.request.Request(url, headers={"User-Agent": "warp-mediacenter-build/1.0"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return json.load(resp)["token"]


def _download_bottle(bottle_url: str, token: str) -> bytes:
    """Download bottle tarball bytes from GHCR."""
    # bottle_url may look like: ghcr.io/v2/homebrew/core/mpv/blobs/sha256:...
    if not bottle_url.startswith("http"):
        bottle_url = "https://" + bottle_url
    req = urllib.request.Request(
        bottle_url,
        headers={
            "Authorization": f"Bearer {token}",
            "User-Agent": "warp-mediacenter-build/1.0",
        },
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return resp.read()


def _extract_dylibs(tarball_bytes: bytes, dest_dir: Path) -> list[Path]:
    """Extract all .dylib files from a bottle tarball into dest_dir."""
    collected: list[Path] = []
    with tarfile.open(fileobj=io.BytesIO(tarball_bytes), mode="r:gz") as tf:
        for member in tf.getmembers():
            if not member.isfile():
                continue
            name = Path(member.name).name
            if not name.endswith(".dylib"):
                continue
            out_path = dest_dir / name
            if out_path.exists():
                continue
            fobj = tf.extractfile(member)
            if fobj is None:
                continue
            out_path.write_bytes(fobj.read())
            collected.append(out_path)
    return collected


def _download_mpv_sidecar() -> None:
    """Primary path: download mpv + all deps via Homebrew bottles, no brew needed."""
    print("Fetching mpv dependency tree from Homebrew API...")
    formulas = _collect_formula_deps("mpv")
    print(f"  Resolved {len(formulas)} formulas (mpv + deps)")

    SIDECAR_LIB.mkdir(parents=True, exist_ok=True)

    mpv_bin_extracted: Path | None = None
    all_dylibs: list[Path] = []

    for formula in formulas:
        info = _get_bottle_info(formula)
        if info is None:
            print(f"  [skip] No bottle found for {formula}")
            continue

        url = info.get("url", "")
        if not url:
            print(f"  [skip] Empty bottle URL for {formula}")
            continue

        print(f"  Downloading {formula} ({info['platform']})...")
        try:
            token = _ghcr_token(formula)
            tarball = _download_bottle(url, token)
        except Exception as exc:
            print(f"  [warn] Download failed for {formula}: {exc}")
            continue

        # Extract dylibs into SIDECAR_LIB
        new_dylibs = _extract_dylibs(tarball, SIDECAR_LIB)
        all_dylibs.extend(new_dylibs)

        # Also look for the mpv binary in the mpv formula tarball.
        # Only extract if the sidecar binary doesn't already exist — never overwrite
        # a working (already-rewritten) binary with a fresh Homebrew bottle binary.
        if formula == "mpv" and mpv_bin_extracted is None and not SIDECAR_BIN.exists():
            with tarfile.open(fileobj=io.BytesIO(tarball), mode="r:gz") as tf:
                for member in tf.getmembers():
                    if not member.isfile():
                        continue
                    parts = Path(member.name).parts
                    # binary is typically at <cellar>/<version>/bin/mpv
                    if len(parts) >= 2 and parts[-1] == "mpv" and parts[-2] == "bin":
                        fobj = tf.extractfile(member)
                        if fobj is None:
                            continue
                        SIDECAR_BIN.parent.mkdir(parents=True, exist_ok=True)
                        SIDECAR_BIN.write_bytes(fobj.read())
                        mpv_bin_extracted = SIDECAR_BIN
                        break

    if not all_dylibs:
        raise RuntimeError("No dylibs extracted from any bottle — download may have failed")

    # Collect all dylibs now in SIDECAR_LIB (may include prior runs)
    all_dylibs = list(SIDECAR_LIB.glob("*.dylib"))

    # Create libmpv.dylib symlink if only versioned copy exists
    _ensure_libmpv_symlink()

    # Set permissions: 644 for dylibs, 755 for binary
    _ensure_permissions(all_dylibs, mode=0o644)
    if mpv_bin_extracted and mpv_bin_extracted.exists():
        _ensure_permissions([mpv_bin_extracted], mode=0o755)

    # Rewrite install names so dylibs are self-contained
    print("Rewriting dylib install names...")
    _rewrite_links(SIDECAR_BIN if SIDECAR_BIN.exists() else Path("/dev/null"), all_dylibs)

    # Ad-hoc sign all dylibs so macOS will load them and Tauri bundler can process them
    print("Ad-hoc signing dylibs...")
    sign_targets = list(SIDECAR_LIB.glob("*.dylib"))
    _codesign_adhoc(sign_targets)
    if SIDECAR_BIN.exists():
        _codesign_adhoc([SIDECAR_BIN])

    # Create Tauri sidecar binary (uses @rpath instead of @executable_path/lib/)
    print("Preparing Tauri sidecar binary...")
    _prepare_tauri_sidecar(all_dylibs)

    print(f"Downloaded and prepared {len(all_dylibs)} dylibs in {SIDECAR_LIB}")


def _ensure_libmpv_symlink() -> None:
    """Create libmpv.dylib as a hard copy of libmpv.2.dylib if needed.

    Uses a copy rather than a symlink so Tauri's resource bundler can process it
    as a regular file. The libmpv Rust crate links against -lmpv → libmpv.dylib.
    """
    unversioned = SIDECAR_LIB / "libmpv.dylib"
    if unversioned.exists():
        return
    candidates = sorted(SIDECAR_LIB.glob("libmpv.*.dylib"))
    if not candidates:
        return
    target = candidates[0]
    shutil.copy2(target, unversioned)
    unversioned.chmod(0o644)
    print(f"  Copied libmpv.dylib from {target.name}")


# ---------------------------------------------------------------------------
# Fallback path: copy from local Homebrew installation
# ---------------------------------------------------------------------------

def _homebrew_mpv_available() -> bool:
    return HB_MPV_BIN.exists() and HB_LIBMPV.exists()


def _collect_dependencies(seeds: list[Path]) -> dict[str, Path]:
    queued = [seed.resolve() for seed in seeds]
    visited: set[Path] = set()
    resolved: dict[str, Path] = {}

    while queued:
        current = queued.pop(0)
        if current in visited:
            continue
        visited.add(current)
        if current.name.endswith(".dylib"):
            resolved[current.name] = current
        for _raw, norm_path in _otool_deps(current):
            dep_resolved = norm_path.resolve()
            if dep_resolved not in visited:
                queued.append(dep_resolved)

    return resolved


def _copy_from_homebrew() -> None:
    """Fallback: copy mpv binary and all dylib deps from local Homebrew install."""
    print("Falling back to local Homebrew installation...")

    if SIDECAR_ROOT.exists():
        shutil.rmtree(SIDECAR_ROOT)
    SIDECAR_LIB.mkdir(parents=True, exist_ok=True)

    _copy_file(HB_MPV_BIN.resolve(), SIDECAR_BIN)

    deps = _collect_dependencies([HB_MPV_BIN, HB_LIBMPV])
    copied_dylibs: list[Path] = []

    for name, src in sorted(deps.items()):
        dst = SIDECAR_LIB / name
        _copy_file(src, dst)
        copied_dylibs.append(dst)

    _ensure_libmpv_symlink()
    _ensure_permissions(copied_dylibs, mode=0o644)
    _ensure_permissions([SIDECAR_BIN], mode=0o755)

    print("Rewriting dylib install names...")
    _rewrite_links(SIDECAR_BIN, copied_dylibs)

    # Ad-hoc sign so macOS will load them and Tauri bundler can process them
    print("Ad-hoc signing dylibs...")
    sign_targets = list(SIDECAR_LIB.glob("*.dylib"))
    _codesign_adhoc(sign_targets)
    _codesign_adhoc([SIDECAR_BIN])

    # Create Tauri sidecar binary
    print("Preparing Tauri sidecar binary...")
    _prepare_tauri_sidecar(copied_dylibs)

    print(f"Copied {len(copied_dylibs)} dylibs from Homebrew to {SIDECAR_LIB}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Prepare bundled mpv sidecar for Warp MediaCenter."
    )
    parser.add_argument(
        "--from-zip",
        metavar="PATH",
        help="Path to an official mpv GitHub release zip "
             "(e.g. mpv-v0.41.0-macos-26-arm.zip). "
             "Skips the Homebrew CDN download entirely.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-prepare even if the sidecar already looks ready.",
    )
    args = parser.parse_args()

    if not args.force and _is_sidecar_ready():
        print(f"Sidecar already prepared at {SIDECAR_LIB} — skipping.")
        print("  (Use --force to re-prepare.)")
        return 0

    # --- Path 0: explicit zip supplied via --from-zip ---
    if args.from_zip:
        zip_path = Path(args.from_zip).expanduser().resolve()
        _prepare_from_official_release(zip_path)
        return 0

    # --- Path 1: auto-detect an official release zip in common locations ---
    search_dirs = [ROOT, ROOT.parent, Path.home() / "Downloads"]
    for search_dir in search_dirs:
        if not search_dir.exists():
            continue
        candidates = sorted(search_dir.glob("mpv-*-macos*arm*.zip"))
        if candidates:
            zip_path = candidates[-1]   # newest (sorted by name)
            print(f"Auto-detected release zip: {zip_path}")
            _prepare_from_official_release(zip_path)
            return 0

    # --- Path 2: download Homebrew bottles directly (no brew required) ---
    try:
        _download_mpv_sidecar()
        return 0
    except Exception as exc:
        print(f"[warn] Direct download failed: {exc}", file=sys.stderr)
        print("Trying local Homebrew fallback...", file=sys.stderr)

    # --- Path 3: copy from local Homebrew installation ---
    if _homebrew_mpv_available():
        _copy_from_homebrew()
        return 0

    print(
        "ERROR: Cannot find or download mpv.\n"
        "  Option A: python3 scripts/prepare_tauri_mpv_sidecar.py "
        "--from-zip ~/Downloads/mpv-v0.41.0-macos-26-arm.zip\n"
        "  Option B: brew install mpv\n"
        "  Option C: ensure network access for Homebrew CDN download.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
