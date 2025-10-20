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


def init_logging(level: str = "INFO") -> None:
    root = logging.getLogger()
    
    # Idempotent: clear existing handlers to avoid duplication
    for h in list(root.handlers):
        root.removeHandler(h)

    root.setLevel(_LEVELS.get(level.upper(), logging.INFO))
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root.addHandler(handler)

def get_logger(name: Optional[str] = None) -> logging.Logger:
    return logging.getLogger(name if name else __name__)
