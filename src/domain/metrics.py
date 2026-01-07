from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


class RuntimeMetrics(Protocol):
    def record_job_created(self) -> None: ...

    def record_job_finished(self, *, status: str) -> None: ...

    def worker_inflight_inc(self, *, worker_id: str) -> None: ...

    def worker_inflight_dec(self, *, worker_id: str) -> None: ...

    def set_worker_up(self, *, worker_id: str, up: bool) -> None: ...


@dataclass(frozen=True)
class NoopMetrics(RuntimeMetrics):
    def record_job_created(self) -> None:
        return None

    def record_job_finished(self, *, status: str) -> None:
        return None

    def worker_inflight_inc(self, *, worker_id: str) -> None:
        return None

    def worker_inflight_dec(self, *, worker_id: str) -> None:
        return None

    def set_worker_up(self, *, worker_id: str, up: bool) -> None:
        return None

