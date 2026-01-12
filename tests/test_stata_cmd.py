from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path

import pytest

import src.infra.stata_cmd as stata_cmd_module
from src.infra.exceptions import SSError, StataCmdNotFoundError
from src.infra.stata_cmd import (
    _is_windows_stata_cmd,
    _validate_wsl_windows_interop,
    build_stata_batch_cmd,
    resolve_stata_cmd,
)


@dataclass(frozen=True)
class _ConfigStub:
    stata_cmd: tuple[str, ...]


def test_is_windows_stata_cmd_with_stata_exe_returns_true() -> None:
    assert _is_windows_stata_cmd(["C:/Program Files/Stata18/StataMP-64.exe"]) is True


def test_is_windows_stata_cmd_with_non_exe_returns_false() -> None:
    assert _is_windows_stata_cmd(["stata-mp"]) is False


def test_build_stata_batch_cmd_with_windows_stata_cmd_uses_e_flag() -> None:
    cmd = build_stata_batch_cmd(stata_cmd=["StataSE-64.exe"], do_filename="script.do")
    assert cmd == ["StataSE-64.exe", "/e", "do", "script.do"]


def test_build_stata_batch_cmd_with_posix_stata_cmd_uses_b_flag() -> None:
    cmd = build_stata_batch_cmd(stata_cmd=["stata"], do_filename="script.do")
    assert cmd == ["stata", "-b", "do", "script.do"]


def test_validate_wsl_windows_interop_with_non_windows_cmd_is_noop(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def _should_not_run(*_args: object, **_kwargs: object) -> subprocess.CompletedProcess[str]:
        raise AssertionError("subprocess.run should not be called")

    monkeypatch.setattr(stata_cmd_module.subprocess, "run", _should_not_run)
    monkeypatch.setenv("WSL_INTEROP", "1")

    _validate_wsl_windows_interop(stata_cmd=["stata"])


def test_validate_wsl_windows_interop_with_wsl_interop_unset_is_noop(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def _should_not_run(*_args: object, **_kwargs: object) -> subprocess.CompletedProcess[str]:
        raise AssertionError("subprocess.run should not be called")

    monkeypatch.setattr(stata_cmd_module.subprocess, "run", _should_not_run)
    monkeypatch.delenv("WSL_INTEROP", raising=False)

    _validate_wsl_windows_interop(stata_cmd=["StataSE-64.exe"])


def test_validate_wsl_windows_interop_with_cmd_exe_missing_is_noop(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def _should_not_run(*_args: object, **_kwargs: object) -> subprocess.CompletedProcess[str]:
        raise AssertionError("subprocess.run should not be called")

    monkeypatch.setattr(stata_cmd_module.subprocess, "run", _should_not_run)
    monkeypatch.setenv("WSL_INTEROP", "1")
    monkeypatch.setattr(Path, "is_file", lambda _self: False)

    _validate_wsl_windows_interop(stata_cmd=["StataSE-64.exe"])


def test_validate_wsl_windows_interop_when_cmd_exe_times_out_raises_sserror(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("WSL_INTEROP", "1")
    monkeypatch.setattr(Path, "is_file", lambda _self: True)

    def _timeout(*args: object, **kwargs: object) -> subprocess.CompletedProcess[str]:
        cmd = args[0] if args else []
        raise subprocess.TimeoutExpired(cmd=cmd, timeout=float(kwargs["timeout"]))

    monkeypatch.setattr(stata_cmd_module.subprocess, "run", _timeout)

    with pytest.raises(SSError) as excinfo:
        _validate_wsl_windows_interop(stata_cmd=["StataSE-64.exe"])

    assert excinfo.value.error_code == "WSL_INTEROP_UNAVAILABLE"


def test_validate_wsl_windows_interop_when_cmd_exe_raises_os_error_raises_sserror(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("WSL_INTEROP", "1")
    monkeypatch.setattr(Path, "is_file", lambda _self: True)

    def _os_error(*_args: object, **_kwargs: object) -> subprocess.CompletedProcess[str]:
        raise OSError("boom")

    monkeypatch.setattr(stata_cmd_module.subprocess, "run", _os_error)

    with pytest.raises(SSError) as excinfo:
        _validate_wsl_windows_interop(stata_cmd=["StataSE-64.exe"])

    assert excinfo.value.error_code == "WSL_INTEROP_UNAVAILABLE"
    assert "boom" in excinfo.value.message


def test_validate_wsl_windows_interop_when_cmd_exe_nonzero_raises_sserror(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("WSL_INTEROP", "1")
    monkeypatch.setattr(Path, "is_file", lambda _self: True)

    def _completed(
        *_args: object,
        **_kwargs: object,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(args=["cmd.exe"], returncode=1, stdout="", stderr="bad")

    monkeypatch.setattr(stata_cmd_module.subprocess, "run", _completed)

    with pytest.raises(SSError) as excinfo:
        _validate_wsl_windows_interop(stata_cmd=["StataSE-64.exe"])

    assert excinfo.value.error_code == "WSL_INTEROP_UNAVAILABLE"
    assert "cmd.exe exit 1" in excinfo.value.message
    assert "bad" in excinfo.value.message


def test_resolve_stata_cmd_with_configured_cmd_returns_list(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    called: dict[str, object] = {}

    def _validate(*, stata_cmd: list[str]) -> None:
        called["cmd"] = list(stata_cmd)

    monkeypatch.setattr(stata_cmd_module, "_validate_wsl_windows_interop", _validate)

    config = _ConfigStub(stata_cmd=("stata-mp",))
    assert resolve_stata_cmd(config) == ["stata-mp"]
    assert called["cmd"] == ["stata-mp"]


def test_resolve_stata_cmd_with_which_hit_returns_first_found(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def _which(_candidate: str) -> str | None:
        return "/usr/bin/stata"

    monkeypatch.setattr(stata_cmd_module.shutil, "which", _which)

    config = _ConfigStub(stata_cmd=())
    assert resolve_stata_cmd(config) == ["/usr/bin/stata"]


def test_resolve_stata_cmd_with_no_candidates_raises_not_found(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(stata_cmd_module.shutil, "which", lambda _c: None)
    monkeypatch.setattr(Path, "exists", lambda _self: False)

    config = _ConfigStub(stata_cmd=())
    with pytest.raises(StataCmdNotFoundError):
        resolve_stata_cmd(config)
