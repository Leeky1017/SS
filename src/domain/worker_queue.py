from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Protocol


@dataclass(frozen=True)
class QueueClaim:
    job_id: str
    claim_id: str
    worker_id: str
    claimed_at: datetime
    lease_expires_at: datetime


class WorkerQueue(Protocol):
    def enqueue(self, *, job_id: str) -> None: ...

    def claim(self, *, worker_id: str) -> QueueClaim | None: ...

    def ack(self, *, claim: QueueClaim) -> None: ...

    def release(self, *, claim: QueueClaim) -> None: ...

