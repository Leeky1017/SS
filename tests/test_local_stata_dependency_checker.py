from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

import src.infra.local_stata_dependency_checker as checker_module
from src.domain.stata_dependency_checker import StataDependency
from src.domain.stata_runner import RunError
from src.infra.local_stata_dependency_checker import (
    LocalStataDependencyChecker,
    _is_safe_stata_name,
    _preflight_do_file,
    _read_missing_packages_or_error,
    _run_preflight_or_error,
    _split_dependencies,
    _write_preflight_files,
)


def test_is_safe_stata_name_with_valid_identifier_returns_true() -> None:
    assert _is_safe_stata_name("reghdfe") is True


def test_is_safe_stata_name_with_leading_digit_returns_false() -> None:
    assert _is_safe_stata_name("1bad") is False


def test_preflight_do_file_with_packages_includes_out_filename_and_foreach_loop() -> None:
    content = _preflight_do_file(packages=["reghdfe", "estout"], out_filename="missing.txt")

    assert 'file open fh using "missing.txt", write text replace' in content
    assert "foreach pkg in reghdfe estout {" in content


def test_split_dependencies_with_invalid_and_ignored_sources_returns_expected_lists() -> None:
    deps = (
        StataDependency(pkg="reghdfe", source="ssc"),
        StataDependency(pkg="1bad", source="ssc"),
        StataDependency(pkg="ignored", source="github"),
    )

    to_check, invalid = _split_dependencies(deps)

    assert [d.pkg for d in to_check] == ["reghdfe"]
    assert [d.pkg for d in invalid] == ["1bad"]


def test_write_preflight_files_with_valid_dir_writes_do_file_and_returns_out_path(
    tmp_path: Path,
) -> None:
    do_filename, out_path, error = _write_preflight_files(work_dir=tmp_path, packages=["reghdfe"])

    assert error is None
    assert out_path == tmp_path / "dependency_preflight.missing.txt"
    assert (tmp_path / do_filename).is_file()
    assert "foreach pkg in reghdfe {" in (tmp_path / do_filename).read_text(encoding="utf-8")


def test_write_preflight_files_when_write_fails_returns_run_error(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
) -> None:
    def _raise_os_error(*_args: object, **_kwargs: object) -> str:
        raise OSError("nope")

    monkeypatch.setattr(Path, "write_text", _raise_os_error)

    _, _, error = _write_preflight_files(work_dir=tmp_path, packages=["reghdfe"])

    assert error is not None
    assert error.error_code == "STATA_DEPENDENCY_PREFLIGHT_WRITE_FAILED"
    assert "nope" in error.message


def test_run_preflight_or_error_with_successful_subprocess_returns_none(tmp_path: Path) -> None:
    seen: dict[str, object] = {}

    def _runner(cmd: list[str], **kwargs: object) -> subprocess.CompletedProcess[str]:
        seen["cmd"] = cmd
        seen["cwd"] = kwargs.get("cwd")
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="", stderr="")

    error = _run_preflight_or_error(
        work_dir=tmp_path,
        stata_cmd=["stata"],
        do_filename="preflight.do",
        subprocess_runner=_runner,
        timeout_seconds=1,
    )

    assert error is None
    assert seen["cmd"] == ["stata", "-b", "do", "preflight.do"]
    assert seen["cwd"] == str(tmp_path)


def test_run_preflight_or_error_with_nonzero_exit_code_returns_run_error(tmp_path: Path) -> None:
    def _runner(cmd: list[str], **_kwargs: object) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(args=cmd, returncode=7, stdout="", stderr="")

    error = _run_preflight_or_error(
        work_dir=tmp_path,
        stata_cmd=["stata"],
        do_filename="preflight.do",
        subprocess_runner=_runner,
        timeout_seconds=1,
    )

    assert error is not None
    assert error.error_code == "STATA_DEPENDENCY_PREFLIGHT_FAILED"


def test_run_preflight_or_error_when_timeout_returns_run_error(tmp_path: Path) -> None:
    def _runner(cmd: list[str], **kwargs: object) -> subprocess.CompletedProcess[str]:
        raise subprocess.TimeoutExpired(cmd=cmd, timeout=float(kwargs["timeout"]))

    error = _run_preflight_or_error(
        work_dir=tmp_path,
        stata_cmd=["stata"],
        do_filename="preflight.do",
        subprocess_runner=_runner,
        timeout_seconds=1,
    )

    assert error is not None
    assert error.error_code == "STATA_DEPENDENCY_PREFLIGHT_TIMEOUT"


def test_run_preflight_or_error_when_os_error_returns_run_error(tmp_path: Path) -> None:
    def _runner(_cmd: list[str], **_kwargs: object) -> subprocess.CompletedProcess[str]:
        raise OSError("boom")

    error = _run_preflight_or_error(
        work_dir=tmp_path,
        stata_cmd=["stata"],
        do_filename="preflight.do",
        subprocess_runner=_runner,
        timeout_seconds=1,
    )

    assert error is not None
    assert error.error_code == "STATA_DEPENDENCY_PREFLIGHT_SUBPROCESS_FAILED"
    assert "boom" in error.message


def test_read_missing_packages_or_error_when_file_missing_returns_empty_set(tmp_path: Path) -> None:
    missing, error = _read_missing_packages_or_error(path=tmp_path / "does_not_exist.txt")

    assert missing == set()
    assert error is None


def test_read_missing_packages_or_error_with_lines_returns_set(tmp_path: Path) -> None:
    path = tmp_path / "missing.txt"
    path.write_text("reghdfe\n\nestout\n", encoding="utf-8")

    missing, error = _read_missing_packages_or_error(path=path)

    assert error is None
    assert missing == {"reghdfe", "estout"}


def test_read_missing_packages_or_error_when_read_fails_returns_run_error(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
) -> None:
    path = tmp_path / "missing.txt"
    path.write_text("reghdfe\n", encoding="utf-8")

    def _raise_os_error(*_args: object, **_kwargs: object) -> str:
        raise OSError("nope")

    monkeypatch.setattr(Path, "read_text", _raise_os_error)

    missing, error = _read_missing_packages_or_error(path=path)

    assert missing == set()
    assert error is not None
    assert error.error_code == "STATA_DEPENDENCY_PREFLIGHT_READ_FAILED"


def test_local_stata_dependency_checker_check_with_no_dependencies_returns_empty_result(
    tmp_path: Path,
) -> None:
    checker = LocalStataDependencyChecker(jobs_dir=tmp_path, stata_cmd=["stata"])

    result = checker.check(job_id="job_123", run_id="run_1", dependencies=())

    assert result.error is None
    assert result.missing == ()


def test_local_stata_dependency_checker_check_with_invalid_workspace_returns_error(
    tmp_path: Path,
) -> None:
    checker = LocalStataDependencyChecker(jobs_dir=tmp_path, stata_cmd=["stata"])

    result = checker.check(
        job_id="bad/id",
        run_id="run_1",
        dependencies=(StataDependency(pkg="reghdfe", source="ssc"),),
    )

    assert result.error is not None
    assert result.error.error_code == "STATA_WORKSPACE_INVALID"


def test_local_stata_dependency_checker_check_with_missing_packages_returns_missing_list(
    tmp_path: Path,
) -> None:
    def _runner(cmd: list[str], cwd: str, **_kwargs: object) -> subprocess.CompletedProcess[str]:
        Path(cwd, "dependency_preflight.missing.txt").write_text("reghdfe\n", encoding="utf-8")
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="", stderr="")

    checker = LocalStataDependencyChecker(
        jobs_dir=tmp_path,
        stata_cmd=["stata"],
        subprocess_runner=_runner,
    )

    result = checker.check(
        job_id="job_123",
        run_id="run_1",
        dependencies=(
            StataDependency(pkg="1bad", source="ssc"),
            StataDependency(pkg="reghdfe", source="ssc"),
        ),
    )

    assert result.error is None
    assert [d.pkg for d in result.missing] == ["1bad", "reghdfe"]


def test_local_stata_dependency_checker_check_when_preflight_fails_returns_error(
    tmp_path: Path,
) -> None:
    def _runner(cmd: list[str], **_kwargs: object) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(args=cmd, returncode=2, stdout="", stderr="")

    checker = LocalStataDependencyChecker(
        jobs_dir=tmp_path,
        stata_cmd=["stata"],
        subprocess_runner=_runner,
    )

    result = checker.check(
        job_id="job_123",
        run_id="run_1",
        dependencies=(StataDependency(pkg="reghdfe", source="ssc"),),
    )

    assert result.error is not None
    assert result.error.error_code == "STATA_DEPENDENCY_PREFLIGHT_FAILED"


def test_local_stata_dependency_checker_check_when_write_preflight_returns_error(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
) -> None:
    def _write_error(
        *,
        work_dir: Path,
        packages: list[str],
    ) -> tuple[str, Path, RunError | None]:
        return (
            "dependency_preflight.do",
            work_dir / "dependency_preflight.missing.txt",
            RunError(error_code="STATA_DEPENDENCY_PREFLIGHT_WRITE_FAILED", message="boom"),
        )

    monkeypatch.setattr(checker_module, "_write_preflight_files", _write_error)

    checker = LocalStataDependencyChecker(jobs_dir=tmp_path, stata_cmd=["stata"])

    result = checker.check(
        job_id="job_123",
        run_id="run_1",
        dependencies=(StataDependency(pkg="reghdfe", source="ssc"),),
    )

    assert result.error is not None
    assert result.error.error_code == "STATA_DEPENDENCY_PREFLIGHT_WRITE_FAILED"


def test_local_stata_dependency_checker_check_when_read_missing_returns_error(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
) -> None:
    def _read_error(*, path: Path) -> tuple[set[str], RunError | None]:
        return set(), RunError(error_code="STATA_DEPENDENCY_PREFLIGHT_READ_FAILED", message="boom")

    monkeypatch.setattr(checker_module, "_read_missing_packages_or_error", _read_error)

    def _runner(cmd: list[str], **_kwargs: object) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="", stderr="")

    checker = LocalStataDependencyChecker(
        jobs_dir=tmp_path,
        stata_cmd=["stata"],
        subprocess_runner=_runner,
    )

    result = checker.check(
        job_id="job_123",
        run_id="run_1",
        dependencies=(StataDependency(pkg="reghdfe", source="ssc"),),
    )

    assert result.error is not None
    assert result.error.error_code == "STATA_DEPENDENCY_PREFLIGHT_READ_FAILED"
