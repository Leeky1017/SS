from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import cast

from src.infra.exceptions import SSError
from src.utils.json_types import JsonObject

DEFAULT_SMOKE_MANIFEST_REL_PATH = Path("smoke_suite/manifest.1.0.json")


@dataclass(frozen=True)
class SmokeSuiteFixture:
    source: str
    dest: str


@dataclass(frozen=True)
class SmokeSuiteDependency:
    pkg: str
    source: str
    purpose: str


@dataclass(frozen=True)
class SmokeSuiteTemplate:
    template_id: str
    fixtures: tuple[SmokeSuiteFixture, ...]
    params: dict[str, str]
    dependencies: tuple[SmokeSuiteDependency, ...]


@dataclass(frozen=True)
class SmokeSuiteManifest:
    schema_version: str
    suite_id: str
    templates: dict[str, SmokeSuiteTemplate]


def _load_json_object(path: Path) -> JsonObject:
    try:
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError as e:
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_NOT_FOUND",
            message=f"smoke suite manifest not found: {path}",
        ) from e
    except OSError as e:
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_READ_FAILED",
            message=f"smoke suite manifest read failed: {path} ({e})",
        ) from e
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_INVALID_JSON",
            message=f"smoke suite manifest invalid json: {path} ({e})",
        ) from e
    if not isinstance(data, dict):
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_INVALID",
            message=f"smoke suite manifest must be a JSON object: {path}",
        )
    return cast(JsonObject, data)


def _require_str(obj: JsonObject, key: str) -> str:
    value = obj.get(key, "")
    if not isinstance(value, str) or value.strip() == "":
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_INVALID",
            message=f"smoke suite manifest missing or invalid '{key}'",
        )
    return value


def _is_safe_dest_filename(value: str) -> bool:
    if value == "":
        return False
    if "/" in value or "\\" in value:
        return False
    if value in {".", ".."}:
        return False
    return ".." not in Path(value).parts


def _parse_fixtures(*, template_id: str, raw: object) -> tuple[SmokeSuiteFixture, ...]:
    if not isinstance(raw, list) or not raw:
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_INVALID",
            message=f"smoke suite manifest invalid fixtures for {template_id}",
        )
    fixtures: list[SmokeSuiteFixture] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        source = item.get("source", "")
        dest = item.get("dest", "")
        if not isinstance(source, str) or source.strip() == "":
            continue
        if not isinstance(dest, str) or not _is_safe_dest_filename(dest):
            continue
        fixtures.append(SmokeSuiteFixture(source=source, dest=dest))
    if not fixtures:
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_INVALID",
            message=f"smoke suite manifest has no valid fixtures for {template_id}",
        )
    return tuple(fixtures)


def _parse_params(*, template_id: str, raw: object) -> dict[str, str]:
    if not isinstance(raw, dict):
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_INVALID",
            message=f"smoke suite manifest invalid params for {template_id}",
        )
    params: dict[str, str] = {}
    for key, value in raw.items():
        if not isinstance(key, str) or key.strip() == "":
            continue
        if not isinstance(value, str):
            raise SSError(
                error_code="SMOKE_SUITE_MANIFEST_INVALID",
                message=f"smoke suite manifest param '{key}' must be a string ({template_id})",
            )
        params[key] = value
    return params


def _parse_dependencies(*, template_id: str, raw: object) -> tuple[SmokeSuiteDependency, ...]:
    if not isinstance(raw, list):
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_INVALID",
            message=f"smoke suite manifest invalid dependencies for {template_id}",
        )
    deps: list[SmokeSuiteDependency] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        pkg = item.get("pkg", "")
        source = item.get("source", "")
        purpose = item.get("purpose", "")
        if not isinstance(pkg, str) or pkg.strip() == "":
            continue
        if source not in {"built-in", "ssc"}:
            continue
        if not isinstance(purpose, str):
            purpose = ""
        deps.append(SmokeSuiteDependency(pkg=pkg, source=source, purpose=purpose))
    return tuple(deps)


def load_smoke_suite_manifest(*, path: Path) -> SmokeSuiteManifest:
    payload = _load_json_object(path)
    schema_version = _require_str(payload, "schema_version")
    suite_id = _require_str(payload, "suite_id")

    templates_raw = payload.get("templates", None)
    if not isinstance(templates_raw, dict) or not templates_raw:
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_INVALID",
            message="smoke suite manifest missing or invalid 'templates'",
        )

    templates: dict[str, SmokeSuiteTemplate] = {}
    for template_id, entry in templates_raw.items():
        if not isinstance(template_id, str) or template_id.strip() == "":
            continue
        if not isinstance(entry, dict):
            raise SSError(
                error_code="SMOKE_SUITE_MANIFEST_INVALID",
                message=f"smoke suite manifest entry must be an object ({template_id})",
            )
        fixtures = _parse_fixtures(template_id=template_id, raw=entry.get("fixtures", None))
        params = _parse_params(template_id=template_id, raw=entry.get("params", None))
        deps = _parse_dependencies(template_id=template_id, raw=entry.get("dependencies", []))
        templates[template_id] = SmokeSuiteTemplate(
            template_id=template_id,
            fixtures=fixtures,
            params=params,
            dependencies=deps,
        )

    if not templates:
        raise SSError(
            error_code="SMOKE_SUITE_MANIFEST_INVALID",
            message="smoke suite manifest has no valid templates",
        )

    return SmokeSuiteManifest(
        schema_version=schema_version,
        suite_id=suite_id,
        templates=templates,
    )

