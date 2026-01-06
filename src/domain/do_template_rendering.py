from __future__ import annotations

from dataclasses import dataclass

from src.infra.exceptions import DoTemplateParameterInvalidError, DoTemplateParameterMissingError


@dataclass(frozen=True)
class TemplateParamSpec:
    name: str
    required: bool


def template_param_specs(*, template_id: str, meta: dict) -> tuple[TemplateParamSpec, ...]:
    raw = meta.get("parameters", [])
    if not isinstance(raw, list):
        return tuple()
    specs: list[TemplateParamSpec] = []
    seen: set[str] = set()
    for item in raw:
        if not isinstance(item, dict):
            continue
        name = item.get("name", "")
        if not isinstance(name, str) or name.strip() == "":
            continue
        if name in seen:
            continue
        required = item.get("required", False)
        specs.append(TemplateParamSpec(name=name, required=bool(required)))
        seen.add(name)
    return tuple(specs)


def render_do_text(
    *,
    template_id: str,
    do_text: str,
    specs: tuple[TemplateParamSpec, ...],
    params: dict[str, str],
) -> tuple[str, dict[str, str]]:
    resolved: dict[str, str] = {}
    for spec in specs:
        if spec.required and spec.name not in params:
            raise DoTemplateParameterMissingError(template_id=template_id, name=spec.name)
        value = params.get(spec.name, "")
        if not isinstance(value, str):
            raise DoTemplateParameterInvalidError(template_id=template_id, name=spec.name)
        resolved[spec.name] = value

    rendered = do_text
    for name in sorted(resolved.keys(), key=len, reverse=True):
        rendered = rendered.replace(name, resolved.get(name, ""))
    return rendered, resolved

