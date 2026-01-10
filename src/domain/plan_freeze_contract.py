from __future__ import annotations

from typing import cast

from src.domain.do_template_rendering import template_param_specs
from src.domain.do_template_run_support import declared_outputs, output_filename
from src.infra.exceptions import DoTemplateContractInvalidError
from src.utils.json_types import JsonObject


def _dependencies_from_meta(*, template_id: str, meta: JsonObject) -> tuple[JsonObject, ...]:
    raw = meta.get("dependencies", [])
    if raw is None:
        return tuple()
    if not isinstance(raw, list):
        raise DoTemplateContractInvalidError(
            template_id=template_id,
            reason="meta.dependencies_invalid",
        )
    deps: list[JsonObject] = []
    for item in raw:
        if isinstance(item, dict):
            deps.append(item)
    return tuple(deps)


def _outputs_contract_from_meta(*, template_id: str, meta: JsonObject) -> JsonObject:
    outputs = []
    for output in declared_outputs(template_id=template_id, meta=meta):
        filename = output_filename(template_id=template_id, output=output)
        output_type = output.get("type", "")
        desc = output.get("description", "")
        outputs.append(
            {
                "file": filename,
                "type": output_type if isinstance(output_type, str) else "",
                "description": desc if isinstance(desc, str) else "",
            }
        )
    return cast(
        JsonObject,
        {
            "declared": outputs,
            "archive_dir_rel_path": "runs/{run_id}/artifacts/outputs",
            "filename_constraints": {
                "posix_relative": True,
                "no_parent_traversal": True,
                "no_backslash": True,
                "no_tilde": True,
            },
        },
    )


def _params_contract_from_meta(
    *,
    template_id: str,
    meta: JsonObject,
    bound_values: dict[str, str],
) -> JsonObject:
    required: list[str] = []
    optional: list[str] = []
    missing: list[str] = []
    for spec in template_param_specs(template_id=template_id, meta=meta):
        if spec.required:
            required.append(spec.name)
            value = bound_values.get(spec.name)
            if value is None or value.strip() == "":
                missing.append(spec.name)
        else:
            optional.append(spec.name)
    return cast(
        JsonObject,
        {
            "required": sorted(set(required)),
            "optional": sorted(set(optional)),
            "bound_values": dict(bound_values),
            "missing_required": sorted(set(missing)),
        },
    )


def build_plan_freeze_contract(
    *,
    template_id: str,
    meta: JsonObject,
    bound_values: dict[str, str],
) -> JsonObject:
    contract_version = meta.get("contract_version", "")
    template_version = meta.get("version", "")
    return cast(
        JsonObject,
        {
            "template_id": template_id,
            "meta_contract_version": contract_version if isinstance(contract_version, str) else "",
            "meta_template_version": template_version if isinstance(template_version, str) else "",
            "params_contract": _params_contract_from_meta(
                template_id=template_id,
                meta=meta,
                bound_values=bound_values,
            ),
            "dependencies": list(_dependencies_from_meta(template_id=template_id, meta=meta)),
            "outputs_contract": _outputs_contract_from_meta(template_id=template_id, meta=meta),
        },
    )
