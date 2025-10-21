"""Shared helpers for the Warp MediaCenter CLI modules."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, is_dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, MutableMapping


def build_subparser(parent: argparse._SubParsersAction, name: str, **kwargs: Any) -> argparse.ArgumentParser:
    """Create a sub-parser with ``required=True`` semantics on modern Python versions."""

    parser = parent.add_parser(name, **kwargs)
    return parser


def require_subcommand(subparsers: argparse._SubParsersAction) -> None:
    """Force argparse to require that a sub-command is provided."""

    try:
        subparsers.required = True  # type: ignore[attr-defined]
    except Exception:
        pass


def print_json(payload: Any) -> None:
    """Render a Python object as formatted JSON to stdout."""

    print(json.dumps(payload, indent=2, sort_keys=True, ensure_ascii=False))


def to_serializable(value: Any) -> Any:
    """Best-effort conversion for complex objects into JSON-friendly structures."""

    if value is None:
        return None
    if isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, Mapping):
        return {str(k): to_serializable(v) for k, v in value.items()}
    if isinstance(value, (list, tuple, set)):
        return [to_serializable(item) for item in value]
    if hasattr(value, "model_dump"):
        try:
            return to_serializable(value.model_dump())  # type: ignore[call-arg]
        except Exception:
            pass
    if is_dataclass(value):
        try:
            return to_serializable(asdict(value))
        except Exception:
            pass
    if hasattr(value, "as_dict"):
        try:
            return to_serializable(value.as_dict())
        except Exception:
            pass
    if hasattr(value, "__dict__"):
        return to_serializable(vars(value))
    return str(value)


def parse_key_value_pairs(pairs: Iterable[str]) -> MutableMapping[str, str]:
    """Parse ``key=value`` strings into a mapping."""

    data: MutableMapping[str, str] = {}
    for pair in pairs:
        if "=" not in pair:
            raise argparse.ArgumentTypeError(f"Expected KEY=VALUE syntax, got '{pair}'")
        key, value = pair.split("=", 1)
        data[key.strip()] = value.strip()
    return data


def exit_with_error(message: str, *, code: int = 1) -> None:
    """Emit a message to stderr and exit."""

    sys.stderr.write(f"Error: {message}\n")
    raise SystemExit(code)
