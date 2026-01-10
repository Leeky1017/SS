from __future__ import annotations

import logging
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import PurePosixPath

from src.domain.do_template_rendering import render_do_text, template_param_specs
from src.domain.do_template_repository import DoTemplateRepository
from src.domain.models import ArtifactKind, LLMPlan, PlanStep, PlanStepType, is_safe_job_rel_path
from src.infra.exceptions import (
    DoFileInputsManifestInvalidError,
    DoFilePlanInvalidError,
    DoFileTemplateUnsupportedError,
    DoTemplateNotFoundError,
)

logger = logging.getLogger(__name__)

DEFAULT_SUMMARY_TABLE_FILENAME = "ss_summary_table.csv"


@dataclass(frozen=True)
class ExpectedOutput:
    kind: ArtifactKind
    filename: str


@dataclass(frozen=True)
class GeneratedDoFile:
    do_file: str
    expected_outputs: tuple[ExpectedOutput, ...]


def _stata_quote(value: str) -> str:
    escaped = value.replace('"', '""')
    return f'"{escaped}"'


def _extract_generate_step(plan: LLMPlan) -> PlanStep:
    for step in plan.steps:
        if step.type == PlanStepType.GENERATE_STATA_DO:
            return step
    raise DoFilePlanInvalidError(reason="missing_generate_step")


def _extract_template(step: PlanStep) -> str:
    template_id = step.params.get("template_id", "")
    if isinstance(template_id, str) and template_id.strip() != "":
        return template_id
    legacy_template = step.params.get("template", "")
    if isinstance(legacy_template, str) and legacy_template.strip() != "":
        return legacy_template
    raise DoFilePlanInvalidError(reason="missing_template_id")


def _extract_template_params(step: PlanStep) -> dict[str, str]:
    raw = step.params.get("template_params", {})
    if raw is None:
        return {}
    if not isinstance(raw, Mapping):
        raise DoFilePlanInvalidError(reason="template_params_invalid")
    params: dict[str, str] = {}
    for key_obj, value_obj in raw.items():
        key = key_obj if isinstance(key_obj, str) else ""
        if key.strip() == "":
            continue
        if not isinstance(value_obj, str):
            raise DoFilePlanInvalidError(reason="template_params_value_not_string")
        params[key] = value_obj
    return params


def _infer_dataset_format_from_rel_path(rel_path: str) -> str | None:
    ext = PurePosixPath(rel_path).suffix.lower()
    if ext == ".csv":
        return "csv"
    if ext in {".xls", ".xlsx"}:
        return "excel"
    if ext == ".dta":
        return "dta"
    return None


def _normalize_dataset_format(*, raw: object, rel_path: str) -> str:
    if isinstance(raw, str):
        candidate = raw.strip().lower()
        if candidate in {"csv", "excel", "dta"}:
            return candidate
    inferred = _infer_dataset_format_from_rel_path(rel_path)
    if inferred is not None:
        return inferred
    raise DoFileInputsManifestInvalidError(reason="primary_dataset_format_missing")


def _extract_primary_dataset_info(inputs_manifest: Mapping[str, object]) -> tuple[str, str]:
    rel_path: object = ""
    fmt: object = ""
    datasets = inputs_manifest.get("datasets")
    if isinstance(datasets, list):
        for item in datasets:
            if not isinstance(item, Mapping):
                continue
            if item.get("role") != "primary_dataset":
                continue
            rel_path = item.get("rel_path", "")
            fmt = item.get("format", "")
            break
    else:
        dataset = inputs_manifest.get("primary_dataset")
        if isinstance(dataset, Mapping):
            rel_path = dataset.get("rel_path", "")
            fmt = dataset.get("format", "")
        else:
            rel_path = inputs_manifest.get("primary_dataset_rel_path", "")
            fmt = inputs_manifest.get("primary_dataset_format", "")

    if not isinstance(rel_path, str):
        raise DoFileInputsManifestInvalidError(reason="primary_dataset_rel_path_not_string")
    if rel_path.strip() == "":
        raise DoFileInputsManifestInvalidError(reason="primary_dataset_rel_path_missing")
    if not is_safe_job_rel_path(rel_path):
        raise DoFileInputsManifestInvalidError(reason="primary_dataset_rel_path_unsafe")
    return rel_path, _normalize_dataset_format(raw=fmt, rel_path=rel_path)


def _extract_analysis_vars(step: PlanStep) -> list[str]:
    raw = step.params.get("analysis_spec")
    if not isinstance(raw, Mapping):
        return []
    values: list[str] = []
    for key in ("outcome_var", "treatment_var"):
        item = raw.get(key)
        if isinstance(item, str) and item.strip() != "":
            values.append(item)
    controls = raw.get("controls")
    if isinstance(controls, list):
        for item in controls:
            if isinstance(item, str) and item.strip() != "":
                values.append(item)
    return values


def _dataset_load_line(*, dataset_format: str, dataset_job_rel_path: str) -> str:
    if dataset_format == "csv":
        return f"import delimited using {_stata_quote(dataset_job_rel_path)}, clear varnames(1)"
    if dataset_format == "excel":
        return f"import excel {_stata_quote(dataset_job_rel_path)}, firstrow clear"
    return f"use {_stata_quote(dataset_job_rel_path)}, clear"


def _stage_primary_dataset_as_library_inputs(
    *,
    dataset_job_rel_path: str,
    dataset_format: str,
) -> str:
    quoted_src = _stata_quote(dataset_job_rel_path)
    lines = [
        "* SS_DO_LIBRARY_INPUTS_STAGE (generated)",
        f"capture confirm file {quoted_src}",
        "if _rc {",
        f"    display as error \"ERROR: primary dataset not found: {dataset_job_rel_path}\"",
        "    exit 601",
        "}",
    ]
    if dataset_format == "csv":
        lines.append(f"copy {quoted_src} \"data.csv\", replace")
    elif dataset_format == "dta":
        lines.append(f"copy {quoted_src} \"data.dta\", replace")
    else:
        lines.extend(
            [
                f"import excel {quoted_src}, firstrow clear",
                "save \"data.dta\", replace",
            ]
        )
    lines.append("")
    return "\n".join(lines)


def _render_stub_descriptive_v1(
    *,
    plan_id: str,
    dataset_job_rel_path: str,
    dataset_format: str,
    analysis_vars: list[str],
) -> str:
    dataset_from_work_dir = dataset_job_rel_path
    analysis_comment = ""
    if len(analysis_vars) > 0:
        analysis_comment = "* analysis_vars: " + " ".join(analysis_vars)
    summary_line = "quietly summarize"
    if len(analysis_vars) > 0:
        summary_line = f"quietly summarize {' '.join(analysis_vars)}"
    lines = [
        "version 17",
        "clear all",
        "set more off",
        "",
        "* Generated by SS DoFileGenerator (deterministic).",
        f"* plan_id: {plan_id}",
        "* template: stub_descriptive_v1",
        analysis_comment,
        "",
        _dataset_load_line(
            dataset_format=dataset_format,
            dataset_job_rel_path=dataset_from_work_dir,
        ),
        "",
        "quietly describe",
        "local ss_k = r(k)",
        summary_line,
        "local ss_N = r(N)",
        "",
        "clear",
        "set obs 2",
        'generate str16 metric = ""',
        "generate double value = .",
        'replace metric = "N" in 1',
        "replace value = `ss_N' in 1",
        'replace metric = "k" in 2',
        "replace value = `ss_k' in 2",
        f"export delimited using {_stata_quote(DEFAULT_SUMMARY_TABLE_FILENAME)}, replace",
        "",
        "exit, clear",
        "",
    ]
    return "\n".join(lines)


@dataclass(frozen=True)
class DoFileGenerator:
    do_template_repo: DoTemplateRepository | None = None

    def generate(self, *, plan: LLMPlan, inputs_manifest: Mapping[str, object]) -> GeneratedDoFile:
        logger.info("SS_DOFILE_GENERATE_START", extra={"plan_id": plan.plan_id})
        step = _extract_generate_step(plan)
        template = _extract_template(step)
        dataset_rel_path, dataset_format = _extract_primary_dataset_info(inputs_manifest)
        analysis_vars = _extract_analysis_vars(step)
        outputs: tuple[ExpectedOutput, ...]

        if template == "stub_descriptive_v1":
            do_file = _render_stub_descriptive_v1(
                plan_id=plan.plan_id,
                dataset_job_rel_path=dataset_rel_path,
                dataset_format=dataset_format,
                analysis_vars=analysis_vars,
            )
            outputs = (
                ExpectedOutput(
                    kind=ArtifactKind.STATA_EXPORT_TABLE,
                    filename=DEFAULT_SUMMARY_TABLE_FILENAME,
                ),
            )
        else:
            repo = self.do_template_repo
            if repo is None:
                raise DoFileTemplateUnsupportedError(template=template)
            params = _extract_template_params(step)
            try:
                tpl = repo.get_template(template_id=template)
            except DoTemplateNotFoundError as e:
                raise DoFileTemplateUnsupportedError(template=template) from e
            specs = template_param_specs(template_id=template, meta=tpl.meta)
            rendered, _resolved = render_do_text(
                template_id=template,
                do_text=tpl.do_text,
                specs=specs,
                params=params,
            )
            staged = _stage_primary_dataset_as_library_inputs(
                dataset_job_rel_path=dataset_rel_path,
                dataset_format=dataset_format,
            )
            do_file = staged + "\n" + rendered
            outputs = ()
        logger.info(
            "SS_DOFILE_GENERATE_DONE",
            extra={"plan_id": plan.plan_id, "template": template, "outputs": len(outputs)},
        )
        return GeneratedDoFile(do_file=do_file, expected_outputs=outputs)
