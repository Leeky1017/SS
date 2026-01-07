from __future__ import annotations

import asyncio
import json
from pathlib import Path

from src.domain.do_template_catalog import TemplateSummary
from src.domain.do_template_selection_prompting import (
    estimate_tokens,
    template_prompt_item,
    trim_templates,
)
from src.domain.do_template_selection_service import DoTemplateSelectionService
from src.domain.llm_client import LLMClient
from src.domain.models import ArtifactKind, Job
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.llm_tracing import TracedLLMClient
from src.utils.job_workspace import resolve_job_dir


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")


def test_select_template_id_when_llm_returns_invalid_then_valid_enforces_membership(
    job_service,
    store,
    jobs_dir: Path,
    tmp_path: Path,
):
    # Arrange
    library = tmp_path / "library"
    _write_json(
        library / "DO_LIBRARY_INDEX.json",
        {
            "families": {
                "descriptive": {
                    "description": "Descriptive analysis",
                    "capabilities": ["summarize"],
                    "tasks": ["T01", "T02"],
                }
            },
            "tasks": {
                "T01": {
                    "family": "descriptive",
                    "name": "Overview",
                    "slug": "overview",
                    "placeholders": ["__X__"],
                    "outputs": [{"file": "out.log", "type": "log"}],
                },
                "T02": {
                    "family": "descriptive",
                    "name": "Summary",
                    "slug": "summary",
                    "placeholders": [],
                    "outputs": [{"file": "out.csv", "type": "table"}],
                },
            },
        },
    )
    catalog = FileSystemDoTemplateCatalog(library_dir=library)

    class FakeLLM(LLMClient):
        def __init__(self) -> None:
            self.stage2_calls = 0

        async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
            if operation == "do_template.select_families":
                return json.dumps(
                    {
                        "schema_version": 1,
                        "families": [
                            {
                                "family_id": "descriptive",
                                "reason": "matches descriptive",
                                "confidence": 0.9,
                            }
                        ],
                    }
                )
            if operation != "do_template.select_template":
                return "{}"
            self.stage2_calls += 1
            if self.stage2_calls == 1:
                return json.dumps(
                    {
                        "schema_version": 1,
                        "template_id": "T404",
                        "reason": "oops",
                        "confidence": 0.1,
                    }
                )
            return json.dumps(
                {
                    "schema_version": 1,
                    "template_id": "T01",
                    "reason": "valid choice",
                    "confidence": 0.8,
                }
            )

    llm = TracedLLMClient(
        inner=FakeLLM(),
        jobs_dir=jobs_dir,
        model="fake",
        temperature=None,
        seed=None,
        timeout_seconds=30.0,
        max_attempts=1,
        retry_backoff_base_seconds=0.0,
        retry_backoff_max_seconds=0.0,
    )
    svc = DoTemplateSelectionService(
        store=store,
        llm=llm,
        catalog=catalog,
        stage1_max_families=1,
        stage2_max_candidates=10,
        stage2_token_budget=10_000,
        max_attempts=2,
    )
    job = job_service.create_job(requirement="need an overview")

    # Act
    result = asyncio.run(svc.select_template_id(job_id=job.job_id))

    # Assert
    assert result.selected_template_id == "T01"
    loaded = store.load(job.job_id)
    kinds = {ref.kind for ref in loaded.artifacts_index}
    assert ArtifactKind.DO_TEMPLATE_SELECTION_STAGE1 in kinds
    assert ArtifactKind.DO_TEMPLATE_SELECTION_CANDIDATES in kinds
    assert ArtifactKind.DO_TEMPLATE_SELECTION_STAGE2 in kinds

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    assert (job_dir / "artifacts/do_template/selection/stage1.json").exists()
    assert (job_dir / "artifacts/do_template/selection/candidates.json").exists()
    assert (job_dir / "artifacts/do_template/selection/stage2.json").exists()


def test_trim_templates_within_budget_is_deterministic():
    # Arrange
    templates = (
        TemplateSummary(
            template_id="T01",
            family_id="descriptive",
            name="Overview",
            slug="overview",
            placeholders=tuple(),
            output_types=("log",),
        ),
        TemplateSummary(
            template_id="T02",
            family_id="descriptive",
            name="Summary",
            slug="summary",
            placeholders=tuple(),
            output_types=("table",),
        ),
        TemplateSummary(
            template_id="T03",
            family_id="descriptive",
            name="More",
            slug="more",
            placeholders=tuple(),
            output_types=("table",),
        ),
    )
    costs = [
        estimate_tokens(json.dumps(template_prompt_item(t), ensure_ascii=False, sort_keys=True))
        for t in templates
    ]
    budget = costs[0] + costs[1]

    # Act
    first = trim_templates(templates=templates, token_budget=budget, max_candidates=10)
    second = trim_templates(templates=templates, token_budget=budget, max_candidates=10)

    # Assert
    assert first == second
    assert tuple(t.template_id for t in first) == ("T01", "T02")
    used = sum(
        estimate_tokens(json.dumps(template_prompt_item(t), ensure_ascii=False, sort_keys=True))
        for t in first
    )
    assert used <= budget
