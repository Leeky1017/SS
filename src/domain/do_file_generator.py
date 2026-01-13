from __future__ import annotations

import logging
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import PurePosixPath

from src.domain.do_template_rendering import render_do_text, template_param_specs
from src.domain.do_template_repository import DoTemplateRepository
from src.domain.do_template_run_support import declared_outputs, output_filename, output_kind
from src.domain.models import ArtifactKind, LLMPlan, PlanStep, PlanStepType, is_safe_job_rel_path
from src.infra.exceptions import (
    DoFileInputsManifestInvalidError,
    DoFilePlanInvalidError,
    DoFileTemplateUnsupportedError,
    DoTemplateNotFoundError,
)
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class ExpectedOutput:
    kind: ArtifactKind
    filename: str


@dataclass(frozen=True)
class PreparedDoTemplate:
    template_id: str
    raw_do: str
    meta: JsonObject
    params: dict[str, str]
    dataset_job_rel_path: str
    dataset_format: str
    dataset_sheet_name: str | None
    dataset_header_row: bool | None


@dataclass(frozen=True)
class GeneratedDoFile:
    template_id: str
    do_file: str
    template_source: str
    template_meta: JsonObject
    template_params: dict[str, str]
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


def _sheet_name_or_none(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    candidate = value.strip()
    return None if candidate == "" else candidate


def _header_row_or_none(value: object) -> bool | None:
    if isinstance(value, bool):
        return value
    return None


def _extract_primary_dataset_info(
    inputs_manifest: Mapping[str, object],
) -> tuple[str, str, str | None, bool | None]:
    rel_path: object = ""
    fmt: object = ""
    sheet_name: str | None = None
    header_row: bool | None = None
    datasets = inputs_manifest.get("datasets")
    if isinstance(datasets, list):
        for item in datasets:
            if not isinstance(item, Mapping):
                continue
            if item.get("role") != "primary_dataset":
                continue
            rel_path = item.get("rel_path", "")
            fmt = item.get("format", "")
            sheet_name = _sheet_name_or_none(item.get("sheet_name"))
            header_row = _header_row_or_none(item.get("header_row"))
            break
    else:
        dataset = inputs_manifest.get("primary_dataset")
        if isinstance(dataset, Mapping):
            rel_path = dataset.get("rel_path", "")
            fmt = dataset.get("format", "")
            sheet_name = _sheet_name_or_none(dataset.get("sheet_name"))
            header_row = _header_row_or_none(dataset.get("header_row"))
        else:
            rel_path = inputs_manifest.get("primary_dataset_rel_path", "")
            fmt = inputs_manifest.get("primary_dataset_format", "")
            sheet_name = _sheet_name_or_none(inputs_manifest.get("primary_dataset_sheet_name"))
            header_row = _header_row_or_none(inputs_manifest.get("primary_dataset_header_row"))

    if not isinstance(rel_path, str):
        raise DoFileInputsManifestInvalidError(reason="primary_dataset_rel_path_not_string")
    if rel_path.strip() == "":
        raise DoFileInputsManifestInvalidError(reason="primary_dataset_rel_path_missing")
    if not is_safe_job_rel_path(rel_path):
        raise DoFileInputsManifestInvalidError(reason="primary_dataset_rel_path_unsafe")
    return rel_path, _normalize_dataset_format(raw=fmt, rel_path=rel_path), sheet_name, header_row

def _stage_primary_dataset_as_library_inputs(
    *,
    dataset_job_rel_path: str,
    dataset_format: str,
    dataset_sheet_name: str | None,
    dataset_header_row: bool | None,
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
        sheet_opt = (
            None
            if dataset_sheet_name is None
            else f"sheet({_stata_quote(dataset_sheet_name)})"
        )
        options = []
        if sheet_opt is not None:
            options.append(sheet_opt)
        if dataset_header_row is not False:
            options.append("firstrow")
        options.append("clear")
        lines.extend(
            [
                f"import excel {quoted_src}, {' '.join(options)}",
                "save \"data.dta\", replace",
            ]
        )
    lines.append("")
    return "\n".join(lines)


def _expected_outputs_from_meta(
    *, template_id: str, meta: JsonObject
) -> tuple[ExpectedOutput, ...]:
    outputs: list[ExpectedOutput] = []
    for output in declared_outputs(template_id=template_id, meta=meta):
        filename = output_filename(template_id=template_id, output=output)
        outputs.append(ExpectedOutput(kind=output_kind(output), filename=filename))
    outputs.sort(key=lambda item: (item.kind.value, item.filename))
    return tuple(outputs)


@dataclass(frozen=True)
class DoFileGenerator:
    do_template_repo: DoTemplateRepository | None = None

    def prepare(
        self, *, plan: LLMPlan, inputs_manifest: Mapping[str, object]
    ) -> PreparedDoTemplate:
        step = _extract_generate_step(plan)
        template_id = _extract_template(step)
        dataset_rel_path, dataset_format, dataset_sheet_name, dataset_header_row = (
            _extract_primary_dataset_info(inputs_manifest)
        )
        params = _extract_template_params(step)

        repo = self.do_template_repo
        if repo is None:
            raise DoFileTemplateUnsupportedError(template=template_id)
        try:
            tpl = repo.get_template(template_id=template_id)
        except DoTemplateNotFoundError as e:
            raise DoFileTemplateUnsupportedError(template=template_id) from e
        return PreparedDoTemplate(
            template_id=template_id,
            raw_do=tpl.do_text,
            meta=tpl.meta,
            params=params,
            dataset_job_rel_path=dataset_rel_path,
            dataset_format=dataset_format,
            dataset_sheet_name=dataset_sheet_name,
            dataset_header_row=dataset_header_row,
        )

    def generate_from_prepared(self, *, prepared: PreparedDoTemplate) -> GeneratedDoFile:
        specs = template_param_specs(template_id=prepared.template_id, meta=prepared.meta)
        rendered, resolved = render_do_text(
            template_id=prepared.template_id,
            do_text=prepared.raw_do,
            specs=specs,
            params=prepared.params,
        )
        staged = _stage_primary_dataset_as_library_inputs(
            dataset_job_rel_path=prepared.dataset_job_rel_path,
            dataset_format=prepared.dataset_format,
            dataset_sheet_name=prepared.dataset_sheet_name,
            dataset_header_row=prepared.dataset_header_row,
        )
        outputs = _expected_outputs_from_meta(template_id=prepared.template_id, meta=prepared.meta)
        return GeneratedDoFile(
            template_id=prepared.template_id,
            do_file=staged + "\n" + rendered,
            template_source=prepared.raw_do,
            template_meta=prepared.meta,
            template_params=resolved,
            expected_outputs=outputs,
        )

    def generate(self, *, plan: LLMPlan, inputs_manifest: Mapping[str, object]) -> GeneratedDoFile:
        logger.info("SS_DOFILE_GENERATE_START", extra={"plan_id": plan.plan_id})
        prepared = self.prepare(plan=plan, inputs_manifest=inputs_manifest)
        generated = self.generate_from_prepared(prepared=prepared)
        logger.info(
            "SS_DOFILE_GENERATE_DONE",
            extra={
                "plan_id": plan.plan_id,
                "template_id": generated.template_id,
                "outputs": len(generated.expected_outputs),
            },
        )
        return generated
