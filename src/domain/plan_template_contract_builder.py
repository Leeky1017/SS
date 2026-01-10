from __future__ import annotations

import logging

from src.domain.do_template_repository import DoTemplateRepository
from src.domain.plan_freeze_contract import build_plan_freeze_contract
from src.infra.exceptions import (
    DoTemplateContractInvalidError,
    DoTemplateIndexCorruptedError,
    DoTemplateMetaNotFoundError,
)
from src.infra.plan_exceptions import PlanTemplateMetaInvalidError, PlanTemplateMetaNotFoundError
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


def build_plan_template_contract(
    *,
    repo: DoTemplateRepository,
    job_id: str,
    template_id: str,
    template_params: JsonObject,
) -> JsonObject:
    try:
        tpl = repo.get_template(template_id=template_id)
        bound_values = {k: v for k, v in template_params.items() if isinstance(v, str)}
        return build_plan_freeze_contract(
            template_id=template_id,
            meta=tpl.meta,
            bound_values=bound_values,
        )
    except DoTemplateMetaNotFoundError as e:
        logger.warning(
            "SS_PLAN_TEMPLATE_META_NOT_FOUND",
            extra={"job_id": job_id, "template_id": template_id, "error_code": e.error_code},
        )
        raise PlanTemplateMetaNotFoundError(job_id=job_id, template_id=template_id) from e
    except (DoTemplateIndexCorruptedError, DoTemplateContractInvalidError) as e:
        logger.warning(
            "SS_PLAN_TEMPLATE_META_INVALID",
            extra={
                "job_id": job_id,
                "template_id": template_id,
                "error_code": e.error_code,
                "error_message": e.message,
            },
        )
        raise PlanTemplateMetaInvalidError(
            job_id=job_id,
            template_id=template_id,
            reason=e.error_code,
        ) from e

