from __future__ import annotations

import json
import logging
import sys
import time
from typing import Any, Mapping, MutableMapping, Optional


_LEVELS = {
    "CRITICAL": logging.CRITICAL,
    "ERROR": logging.ERROR,
    "WARNING": logging.WARNING,
    "INFO": logging.INFO,
    "DEBUG": logging.DEBUG,
}


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: MutableMapping[str, Any] = {
            "ts": int(time.time() * 1000),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
        }

        if record.exc_info:
            payload["exc_info"] = self.formatException(record.exc_info)
        
        for k, v in record.__dict__.items():
            if k not in ("args", "asctime", "created", "exc_info", "exc_text",
                         "filename", "funcName", "levelname", "levelno",
                         "lineno", "module", "msecs", "message", "msg",
                         "name", "pathname", "process", "processName",
                         "relativeCreated", "stack_info", "thread", "threadName"):
                payload[k] = v
        
        return json.dumps(payload, ensure_ascii=False)


class StructuredLogger(logging.Logger):
    """Logger that automatically wraps keyword arguments into `extra` for JSON formatting."""

    def _log_with_extra(self, level: int, msg: str, args: Any, **kwargs: Any) -> None:
        extra = kwargs.pop("extra", {}) or {}
        for k, v in kwargs.items():
            if k not in _LOG_RECORD_ATTRS:
                extra[k] = v
        kwargs.clear()
        kwargs["extra"] = extra
        super()._log(level, msg, args, **kwargs)

    def debug(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log_with_extra(logging.DEBUG, msg, args, **kwargs)

    def info(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log_with_extra(logging.INFO, msg, args, **kwargs)

    def warning(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log_with_extra(logging.WARNING, msg, args, **kwargs)

    def error(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log_with_extra(logging.ERROR, msg, args, **kwargs)

    def critical(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log_with_extra(logging.CRITICAL, msg, args, **kwargs)

    def exception(self, msg: str, *args: Any, **kwargs: Any) -> None:
        kwargs["exc_info"] = True
        self._log_with_extra(logging.ERROR, msg, args, **kwargs)


_LOG_RECORD_ATTRS = frozenset((
    "name", "msg", "args", "levelname", "levelno", "pathname", "filename",
    "module", "exc_info", "exc_text", "stack_info", "lineno", "funcName",
    "created", "relativeCreated", "msecs", "thread", "threadName",
    "process", "processName", "message", "taskName",
))


def _patch_logger_to_structured(logger: logging.Logger) -> None:
    """Patch an existing logger to use StructuredLogger methods."""
    if hasattr(logger, "_structured_patched"):
        return
    logger._structured_patched = True  # type: ignore

    original_log = logger._log

    def patched_log(level, msg, *args, **kwargs):
        extra = kwargs.pop("extra", {}) or {}
        for k, v in kwargs.items():
            if k not in _LOG_RECORD_ATTRS:
                extra[k] = v
        kwargs.clear()
        kwargs["extra"] = extra
        original_log(level, msg, *args, **kwargs)

    logger._log = patched_log


def init_logging(level: str = "INFO") -> None:
    # Register our custom logger class for future loggers
    logging.setLoggerClass(StructuredLogger)

    # Patch ALL existing loggers to use StructuredLogger methods
    root = logging.getLogger()
    _patch_logger_to_structured(root)
    for name in logging.root.manager.loggerDict:
        logger = logging.getLogger(name)
        if isinstance(logger, logging.Logger):
            _patch_logger_to_structured(logger)
    
    # Idempotent: clear existing handlers to avoid duplication
    for h in list(root.handlers):
        root.removeHandler(h)

    root.setLevel(_LEVELS.get(level.upper(), logging.INFO))
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root.addHandler(handler)

def get_logger(name: Optional[str] = None) -> StructuredLogger:
    logger = logging.getLogger(name if name else __name__)
    if not isinstance(logger, StructuredLogger):
        _patch_logger_to_structured(logger)
    return logger  # type: ignore[return-value]
