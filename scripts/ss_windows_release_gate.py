from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

from ss_ssh_e2e.errors import E2EError
from ss_windows_release_gate_support import recoverability_check, restart_remote_runtime

DEFAULT_HOST = "47.98.174.3"
DEFAULT_PORT = 22
DEFAULT_USER = "Administrator"
DEFAULT_IDENTITY_FILE = "/tmp/ss_codex_ed25519"

DEFAULT_SMOKE_PORT = 18000

DEFAULT_DEPLOY_SCRIPT = "/home/leeky/.codex/skills/ss-ssh-deploy/scripts/deploy.py"


def _utc_ts() -> str:
    return dt.datetime.now(dt.UTC).strftime("%Y%m%dT%H%M%SZ")


def _json_dumps(data: Any) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True)


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _run_capture(*, cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=str(cwd),
        text=True,
        capture_output=True,
        encoding="utf-8",
        errors="replace",
    )


def _require_file(path: Path, *, label: str) -> None:
    if path.is_file():
        return
    raise RuntimeError(f"{label} not found: {path}")


def _repo_root() -> Path:
    here = Path(__file__).resolve()
    repo_root = here.parents[1]
    return repo_root


def _deploy_cmd(*, args: argparse.Namespace, deploy_script: Path) -> list[str]:
    return [
        sys.executable,
        str(deploy_script),
        "--host",
        args.host,
        "--port",
        str(args.port),
        "--user",
        args.user,
        "--identity-file",
        args.identity_file,
        "--smoke-port",
        str(args.smoke_port),
    ]


def _rollback_cmd(*, args: argparse.Namespace, deploy_script: Path) -> list[str]:
    return [*_deploy_cmd(args=args, deploy_script=deploy_script), "--rollback"]


def _e2e_cmd(*, args: argparse.Namespace, repo_root: Path, out_dir: Path) -> list[str]:
    return [
        sys.executable,
        str(repo_root / "scripts" / "ss_ssh_e2e.py"),
        "--host",
        args.host,
        "--port",
        str(args.port),
        "--user",
        args.user,
        "--identity-file",
        args.identity_file,
        "--tenant-id",
        args.tenant_id,
        "--max-wait-seconds",
        str(args.max_wait_seconds),
        "--diagnose",
        "--out-dir",
        str(out_dir / "e2e"),
    ]


def _write_result(*, out_dir: Path, result: dict[str, Any]) -> None:
    _write_text(out_dir / "result.json", _json_dumps(result))
    print(_json_dumps(result))


def _init_result(*, out_dir: Path) -> dict[str, Any]:
    return {
        "ok": False,
        "out_dir": str(out_dir),
        "deploy": {"ok": False},
        "e2e": {"ok": False},
        "restart": {"attempted": False, "ok": None},
        "recoverability": {"attempted": False, "ok": None},
        "rollback": {"attempted": False, "ok": None},
    }


def _run_deploy(
    *, repo_root: Path, out_dir: Path, deploy_script: Path, args: argparse.Namespace
) -> subprocess.CompletedProcess[str]:
    deploy = _run_capture(cmd=_deploy_cmd(args=args, deploy_script=deploy_script), cwd=repo_root)
    _write_text(out_dir / "deploy.stdout.txt", deploy.stdout)
    _write_text(out_dir / "deploy.stderr.txt", deploy.stderr)
    return deploy


def _run_e2e(
    *, repo_root: Path, out_dir: Path, args: argparse.Namespace
) -> tuple[subprocess.CompletedProcess[str], dict[str, Any] | None]:
    e2e = _run_capture(cmd=_e2e_cmd(args=args, repo_root=repo_root, out_dir=out_dir), cwd=repo_root)
    _write_text(out_dir / "e2e.stdout.txt", e2e.stdout)
    _write_text(out_dir / "e2e.stderr.txt", e2e.stderr)
    if not e2e.stdout.strip():
        return e2e, None
    try:
        return e2e, json.loads(e2e.stdout)
    except json.JSONDecodeError:
        return e2e, None


def _run_rollback(
    *, repo_root: Path, out_dir: Path, deploy_script: Path, args: argparse.Namespace
) -> subprocess.CompletedProcess[str]:
    rollback = _run_capture(
        cmd=_rollback_cmd(args=args, deploy_script=deploy_script),
        cwd=repo_root,
    )
    _write_text(out_dir / "rollback.stdout.txt", rollback.stdout)
    _write_text(out_dir / "rollback.stderr.txt", rollback.stderr)
    return rollback


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="ss-windows-release-gate")
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--user", default=DEFAULT_USER)
    parser.add_argument("--identity-file", default=DEFAULT_IDENTITY_FILE)
    parser.add_argument("--smoke-port", type=int, default=DEFAULT_SMOKE_PORT)
    parser.add_argument("--tenant-id", default="e2e")
    parser.add_argument("--max-wait-seconds", type=int, default=600)
    parser.add_argument("--out-dir", default="")
    parser.add_argument("--deploy-script", default=DEFAULT_DEPLOY_SCRIPT)
    return parser


def _resolve_out_dir(value: str) -> Path:
    out_dir = Path(value) if value else Path("/tmp") / "ss_windows_release_gate" / _utc_ts()
    out_dir.mkdir(parents=True, exist_ok=True)
    return out_dir


def _validate_gate_inputs(*, args: argparse.Namespace, repo_root: Path) -> Path:
    deploy_script = Path(args.deploy_script)
    _require_file(deploy_script, label="deploy script")
    _require_file(Path(args.identity_file), label="ssh identity file")
    _require_file(repo_root / "scripts" / "ss_ssh_e2e.py", label="repo e2e runner")
    return deploy_script


def _run_restart_and_recoverability(
    *,
    result: dict[str, Any],
    out_dir: Path,
    args: argparse.Namespace,
    e2e_payload: dict[str, Any],
) -> bool:
    try:
        result["restart"] = restart_remote_runtime(
            out_dir=out_dir,
            user=str(args.user),
            host=str(args.host),
            port=int(args.port),
            identity_file=str(args.identity_file),
        )
    except (E2EError, OSError, RuntimeError) as e:
        result["restart"] = {"attempted": True, "ok": False, "error": str(e)}
        return False

    if not bool(result["restart"].get("ok")):
        return False
    try:
        result["recoverability"] = recoverability_check(
            out_dir=out_dir,
            user=str(args.user),
            host=str(args.host),
            port=int(args.port),
            identity_file=str(args.identity_file),
            tenant_id=str(args.tenant_id),
            task_code=str(e2e_payload.get("task_code", "")),
            expected_job_id=str(e2e_payload.get("job_id", "")),
            expected_terminal_status=str(e2e_payload.get("status", "")),
        )
    except (E2EError, OSError, RuntimeError) as e:
        result["recoverability"] = {"attempted": True, "ok": False, "error": str(e)}
        return False
    return bool(result["recoverability"].get("ok"))


def main(argv: list[str]) -> int:
    args = _build_parser().parse_args(argv)

    repo_root = _repo_root()
    deploy_script = _validate_gate_inputs(args=args, repo_root=repo_root)

    out_dir = _resolve_out_dir(args.out_dir)
    result = _init_result(out_dir=out_dir)

    deploy = _run_deploy(
        repo_root=repo_root,
        out_dir=out_dir,
        deploy_script=deploy_script,
        args=args,
    )
    result["deploy"] = {"ok": deploy.returncode == 0, "returncode": deploy.returncode}
    if deploy.returncode != 0:
        _write_result(out_dir=out_dir, result=result)
        return 1

    e2e, e2e_payload = _run_e2e(repo_root=repo_root, out_dir=out_dir, args=args)
    result["e2e"] = {"ok": e2e.returncode == 0, "returncode": e2e.returncode, "result": e2e_payload}

    if e2e.returncode == 0 and isinstance(e2e_payload, dict):
        if _run_restart_and_recoverability(
            result=result,
            out_dir=out_dir,
            args=args,
            e2e_payload=e2e_payload,
        ):
            result["ok"] = True
            _write_result(out_dir=out_dir, result=result)
            return 0
    if e2e.returncode == 0 and not isinstance(e2e_payload, dict):
        result["e2e"]["ok"] = False
        result["e2e"]["error"] = "missing_e2e_payload_json"

    result["rollback"]["attempted"] = True
    rollback = _run_rollback(
        repo_root=repo_root,
        out_dir=out_dir,
        deploy_script=deploy_script,
        args=args,
    )
    result["rollback"]["ok"] = rollback.returncode == 0
    _write_result(out_dir=out_dir, result=result)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
