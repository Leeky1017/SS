from __future__ import annotations

import json
from pathlib import Path

import pytest

from src.domain.do_template_run_service import DoTemplateRunService
from src.domain.models import ArtifactKind, ArtifactRef, JobStatus
from src.domain.stata_runner import RunResult
from src.infra.exceptions import DoTemplateParameterMissingError
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.stata_run_support import job_rel_path, resolve_run_dirs, write_text
from src.utils.job_workspace import resolve_job_dir


class FakeRunner:
    def __init__(self, *, jobs_dir: Path):
        self._jobs_dir = jobs_dir

    def run(
        self,
        *,
        tenant_id: str = "default",
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None = None,
        ) -> RunResult:
        dirs = resolve_run_dirs(jobs_dir=self._jobs_dir, job_id=job_id, run_id=run_id)
        assert dirs is not None
        dirs.work_dir.mkdir(parents=True, exist_ok=True)
        dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)
        do_path = dirs.artifacts_dir / "stata.do"
        write_text(do_path, do_file)
        write_text(dirs.work_dir / "result.log", "hello\n")
        rel_path = job_rel_path(job_dir=dirs.job_dir, path=do_path)
        return RunResult(
            job_id=job_id,
            run_id=run_id,
            ok=True,
            exit_code=0,
            timed_out=False,
            artifacts=(
                ArtifactRef(
                    kind=ArtifactKind.STATA_DO,
                    rel_path=rel_path,
                ),
            ),
            error=None,
        )


class FakeRunnerWithNestedOutput:
    def __init__(self, *, jobs_dir: Path):
        self._jobs_dir = jobs_dir

    def run(
        self,
        *,
        tenant_id: str = "default",
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None = None,
    ) -> RunResult:
        dirs = resolve_run_dirs(jobs_dir=self._jobs_dir, job_id=job_id, run_id=run_id)
        assert dirs is not None
        dirs.work_dir.mkdir(parents=True, exist_ok=True)
        dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)
        do_path = dirs.artifacts_dir / "stata.do"
        write_text(do_path, do_file)
        write_text(dirs.work_dir / "outputs" / "manifest.txt", "manifest\n")
        rel_path = job_rel_path(job_dir=dirs.job_dir, path=do_path)
        return RunResult(
            job_id=job_id,
            run_id=run_id,
            ok=True,
            exit_code=0,
            timed_out=False,
            artifacts=(ArtifactRef(kind=ArtifactKind.STATA_DO, rel_path=rel_path),),
            error=None,
        )


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")


def test_run_when_template_ok_archives_template_and_outputs(
    job_service,
    store,
    state_machine,
    jobs_dir: Path,
    tmp_path: Path,
):
    # Arrange
    library = tmp_path / "library"
    _write_json(library / "DO_LIBRARY_INDEX.json", {"tasks": {"T01": {"do_file": "T01_demo.do"}}})
    (library / "do").mkdir(parents=True, exist_ok=True)
    (library / "do" / "T01_demo.do").write_text('display "__X__"\n', encoding="utf-8")
    _write_json(
        library / "do" / "meta" / "T01_demo.meta.json",
        {
            "id": "T01",
            "parameters": [{"name": "__X__", "required": True}],
            "outputs": [{"file": "result.log", "type": "log"}],
        },
    )

    job = job_service.create_job(requirement="demo", plan_revision="run-1")
    repo = FileSystemDoTemplateRepository(library_dir=library)
    runner = FakeRunner(jobs_dir=jobs_dir)
    svc = DoTemplateRunService(
        store=store,
        runner=runner,
        repo=repo,
        state_machine=state_machine,
        jobs_dir=jobs_dir,
    )

    # Act
    result = svc.run(
        job_id=job.job_id,
        template_id="T01",
        params={"__X__": "123"},
        run_id="run_demo",
    )

    # Assert
    assert result.ok is True
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    artifacts_dir = job_dir / "runs" / "run_demo" / "artifacts"
    assert (artifacts_dir / "template" / "source.do").exists()
    assert (artifacts_dir / "template" / "meta.json").exists()
    assert (artifacts_dir / "template" / "params.json").exists()
    assert (artifacts_dir / "outputs" / "result.log").exists()


def test_run_when_output_is_nested_path_archives_nested_output(
    job_service,
    store,
    state_machine,
    jobs_dir: Path,
    tmp_path: Path,
):
    # Arrange
    library = tmp_path / "library"
    _write_json(library / "DO_LIBRARY_INDEX.json", {"tasks": {"T01": {"do_file": "T01_demo.do"}}})
    (library / "do").mkdir(parents=True, exist_ok=True)
    (library / "do" / "T01_demo.do").write_text("exit 0\n", encoding="utf-8")
    _write_json(
        library / "do" / "meta" / "T01_demo.meta.json",
        {
            "id": "T01",
            "parameters": [],
            "outputs": [{"file": "outputs/manifest.txt", "type": "manifest"}],
        },
    )

    job = job_service.create_job(requirement="demo", plan_revision="nested-output-1")
    repo = FileSystemDoTemplateRepository(library_dir=library)
    runner = FakeRunnerWithNestedOutput(jobs_dir=jobs_dir)
    svc = DoTemplateRunService(
        store=store,
        runner=runner,
        repo=repo,
        state_machine=state_machine,
        jobs_dir=jobs_dir,
    )

    # Act
    result = svc.run(
        job_id=job.job_id,
        template_id="T01",
        params={},
        run_id="run_demo",
    )

    # Assert
    assert result.ok is True
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    artifacts_dir = job_dir / "runs" / "run_demo" / "artifacts"
    assert (artifacts_dir / "outputs" / "outputs" / "manifest.txt").exists()


def test_run_when_required_param_missing_marks_job_failed(
    job_service,
    store,
    state_machine,
    jobs_dir: Path,
    tmp_path: Path,
):
    # Arrange
    library = tmp_path / "library"
    _write_json(library / "DO_LIBRARY_INDEX.json", {"tasks": {"T01": {"do_file": "T01_demo.do"}}})
    (library / "do").mkdir(parents=True, exist_ok=True)
    (library / "do" / "T01_demo.do").write_text('display "__X__"\n', encoding="utf-8")
    _write_json(
        library / "do" / "meta" / "T01_demo.meta.json",
        {"id": "T01", "parameters": [{"name": "__X__", "required": True}]},
    )

    job = job_service.create_job(requirement="demo", plan_revision="run-2")
    repo = FileSystemDoTemplateRepository(library_dir=library)
    runner = FakeRunner(jobs_dir=jobs_dir)
    svc = DoTemplateRunService(
        store=store,
        runner=runner,
        repo=repo,
        state_machine=state_machine,
        jobs_dir=jobs_dir,
    )

    # Act / Assert
    with pytest.raises(DoTemplateParameterMissingError):
        svc.run(job_id=job.job_id, template_id="T01", params={}, run_id="run_missing")
    updated = store.load(job.job_id)
    assert updated.status == JobStatus.FAILED


def test_run_when_template_requires_panelvar_accepts_id_var_param_alias(
    job_service,
    store,
    state_machine,
    jobs_dir: Path,
    tmp_path: Path,
):
    # Arrange
    library = tmp_path / "library"
    _write_json(library / "DO_LIBRARY_INDEX.json", {"tasks": {"TF01": {"do_file": "TF01_demo.do"}}})
    (library / "do").mkdir(parents=True, exist_ok=True)
    (library / "do" / "TF01_demo.do").write_text('display "__PANELVAR__"\n', encoding="utf-8")
    _write_json(
        library / "do" / "meta" / "TF01_demo.meta.json",
        {
            "id": "TF01",
            "parameters": [{"name": "__PANELVAR__", "required": True}],
            "outputs": [{"file": "result.log", "type": "log"}],
        },
    )

    job = job_service.create_job(requirement="demo", plan_revision="run-alias-1")
    repo = FileSystemDoTemplateRepository(library_dir=library)
    runner = FakeRunner(jobs_dir=jobs_dir)
    svc = DoTemplateRunService(
        store=store,
        runner=runner,
        repo=repo,
        state_machine=state_machine,
        jobs_dir=jobs_dir,
    )

    # Act
    result = svc.run(
        job_id=job.job_id,
        template_id="TF01",
        params={"__ID_VAR__": "firm_id"},
        run_id="run_alias",
    )

    # Assert
    assert result.ok is True
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    rendered_do = (job_dir / "runs" / "run_alias" / "artifacts" / "stata.do").read_text(
        encoding="utf-8"
    )
    assert 'display "firm_id"' in rendered_do
