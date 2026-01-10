from __future__ import annotations

from collections.abc import Mapping
from typing import cast

from src.domain.do_template_catalog import DoTemplateCatalog
from src.domain.do_template_repository import DoTemplateRepository
from src.infra.exceptions import DoTemplateIndexCorruptedError
from src.utils.json_types import JsonObject


def analysis_vars_from_analysis_spec(analysis_spec: Mapping[str, object]) -> list[str]:
    values: list[str] = []
    for key in ("outcome_var", "treatment_var"):
        item = analysis_spec.get(key, "")
        if isinstance(item, str) and item.strip() != "":
            values.append(item.strip())
    controls = analysis_spec.get("controls", [])
    if isinstance(controls, list):
        for item in controls:
            if isinstance(item, str) and item.strip() != "":
                values.append(item.strip())
    return values


def template_params_for(*, template_id: str, analysis_vars: list[str]) -> JsonObject:
    joined = " ".join(analysis_vars)
    if template_id == "T01":
        return cast(JsonObject, {"__NUMERIC_VARS__": joined, "__ID_VAR__": "", "__TIME_VAR__": ""})
    if template_id == "TA14":
        return cast(
            JsonObject,
            {"__CHECK_VARS__": joined, "__ID_VAR__": "", "__QUALITY_THRESHOLD__": "0.8"},
        )
    return cast(JsonObject, {})


def select_template_id(
    *,
    catalog: DoTemplateCatalog,
    repo: DoTemplateRepository,
    analysis_vars: list[str],
) -> str:
    families = catalog.list_families()
    family_ids = tuple(f.family_id for f in families if f.family_id.strip() != "")
    _ = catalog.list_templates(family_ids=family_ids)

    available = set(repo.list_template_ids())
    if analysis_vars and "T01" in available:
        return "T01"
    if "TA14" in available:
        return "TA14"
    if available:
        return sorted(available)[0]
    raise DoTemplateIndexCorruptedError(reason="index.no_tasks")

