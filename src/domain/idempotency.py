from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass


def _normalize_whitespace(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


@dataclass(frozen=True)
class JobIdempotency:
    version: str = "v1"

    def compute_key(
        self,
        *,
        inputs_fingerprint: str | None,
        requirement: str | None,
        plan_revision: str | int | None,
    ) -> str:
        fingerprint = inputs_fingerprint if inputs_fingerprint is not None else ""
        req = requirement if requirement is not None else ""
        rev = str(plan_revision) if plan_revision is not None else ""
        requirement_norm = _normalize_whitespace(req)
        canonical = (
            f"{self.version}|fingerprint={fingerprint}|requirement={requirement_norm}|plan_revision={rev}"
        )
        return hashlib.sha256(canonical.encode("utf-8")).hexdigest()

    def derive_job_id(self, *, idempotency_key: str) -> str:
        return f"job_{idempotency_key[:16]}"
