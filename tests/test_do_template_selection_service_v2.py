from __future__ import annotations

import asyncio
import json
from pathlib import Path

from src.domain.do_template_selection_service import DoTemplateSelectionService
from src.domain.llm_client import LLMClient
from src.domain.models import Job
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.llm_tracing import TracedLLMClient
from src.utils.job_workspace import resolve_job_dir


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")


def _write_library_index(library_dir: Path) -> None:
    _write_json(
        library_dir / "DO_LIBRARY_INDEX.json",
        {
            "families": {
                "descriptive": {
                    "description": "Descriptive analysis",
                    "capabilities": ["summarize"],
                    "tasks": ["T01"],
                },
                "regression": {
                    "description": "Regression analysis",
                    "capabilities": ["regress"],
                    "tasks": ["T05"],
                },
            },
            "tasks": {
                "T01": {
                    "family": "descriptive", "name": "Overview", "slug": "overview",
                    "placeholders": ["__X__"],
                    "outputs": [{"file": "out.log", "type": "log"}],
                },
                "T05": {
                    "family": "regression", "name": "Regression", "slug": "regression",
                    "placeholders": ["__Y__", "__X__"],
                    "outputs": [{"file": "out.log", "type": "log"}],
                },
            },
        },
    )


def _make_traced_llm(*, inner: LLMClient, jobs_dir: Path) -> TracedLLMClient:
    return TracedLLMClient(
        inner=inner,
        jobs_dir=jobs_dir,
        model="fake",
        temperature=None,
        seed=None,
        timeout_seconds=30.0,
        max_attempts=1,
        retry_backoff_base_seconds=0.0,
        retry_backoff_max_seconds=0.0,
    )


def _read_stage2_artifact(*, jobs_dir: Path, job_id: str) -> dict:
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    path = job_dir / "artifacts/do_template/selection/stage2.json"
    return json.loads(path.read_text(encoding="utf-8"))


def _make_service(
    *,
    store,
    llm: LLMClient,
    catalog: FileSystemDoTemplateCatalog,
) -> DoTemplateSelectionService:
    return DoTemplateSelectionService(
        store=store,
        llm=llm,
        catalog=catalog,
        stage1_max_families=2,
        stage2_max_candidates=20,
        stage2_token_budget=10_000,
        max_attempts=2,
    )


class ScriptedLLM(LLMClient):
    def __init__(self, *, responses: dict[str, list[str]]):
        self._responses = {key: list(values) for key, values in responses.items()}

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        _ = job
        _ = prompt
        queue = self._responses.get(operation)
        if queue is None or len(queue) == 0:
            return "{}"
        return queue.pop(0)


def test_select_template_id_with_multi_template_selection_returns_supplementary_templates(
    job_service,
    store,
    jobs_dir: Path,
    tmp_path: Path,
):
    # Arrange
    library = tmp_path / "library"
    _write_library_index(library)
    catalog = FileSystemDoTemplateCatalog(library_dir=library)
    llm = _make_traced_llm(
        inner=ScriptedLLM(
            responses={
                "do_template.select_families": [
                    json.dumps(
                        {
                            "schema_version": 2,
                            "families": [
                                {
                                    "family_id": "descriptive",
                                    "reason": "need descriptive stats first",
                                    "confidence": 0.9,
                                },
                                {
                                    "family_id": "regression",
                                    "reason": "need regression after",
                                    "confidence": 0.9,
                                },
                            ],
                            "analysis_sequence": ["descriptive", "regression"],
                            "requires_combination": True,
                            "combination_reason": "multi-stage analysis (descriptive → regression)",
                        }
                    )
                ],
                "do_template.select_template": [
                    json.dumps(
                        {
                            "schema_version": 2,
                            "primary_template_id": "T05",
                            "primary_reason": "Regression is the primary analysis step",
                            "primary_confidence": 0.9,
                            "supplementary_templates": [
                                {
                                    "template_id": "T01",
                                    "purpose": "descriptive overview before regression",
                                    "sequence_order": 1,
                                    "confidence": 0.8,
                                }
                            ],
                        }
                    )
                ],
            },
        ),
        jobs_dir=jobs_dir,
    )
    svc = _make_service(store=store, llm=llm, catalog=catalog)
    job = job_service.create_job(requirement="first descriptive stats then regression")

    # Act
    result = asyncio.run(svc.select_template_id(job_id=job.job_id))

    # Assert
    assert result.selected_template_id == "T05"
    assert result.supplementary_template_ids == ("T01",)
    assert result.analysis_sequence == ("descriptive", "regression")
    assert result.requires_combination is True
    assert result.requires_user_confirmation is False
    assert result.used_manual_fallback is False
    assert result.primary_confidence == 0.9

    stage2_payload = _read_stage2_artifact(jobs_dir=jobs_dir, job_id=job.job_id)
    assert stage2_payload["supplementary_template_ids"] == ["T01"]
    assert stage2_payload["requires_user_confirmation"] is False
    assert stage2_payload["used_manual_fallback"] is False
    assert stage2_payload["selection"]["schema_version"] == 2


def test_select_template_id_when_low_confidence_requires_user_confirmation(
    job_service,
    store,
    jobs_dir: Path,
    tmp_path: Path,
):
    # Arrange
    library = tmp_path / "library"
    _write_library_index(library)
    catalog = FileSystemDoTemplateCatalog(library_dir=library)
    llm = _make_traced_llm(
        inner=ScriptedLLM(
            responses={
                "do_template.select_families": [
                    json.dumps(
                        {
                            "schema_version": 2,
                            "families": [
                                dict(family_id="regression", reason="regression", confidence=0.8)
                            ],
                            "analysis_sequence": ["regression"],
                            "requires_combination": False,
                            "combination_reason": "",
                        }
                    )
                ],
                "do_template.select_template": [
                    json.dumps(
                        {
                            "schema_version": 2,
                            "primary_template_id": "T05",
                            "primary_reason": "best match",
                            "primary_confidence": 0.5,
                            "supplementary_templates": [],
                        }
                    )
                ],
            },
        ),
        jobs_dir=jobs_dir,
    )
    svc = _make_service(store=store, llm=llm, catalog=catalog)
    job = job_service.create_job(requirement="run regression")

    # Act
    result = asyncio.run(svc.select_template_id(job_id=job.job_id))

    # Assert
    assert result.selected_template_id == "T05"
    assert result.requires_user_confirmation is True
    assert result.used_manual_fallback is False
    assert result.primary_confidence == 0.5

    stage2_payload = _read_stage2_artifact(jobs_dir=jobs_dir, job_id=job.job_id)
    assert stage2_payload["requires_user_confirmation"] is True
    assert stage2_payload["used_manual_fallback"] is False


def test_select_template_id_when_confidence_below_manual_threshold_falls_back_to_top_candidate(
    job_service,
    store,
    jobs_dir: Path,
    tmp_path: Path,
):
    # Arrange
    library = tmp_path / "library"
    _write_library_index(library)
    catalog = FileSystemDoTemplateCatalog(library_dir=library)
    llm = _make_traced_llm(
        inner=ScriptedLLM(
            responses={
                "do_template.select_families": [
                    json.dumps(
                        {
                            "schema_version": 2,
                            "families": [
                                dict(family_id="descriptive", reason="overview", confidence=0.8),
                                dict(family_id="regression", reason="maybe also", confidence=0.5),
                            ],
                            "analysis_sequence": ["descriptive", "regression"],
                            "requires_combination": False,
                            "combination_reason": "",
                        }
                    )
                ],
                "do_template.select_template": [
                    json.dumps(
                        {
                            "schema_version": 2,
                            "primary_template_id": "T05",
                            "primary_reason": "uncertain",
                            "primary_confidence": 0.2,
                            "supplementary_templates": [],
                        }
                    )
                ],
            },
        ),
        jobs_dir=jobs_dir,
    )
    svc = _make_service(store=store, llm=llm, catalog=catalog)
    job = job_service.create_job(requirement="need an overview")

    # Act
    result = asyncio.run(svc.select_template_id(job_id=job.job_id))

    # Assert
    assert result.selected_template_id == "T01"
    assert result.supplementary_template_ids == tuple()
    assert result.requires_user_confirmation is True
    assert result.used_manual_fallback is True
    assert result.primary_confidence == 0.2

    stage2_payload = _read_stage2_artifact(jobs_dir=jobs_dir, job_id=job.job_id)
    assert stage2_payload["selected_template_id"] == "T01"
    assert stage2_payload["used_manual_fallback"] is True
    assert stage2_payload["selection"]["primary_template_id"] == "T05"
