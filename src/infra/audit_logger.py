from __future__ import annotations

import logging
from dataclasses import dataclass

from src.domain.audit import AuditEvent, AuditLogger

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class LoggingAuditLogger(AuditLogger):
    def emit(self, *, event: AuditEvent) -> None:
        logger.info("SS_AUDIT_EVENT", extra=event.to_log_extra())

