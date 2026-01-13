from __future__ import annotations

import json
import re
from collections.abc import Mapping
from json import JSONDecodeError

from pydantic import BaseModel, ConfigDict, Field, ValidationError

from src.domain.models import LLMPlan, PlanStep, PlanStepType
from src.domain.plan_generation_models import PlanGenerationInput
from src.utils.job_workspace import is_safe_path_segment

_PLAN_GENERATION_SCHEMA_VERSION_V1 = 1
_JSON_BLOCK_RE = re.compile(r"```(?:json)?\\s*\\n?(.*?)\\n?```", re.DOTALL)


class PlanGenerationParseError(Exception):
    """Raised when plan generation LLM output cannot be parsed/validated."""

    def __init__(self, message: str, raw_text: str, *, error_code: str) -> None:
        super().__init__(message)
        self.error_code = error_code
        self.raw_text = raw_text


class _PlanGenerationResponseV1(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: int = Field(default=_PLAN_GENERATION_SCHEMA_VERSION_V1)
    steps: list[PlanStep] = Field(default_factory=list)


def _extract_json_from_markdown(text: str) -> str:
    match = _JSON_BLOCK_RE.search(text)
    if match is None:
        return text
    return match.group(1).strip()


def _json_dumps(value: object) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True)


def _truncate(text: str, *, max_chars: int) -> str:
    if max_chars <= 0:
        return ""
    value = text.strip()
    if len(value) <= max_chars:
        return value
    return value[: max_chars - 3] + "..."


def _schema_hint_json(*, allowed_types: list[str]) -> str:
    schema_hint = {
        "schema_version": _PLAN_GENERATION_SCHEMA_VERSION_V1,
        "steps": [
            {
                "step_id": "snake_case string",
                "type": f"one of: {', '.join(allowed_types)}",
                "purpose": "short purpose string",
                "depends_on": ["step_id", "..."],
                "fallback_step_id": "step_id|null",
                "params": {"template_id": "optional template id from SELECTED_TEMPLATES"},
            }
        ],
    }
    return _json_dumps(schema_hint)


def _data_schema_json(plan_input: PlanGenerationInput) -> str:
    data_schema = plan_input.data_schema
    return _json_dumps(
        {
            "columns": list(data_schema.columns[:50]),
            "n_rows": data_schema.n_rows,
            "has_panel_structure": bool(data_schema.has_panel_structure),
            "detected_vars": dict(data_schema.detected_vars),
        }
    )


def _prompt_rules() -> list[str]:
    return [
        "Rules:",
        "- Use safe step_id (snake_case, no spaces).",
        "- Use depends_on to express ordering; all references must exist.",
        "- If uncertain, prefer fewer steps but keep the logic sound.",
        "- Do not invent template ids outside SELECTED_TEMPLATES.",
    ]


def build_plan_generation_prompt(*, plan_input: PlanGenerationInput) -> str:
    requirement = plan_input.requirement.strip()
    constraints = plan_input.constraints
    draft_text = "" if plan_input.draft is None else plan_input.draft.text

    allowed_types = [t.value for t in PlanStepType]

    return "\n".join(
        [
            "You are a research methodology planner and Stata power user.",
            "Task: turn the requirement into a logical multi-step execution plan.",
            f"Constraint: steps <= {int(constraints.max_steps)}.",
            "Return ONLY a valid JSON object (no markdown, no extra text).",
            "",
            f"JOB_ID: {plan_input.job_id}",
            "",
            "REQUIREMENT:",
            requirement,
            "",
            "SELECTED_TEMPLATES (choose from these when setting params.template_id):",
            _json_dumps(plan_input.selected_templates),
            "",
            "DATA_SCHEMA:",
            _data_schema_json(plan_input),
            "",
            "DRAFT (may be partial; use only as context):",
            _truncate(draft_text, max_chars=800),
            "",
            "OUTPUT_SCHEMA:",
            _schema_hint_json(allowed_types=allowed_types),
            "",
            *_prompt_rules(),
        ]
    )


def _validated_step_type(value: object, *, raw_text: str) -> None:
    if not isinstance(value, str) or value.strip() == "":
        raise PlanGenerationParseError(
            "step.type must be a non-empty string",
            raw_text,
            error_code="PLAN_GEN_STEP_TYPE_INVALID",
        )
    allowed = {t.value for t in PlanStepType}
    if value not in allowed:
        raise PlanGenerationParseError(
            f"unsupported step type: {value}",
            raw_text,
            error_code="PLAN_GEN_UNSUPPORTED_STEP_TYPE",
        )


def _validate_template_id_if_present(
    *,
    step: PlanStep,
    selected_templates: list[str],
    raw_text: str,
) -> None:
    if len(selected_templates) == 0:
        return
    raw = step.params.get("template_id")
    if raw is None:
        return
    if not isinstance(raw, str) or raw.strip() == "":
        raise PlanGenerationParseError(
            "params.template_id must be a non-empty string when present",
            raw_text,
            error_code="PLAN_GEN_TEMPLATE_ID_INVALID",
        )
    if raw not in set(selected_templates):
        raise PlanGenerationParseError(
            f"params.template_id not in selected templates: {raw}",
            raw_text,
            error_code="PLAN_GEN_TEMPLATE_ID_UNSUPPORTED",
        )


def _parse_json_object(*, text: str) -> Mapping[str, object]:
    raw = text.strip()
    if "```" in raw:
        raw = _extract_json_from_markdown(raw)
    try:
        parsed = json.loads(raw)
    except JSONDecodeError as e:
        raise PlanGenerationParseError(
            f"Invalid JSON: {e}",
            raw_text=text,
            error_code="PLAN_GEN_JSON_INVALID",
        ) from e
    if not isinstance(parsed, Mapping):
        raise PlanGenerationParseError(
            "Response must be a JSON object",
            raw_text=text,
            error_code="PLAN_GEN_SCHEMA_INVALID",
        )
    return parsed


def _raw_steps_or_error(
    *,
    parsed: Mapping[str, object],
    raw_text: str,
) -> list[Mapping[str, object]]:
    steps = parsed.get("steps")
    if not isinstance(steps, list):
        raise PlanGenerationParseError(
            "Missing or invalid 'steps' field",
            raw_text=raw_text,
            error_code="PLAN_GEN_SCHEMA_INVALID",
        )
    out: list[Mapping[str, object]] = []
    for item in steps:
        if not isinstance(item, Mapping):
            raise PlanGenerationParseError(
                "each step must be an object",
                raw_text=raw_text,
                error_code="PLAN_GEN_SCHEMA_INVALID",
            )
        out.append(item)
    return out


def _validate_raw_steps(
    *,
    steps: list[Mapping[str, object]],
    max_steps: int,
    raw_text: str,
) -> None:
    if len(steps) == 0:
        raise PlanGenerationParseError(
            "steps must be non-empty",
            raw_text=raw_text,
            error_code="PLAN_GEN_EMPTY_STEPS",
        )
    if max_steps > 0 and len(steps) > max_steps:
        raise PlanGenerationParseError(
            f"steps exceeds max_steps={max_steps}",
            raw_text=raw_text,
            error_code="PLAN_GEN_MAX_STEPS_EXCEEDED",
        )
    for item in steps:
        _validated_step_type(item.get("type"), raw_text=raw_text)
        step_id = item.get("step_id")
        if not isinstance(step_id, str) or step_id.strip() == "":
            raise PlanGenerationParseError(
                "step_id must be a non-empty string",
                raw_text=raw_text,
                error_code="PLAN_GEN_STEP_ID_INVALID",
            )
        if not is_safe_path_segment(step_id):
            raise PlanGenerationParseError(
                f"unsafe step_id: {step_id}",
                raw_text=raw_text,
                error_code="PLAN_GEN_STEP_ID_UNSAFE",
            )


def _response_v1_or_error(
    *,
    parsed: Mapping[str, object],
    raw_text: str,
) -> _PlanGenerationResponseV1:
    try:
        return _PlanGenerationResponseV1.model_validate(parsed)
    except ValidationError as e:
        raise PlanGenerationParseError(
            f"Schema validation failed: {e}",
            raw_text=raw_text,
            error_code="PLAN_GEN_SCHEMA_INVALID",
        ) from e


def parse_plan_generation_result(
    *,
    text: str,
    max_steps: int,
    selected_templates: list[str],
) -> list[PlanStep]:
    parsed = _parse_json_object(text=text)
    raw_steps = _raw_steps_or_error(parsed=parsed, raw_text=text)
    _validate_raw_steps(steps=raw_steps, max_steps=max_steps, raw_text=text)
    response = _response_v1_or_error(parsed=parsed, raw_text=text)
    for step in response.steps:
        _validate_template_id_if_present(
            step=step,
            selected_templates=selected_templates,
            raw_text=text,
        )

    _ = LLMPlan(plan_id="plan_gen_validate", rel_path="artifacts/plan.json", steps=response.steps)
    return list(response.steps)
