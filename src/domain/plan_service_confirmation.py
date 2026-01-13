from __future__ import annotations

from src.domain.models import Job, JobConfirmation


def effective_confirmation(*, job: Job, confirmation: JobConfirmation) -> JobConfirmation:
    updates: dict[str, object] = {}
    if confirmation.requirement is None:
        updates["requirement"] = job.requirement

    existing = job.confirmation
    if existing is not None:
        if confirmation.notes is None and existing.notes is not None:
            updates["notes"] = existing.notes

        missing_answers = len(confirmation.answers) == 0
        existing_answers = len(existing.answers) > 0
        if missing_answers and existing_answers:
            updates["answers"] = dict(existing.answers)

        missing_corrections = len(confirmation.variable_corrections) == 0
        existing_corrections = len(existing.variable_corrections) > 0
        if missing_corrections and existing_corrections:
            updates["variable_corrections"] = dict(existing.variable_corrections)

        missing_overrides = len(confirmation.default_overrides) == 0
        existing_overrides = len(existing.default_overrides) > 0
        if missing_overrides and existing_overrides:
            updates["default_overrides"] = dict(existing.default_overrides)

        missing_feedback = len(confirmation.expert_suggestions_feedback) == 0
        existing_feedback = len(existing.expert_suggestions_feedback) > 0
        if missing_feedback and existing_feedback:
            updates["expert_suggestions_feedback"] = dict(existing.expert_suggestions_feedback)

    if len(updates) == 0:
        return confirmation
    return confirmation.model_copy(update=updates)

