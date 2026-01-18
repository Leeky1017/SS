from __future__ import annotations

import logging
from collections.abc import Mapping

from src.domain import do_template_plan_support
from src.domain.do_template_repository import DoTemplateRepository
from src.domain.models import Job, JobConfirmation
from src.domain.plan_contract_extract import missing_required_template_params
from src.domain.plan_freeze_gate import (
    missing_draft_fields_for_plan_freeze,
    next_actions_for_plan_freeze_missing,
)
from src.domain.plan_freeze_missing_required_details import (
    action_message_for_plan_freeze_missing,
    missing_fields_detail_for_plan_freeze,
    missing_params_detail_for_plan_freeze,
)
from src.domain.plan_template_contract_builder import build_plan_template_contract
from src.infra.plan_exceptions import PlanFreezeMissingRequiredError

logger = logging.getLogger(__name__)


def _missing_params_and_template_meta(
    *,
    job: Job,
    confirmation: JobConfirmation,
    template_id: str,
    analysis_spec: Mapping[str, object],
    do_template_repo: DoTemplateRepository,
) -> tuple[list[str], Mapping[str, object]]:
    template_params = do_template_plan_support.template_params_for(
        template_id=template_id,
        analysis_spec=analysis_spec,
        variable_corrections=confirmation.variable_corrections,
    )
    template_contract = build_plan_template_contract(
        repo=do_template_repo,
        job_id=job.job_id,
        template_id=template_id,
        template_params=template_params,
    )
    missing_params = missing_required_template_params(template_contract=template_contract)
    template_meta = do_template_repo.get_template(template_id=template_id).meta
    return missing_params, template_meta


def _missing_required_details(
    *,
    job: Job,
    missing_fields: list[str],
    missing_params: list[str],
    template_meta: Mapping[str, object],
) -> tuple[list[dict[str, object]], list[dict[str, object]], str, list[dict[str, object]]]:
    missing_fields_detail = missing_fields_detail_for_plan_freeze(
        draft=job.draft, missing_fields=missing_fields
    )
    missing_params_detail = missing_params_detail_for_plan_freeze(
        draft=job.draft, missing_params=missing_params, template_meta=template_meta
    )
    action = action_message_for_plan_freeze_missing(
        missing_fields=missing_fields, missing_params=missing_params
    )
    next_actions = next_actions_for_plan_freeze_missing(
        job_id=job.job_id, missing_fields=missing_fields, missing_params=missing_params
    )
    return missing_fields_detail, missing_params_detail, action, next_actions


def ensure_plan_freeze_required_inputs_present(
    *,
    job: Job,
    confirmation: JobConfirmation,
    template_id: str,
    analysis_spec: Mapping[str, object],
    do_template_repo: DoTemplateRepository,
) -> None:
    missing_fields = missing_draft_fields_for_plan_freeze(
        draft=job.draft, answers=confirmation.answers
    )
    missing_params, template_meta = _missing_params_and_template_meta(
        job=job,
        confirmation=confirmation,
        template_id=template_id,
        analysis_spec=analysis_spec,
        do_template_repo=do_template_repo,
    )
    if len(missing_fields) == 0 and len(missing_params) == 0:
        return

    missing_fields_detail, missing_params_detail, action, next_actions = _missing_required_details(
        job=job,
        missing_fields=missing_fields,
        missing_params=missing_params,
        template_meta=template_meta,
    )
    logger.info(
        "SS_PLAN_FREEZE_MISSING_REQUIRED",
        extra={
            "job_id": job.job_id,
            "template_id": template_id,
            "missing_fields": ",".join(missing_fields),
            "missing_params": ",".join(missing_params),
        },
    )
    raise PlanFreezeMissingRequiredError(
        job_id=job.job_id,
        template_id=template_id,
        missing_fields=missing_fields,
        missing_fields_detail=missing_fields_detail,
        missing_params=missing_params,
        missing_params_detail=missing_params_detail,
        next_actions=next_actions,
        action=action,
    )
