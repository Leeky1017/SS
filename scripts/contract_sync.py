from __future__ import annotations

import argparse
import difflib
import json
import os
import re
import subprocess
import tempfile
from collections import deque
from pathlib import Path
from typing import Any

PUBLIC_TYPES_OUT = Path("frontend/src/api/types.ts")
ADMIN_TYPES_OUT = Path("frontend/src/features/admin/adminApiTypes.ts")

OPENAPI_TYPESCRIPT_VERSION = "7.9.1"

PUBLIC_EXPORTS: list[str] = [
    "SSJobStatus",
    "JsonScalar",
    "JsonValue",
    "RedeemTaskCodeRequest",
    "RedeemTaskCodeResponse",
    "ConfirmJobRequest",
    "ConfirmJobResponse",
    "PlanStepResponse",
    "LLMPlanResponse",
    "FreezePlanRequest",
    "FreezePlanResponse",
    "GetPlanResponse",
    "JobTimestamps",
    "DraftSummary",
    "ArtifactsSummary",
    "RunAttemptSummary",
    "GetJobResponse",
    "ArtifactIndexItem",
    "ArtifactsIndexResponse",
    "InputsUploadResponse",
    "InputsPreviewColumn",
    "InputsPreviewResponse",
    "DraftPreviewDataSource",
    "DraftPreviewDecision",
    "DraftPreviewPendingResponse",
    "DraftQualityWarning",
    "DraftStage1Option",
    "DraftStage1Question",
    "DraftOpenUnknown",
    "DraftPreviewReadyResponse",
    "DraftPreviewResponse",
    "DraftPatchRequest",
    "DraftPatchResponse",
    "RunJobResponse",
]

ADMIN_EXPORTS: list[str] = [
    "AdminLoginRequest",
    "AdminLoginResponse",
    "AdminLogoutResponse",
    "AdminTokenItem",
    "AdminTokenListResponse",
    "AdminTokenCreateRequest",
    "AdminTokenCreateResponse",
    "AdminTaskCodeItem",
    "AdminTaskCodeCreateRequest",
    "AdminTaskCodeListResponse",
    "AdminJobListItem",
    "AdminJobListResponse",
    "AdminArtifactItem",
    "AdminRunAttemptItem",
    "AdminJobDetailResponse",
    "AdminJobRetryResponse",
    "AdminTenantListResponse",
    "AdminSystemStatusResponse",
]

PUBLIC_SCHEMA_ROOTS: set[str] = {
    "ArtifactIndexItem",
    "ArtifactsIndexResponse",
    "ArtifactsSummary",
    "ConfirmJobRequest",
    "ConfirmJobResponse",
    "DraftDataQualityWarning",
    "DraftOpenUnknown",
    "DraftPatchRequest",
    "DraftPatchResponse",
    "DraftPreviewDataSource",
    "DraftPreviewPendingResponse",
    "DraftPreviewResponse",
    "DraftStage1Option",
    "DraftStage1Question",
    "DraftSummary",
    "FreezePlanRequest",
    "FreezePlanResponse",
    "GetJobResponse",
    "GetPlanResponse",
    "InputsPreviewColumn",
    "InputsPreviewResponse",
    "InputsUploadResponse",
    "JobTimestamps",
    "LLMPlanResponse",
    "PlanStepResponse",
    "RunAttemptSummary",
    "RunJobResponse",
    "TaskCodeRedeemRequest",
    "TaskCodeRedeemResponse",
}


def _ensure_minimal_env_for_openapi_export() -> None:
    os.environ.setdefault("SS_ENV", "development")
    os.environ.setdefault("SS_LLM_PROVIDER", "yunwu")
    os.environ.setdefault("SS_LLM_API_KEY", "test-key")


def _export_openapi_spec() -> dict[str, Any]:
    _ensure_minimal_env_for_openapi_export()
    from src.main import create_app

    app = create_app()
    return app.openapi()


def _collect_ref_schema_names(schema: object) -> set[str]:
    ref_re = re.compile(r"^#/components/schemas/(.+)$")
    refs: set[str] = set()
    stack: list[object] = [schema]
    while stack:
        node = stack.pop()
        if isinstance(node, dict):
            ref = node.get("$ref")
            if isinstance(ref, str):
                match = ref_re.match(ref)
                if match:
                    refs.add(match.group(1))
            stack.extend(node.values())
        elif isinstance(node, list):
            stack.extend(node)
    return refs


def _schema_dependency_closure(*, schemas: dict[str, Any], roots: set[str]) -> set[str]:
    needed = set(roots)
    queue: deque[str] = deque(sorted(roots))
    while queue:
        name = queue.popleft()
        schema = schemas.get(name)
        if schema is None:
            continue
        for ref in _collect_ref_schema_names(schema):
            if ref not in needed:
                needed.add(ref)
                queue.append(ref)
    return needed


def _build_pruned_openapi_spec(*, spec: dict[str, Any], schema_names: set[str]) -> dict[str, Any]:
    all_schemas = dict(spec.get("components", {}).get("schemas", {}))
    pruned_schemas = {k: all_schemas[k] for k in sorted(schema_names) if k in all_schemas}
    return {
        "openapi": spec.get("openapi", "3.1.0"),
        "info": spec.get("info", {"title": "SS", "version": "0.0.0"}),
        "paths": {},
        "components": {"schemas": pruned_schemas},
    }


def _run_openapi_typescript(*, openapi_json: Path, out_ts: Path) -> None:
    cmd = [
        "npm",
        "--prefix",
        "frontend",
        "exec",
        "--",
        "openapi-typescript",
        str(openapi_json),
        "-o",
        str(out_ts),
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)
    except FileNotFoundError as exc:
        msg = "npm not found; install Node.js to run OpenAPI → TypeScript generation"
        raise RuntimeError(msg) from exc
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr.strip()
        stdout = exc.stdout.strip()
        message = stderr or stdout or "openapi-typescript failed"
        raise RuntimeError(message) from exc


def _strip_jsdoc_comments(text: str) -> str:
    return re.sub(r"/\\*\\*.*?\\*/", "", text, flags=re.S)


def _strip_blank_lines(text: str) -> str:
    return "\n".join([ln for ln in text.splitlines() if ln.strip() != ""]) + "\n"


def _filter_unneeded_exports(text: str) -> str:
    lines: list[str] = []
    for line in text.splitlines():
        if line.strip() in {
            "export type paths = Record<string, never>;",
            "export type webhooks = Record<string, never>;",
        }:
            continue
        lines.append(line)
    return "\n".join(lines) + "\n"


def _format_public_exports() -> str:
    lines: list[str] = [
        "export type JsonScalar = components['schemas']['JsonScalar'];",
        "type JsonValueInput = components['schemas']['JsonValue-Input'];",
        "type JsonValueOutput = components['schemas']['JsonValue-Output'];",
        "export type JsonValue = JsonValueInput | JsonValueOutput;",
        "export type RedeemTaskCodeRequest = components['schemas']['TaskCodeRedeemRequest'];",
        "export type RedeemTaskCodeResponse = components['schemas']['TaskCodeRedeemResponse'];",
        "export type ConfirmJobRequest = components['schemas']['ConfirmJobRequest'];",
        "export type ConfirmJobResponse = components['schemas']['ConfirmJobResponse'];",
        "export type PlanStepResponse = components['schemas']['PlanStepResponse'];",
        "export type LLMPlanResponse = components['schemas']['LLMPlanResponse'];",
        "export type FreezePlanRequest = components['schemas']['FreezePlanRequest'];",
        "export type FreezePlanResponse = components['schemas']['FreezePlanResponse'];",
        "export type GetPlanResponse = components['schemas']['GetPlanResponse'];",
        "export type JobTimestamps = components['schemas']['JobTimestamps'];",
        "export type DraftSummary = components['schemas']['DraftSummary'];",
        "export type ArtifactsSummary = components['schemas']['ArtifactsSummary'];",
        "export type RunAttemptSummary = components['schemas']['RunAttemptSummary'];",
        "export type GetJobResponse = components['schemas']['GetJobResponse'];",
        "export type ArtifactIndexItem = components['schemas']['ArtifactIndexItem'];",
        "export type ArtifactsIndexResponse = components['schemas']['ArtifactsIndexResponse'];",
        "export type InputsUploadResponse = components['schemas']['InputsUploadResponse'];",
        "export type InputsPreviewColumn = components['schemas']['InputsPreviewColumn'];",
        "export type InputsPreviewResponse = components['schemas']['InputsPreviewResponse'];",
        "export type DraftPreviewDataSource = components['schemas']['DraftPreviewDataSource'];",
        (
            "export type DraftPreviewPendingResponse = "
            "components['schemas']['DraftPreviewPendingResponse'];"
        ),
        "export type DraftQualityWarning = components['schemas']['DraftDataQualityWarning'];",
        "export type DraftStage1Option = components['schemas']['DraftStage1Option'];",
        "export type DraftStage1Question = components['schemas']['DraftStage1Question'];",
        "export type DraftOpenUnknown = components['schemas']['DraftOpenUnknown'];",
        "export type DraftPreviewReadyResponse = components['schemas']['DraftPreviewResponse'];",
        "export type DraftPreviewDecision = DraftPreviewReadyResponse['decision'];",
        (
            "export type DraftPreviewResponse = "
            "DraftPreviewPendingResponse | DraftPreviewReadyResponse;"
        ),
        "export type DraftPatchRequest = components['schemas']['DraftPatchRequest'];",
        "export type DraftPatchResponse = components['schemas']['DraftPatchResponse'];",
        "export type RunJobResponse = components['schemas']['RunJobResponse'];",
        "export type SSJobStatus = GetJobResponse['status'];",
    ]
    exported = [ln.split()[2] for ln in lines if ln.startswith("export type ")]
    missing = [name for name in PUBLIC_EXPORTS if name not in set(exported)]
    if missing:
        raise RuntimeError(f"missing public export lines: {missing}")
    return "\n".join(lines) + "\n"


def _format_admin_exports() -> str:
    lines = [f"export type {name} = components['schemas']['{name}'];" for name in ADMIN_EXPORTS]
    return "\n".join(lines) + "\n"


def _generate_types_file(*, spec: dict[str, Any], roots: set[str], exports_block: str) -> str:
    schemas = dict(spec.get("components", {}).get("schemas", {}))
    needed = _schema_dependency_closure(schemas=schemas, roots=roots)
    pruned = _build_pruned_openapi_spec(spec=spec, schema_names=needed)

    with tempfile.TemporaryDirectory(prefix="ss-contract-sync-") as tmp:
        tmp_dir = Path(tmp)
        openapi_json = tmp_dir / "openapi.pruned.json"
        openapi_json.write_text(
            json.dumps(pruned, ensure_ascii=False, indent=2, sort_keys=True),
            encoding="utf-8",
        )

        generated_ts = tmp_dir / "openapi.types.ts"
        _run_openapi_typescript(openapi_json=openapi_json, out_ts=generated_ts)
        base = generated_ts.read_text(encoding="utf-8")

    base = _strip_jsdoc_comments(base)
    base = _filter_unneeded_exports(base)
    base = _strip_blank_lines(base)

    header = (
        "// GENERATED FILE - DO NOT EDIT.\n"
        f"// Source: FastAPI OpenAPI → openapi-typescript@{OPENAPI_TYPESCRIPT_VERSION}.\n"
        "// Run: scripts/contract_sync.sh generate\n"
        "\n"
    )
    content = header + base + "\n" + exports_block
    if content.count("\n") >= 300:
        raise RuntimeError("generated file >= 300 lines; must stay under repo line limit")
    return content


def _unified_diff(*, old: str, new: str, path: Path) -> str:
    diff = difflib.unified_diff(
        old.splitlines(keepends=True),
        new.splitlines(keepends=True),
        fromfile=str(path),
        tofile=str(path),
    )
    return "".join(diff)


def _write_or_check(*, out_path: Path, content: str, mode: str) -> bool:
    existing = out_path.read_text(encoding="utf-8") if out_path.exists() else ""
    if existing == content:
        return True

    if mode == "check":
        print(_unified_diff(old=existing, new=content, path=out_path))
        return False

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content, encoding="utf-8")
    return True


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="SS API contract sync (OpenAPI → frontend types).")
    parser.add_argument("mode", choices=["check", "generate"])
    return parser


def main() -> int:
    args = _build_parser().parse_args()
    spec = _export_openapi_spec()

    public_content = _generate_types_file(
        spec=spec,
        roots=PUBLIC_SCHEMA_ROOTS,
        exports_block=_format_public_exports(),
    )
    ok_public = _write_or_check(out_path=PUBLIC_TYPES_OUT, content=public_content, mode=args.mode)

    admin_content = _generate_types_file(
        spec=spec,
        roots=set(ADMIN_EXPORTS),
        exports_block=_format_admin_exports(),
    )
    ok_admin = _write_or_check(out_path=ADMIN_TYPES_OUT, content=admin_content, mode=args.mode)

    return 0 if ok_public and ok_admin else 1


if __name__ == "__main__":
    raise SystemExit(main())
