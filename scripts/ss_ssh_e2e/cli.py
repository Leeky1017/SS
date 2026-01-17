from __future__ import annotations

import argparse
import contextlib
import subprocess
from pathlib import Path
from typing import Any

from ss_ssh_e2e.diagnostics import collect_remote_diagnostics
from ss_ssh_e2e.errors import E2EError, json_dumps, redact, utc_ts, write_text
from ss_ssh_e2e.flow import require_httpx, run_flow
from ss_ssh_e2e.tunnel import pick_free_port, ssh_tunnel

DEFAULT_HOST = "47.98.174.3"
DEFAULT_PORT = 22
DEFAULT_USER = "Administrator"
DEFAULT_IDENTITY_FILE = "/tmp/ss_codex_ed25519"

DEFAULT_REMOTE_API_HOST = "127.0.0.1"
DEFAULT_REMOTE_API_PORT = 8000

DEFAULT_TENANT_ID = "e2e"

DEFAULT_POLL_INTERVAL_SECONDS = 2.0
DEFAULT_MAX_WAIT_SECONDS = 600.0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="ss-ssh-e2e")
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--user", default=DEFAULT_USER)
    parser.add_argument("--identity-file", default=DEFAULT_IDENTITY_FILE)

    parser.add_argument("--remote-api-host", default=DEFAULT_REMOTE_API_HOST)
    parser.add_argument("--remote-api-port", type=int, default=DEFAULT_REMOTE_API_PORT)
    parser.add_argument("--local-port", type=int, default=0)
    parser.add_argument("--tunnel-ready-timeout-seconds", type=float, default=10.0)

    parser.add_argument("--tenant-id", default=DEFAULT_TENANT_ID)
    parser.add_argument("--http-timeout-seconds", type=float, default=120.0)
    parser.add_argument(
        "--poll-interval-seconds",
        type=float,
        default=DEFAULT_POLL_INTERVAL_SECONDS,
    )
    parser.add_argument("--max-wait-seconds", type=float, default=DEFAULT_MAX_WAIT_SECONDS)

    parser.add_argument("--task-code", default="")
    parser.add_argument("--requirement", default="")
    parser.add_argument("--ignore-unhealthy", action="store_true")
    parser.add_argument("--diagnose", action="store_true")
    parser.add_argument("--out-dir", default="")
    return parser


def resolve_out_dir(value: str) -> Path:
    if value:
        out_dir = Path(value)
        out_dir.mkdir(parents=True, exist_ok=True)
        return out_dir
    out_dir = Path("/tmp") / "ss_real_e2e" / utc_ts()
    out_dir.mkdir(parents=True, exist_ok=True)
    return out_dir


def run(*, args: argparse.Namespace, out_dir: Path) -> tuple[dict[str, Any], int]:
    key = Path(args.identity_file)
    if not key.is_file():
        raise E2EError(
            event_code="SSE2E_LOCAL_KEY_MISSING",
            message=f"identity file not found: {key}",
        )

    httpx = require_httpx()
    local_port = int(args.local_port) if int(args.local_port) != 0 else pick_free_port()
    base_url = f"http://127.0.0.1:{local_port}"

    task_code = args.task_code or f"tc_real_e2e_{utc_ts()}"
    requirement = args.requirement or (
        "real e2e audit: upload->preview->draft->patch->plan/freeze->run->artifacts"
    )

    with ssh_tunnel(
        user=args.user,
        host=args.host,
        port=args.port,
        identity_file=args.identity_file,
        local_port=local_port,
        remote_host=args.remote_api_host,
        remote_port=args.remote_api_port,
        ready_timeout_seconds=args.tunnel_ready_timeout_seconds,
    ):
        flow = run_flow(
            httpx=httpx,
            base_url=base_url,
            out_dir=out_dir,
            tenant_id=args.tenant_id,
            task_code=task_code,
            requirement=requirement,
            ignore_unhealthy=bool(args.ignore_unhealthy),
            http_timeout_seconds=float(args.http_timeout_seconds),
            poll_interval_seconds=float(args.poll_interval_seconds),
            max_wait_seconds=float(args.max_wait_seconds),
        )

    ok = flow.get("status") == "succeeded"
    result = {"ok": ok, "event_code": "SSE2E_DONE", "out_dir": str(out_dir), **flow}
    return result, (0 if ok else 2)


def main(argv: list[str]) -> int:
    args = build_parser().parse_args(argv)
    out_dir = resolve_out_dir(args.out_dir)
    result: dict[str, Any] = {
        "ok": False,
        "event_code": "SSE2E_UNKNOWN",
        "job_id": None,
        "status": None,
        "out_dir": str(out_dir),
    }
    exit_code = 1

    try:
        result, exit_code = run(args=args, out_dir=out_dir)
    except E2EError as e:
        result.update(
            {
                "ok": False,
                "event_code": e.event_code,
                "message": str(e),
                "details": redact(e.details),
            }
        )
    except (OSError, subprocess.SubprocessError) as e:
        result.update({"ok": False, "event_code": "SSE2E_LOCAL_ERROR", "message": str(e)})

    if args.diagnose or not bool(result.get("ok")):
        with contextlib.suppress(E2EError):
            result["remote_diagnostics"] = collect_remote_diagnostics(
                user=args.user,
                host=args.host,
                port=args.port,
                identity_file=args.identity_file,
                out_dir=out_dir,
            )

    write_text(out_dir / "result.json", json_dumps(redact(result)))
    print(json_dumps(redact(result)))
    return exit_code
