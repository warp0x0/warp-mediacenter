from typing import TypedDict, Literal, Optional
from pydantic import BaseModel, Field
from __future__ import annotations



LogLevel = Literal["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"]


class HealthReport(TypedDict):
    status: Literal["ok", "degraded", "fail"]
    components: dict[str, Literal["ok", "degraded", "fail"]]


class HttpResult(BaseModel):
    url: str
    status_code: int
    ok: bool
    elapsed_ms: int = Field(ge=0)
    error: Optional[str] = None
