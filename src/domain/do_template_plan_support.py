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


def _selected_var(corrections: Mapping[str, str] | None, key: str) -> str:
    if corrections is None:
        return ""
    value = corrections.get(key, "")
    candidate = value.strip()
    return "" if candidate == "" else candidate


def _analysis_dep_and_indep(analysis_spec: Mapping[str, object]) -> tuple[str, str]:
    depvar = analysis_spec.get("outcome_var", "")
    dep = depvar.strip() if isinstance(depvar, str) else ""
    indep_parts: list[str] = []
    treat = analysis_spec.get("treatment_var", "")
    if isinstance(treat, str) and treat.strip() != "":
        indep_parts.append(treat.strip())
    controls = analysis_spec.get("controls", [])
    if isinstance(controls, list):
        for item in controls:
            if isinstance(item, str) and item.strip() != "":
                indep_parts.append(item.strip())
    return dep, " ".join(indep_parts)


def _selected_panel_vars(
    variable_corrections: Mapping[str, str] | None,
) -> tuple[str, str, str]:
    id_var = _selected_var(variable_corrections, "__ID_VAR__")
    if id_var == "":
        id_var = _selected_var(variable_corrections, "__PANELVAR__")
    time_var = _selected_var(variable_corrections, "__TIME_VAR__")
    cluster_var = _selected_var(variable_corrections, "__CLUSTER_VAR__")
    return id_var, time_var, cluster_var


def template_params_for(
    *,
    template_id: str,
    analysis_spec: Mapping[str, object],
    variable_corrections: Mapping[str, str] | None = None,
) -> JsonObject:
    joined = " ".join(analysis_vars_from_analysis_spec(analysis_spec))
    dep, indep = _analysis_dep_and_indep(analysis_spec)
    id_var, time_var, cluster_var = _selected_panel_vars(variable_corrections)

    if template_id == "T01":
        return cast(
            JsonObject,
            {"__NUMERIC_VARS__": joined, "__ID_VAR__": id_var, "__TIME_VAR__": time_var},
        )
    if template_id == "T07":
        return cast(JsonObject, {"__NUMERIC_VARS__": joined})
    if template_id == "TA14":
        return cast(
            JsonObject,
            {"__CHECK_VARS__": joined, "__ID_VAR__": id_var, "__QUALITY_THRESHOLD__": "0.8"},
        )
    if template_id == "T30":
        return cast(JsonObject, {"__ID_VAR__": id_var, "__TIME_VAR__": time_var})
    if template_id == "T31":
        cluster = (
            cluster_var
            if cluster_var != ""
            else (id_var if id_var != "" else "__ID_VAR__")
        )
        return cast(
            JsonObject,
            {
                "__DEPVAR__": dep,
                "__INDEPVARS__": indep,
                "__ID_VAR__": id_var,
                "__PANELVAR__": id_var,
                "__TIME_VAR__": time_var,
                "__CLUSTER_VAR__": cluster,
            },
        )
    return cast(
        JsonObject,
        {
            "__DEPVAR__": dep,
            "__INDEPVARS__": indep,
            "__ID_VAR__": id_var,
            "__PANELVAR__": id_var,
            "__TIME_VAR__": time_var,
            "__CLUSTER_VAR__": cluster_var,
        },
    )


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
