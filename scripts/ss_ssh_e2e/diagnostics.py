from __future__ import annotations

import subprocess
from pathlib import Path

from ss_ssh_e2e.errors import E2EError, write_text
from ss_ssh_e2e.tunnel import ssh_base_args


def ssh_capture(*, user: str, host: str, port: int, identity_file: str, remote_cmd: str) -> str:
    cmd = [
        "ssh",
        *ssh_base_args(identity_file=identity_file, port=port),
        f"{user}@{host}",
        remote_cmd,
    ]
    try:
        out = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except subprocess.CalledProcessError as e:
        raise E2EError(
            event_code="SSE2E_REMOTE_DIAG_FAILED",
            message=f"remote diag failed (exit={e.returncode})",
        ) from e
    return out.stdout


def ps(cmd: str) -> str:
    escaped = cmd.replace('"', '\\"')
    return f'powershell -NoProfile -Command "{escaped}"'


def collect_remote_diagnostics(
    *,
    user: str,
    host: str,
    port: int,
    identity_file: str,
    out_dir: Path,
) -> dict[str, str]:
    diag_dir = out_dir / "diagnostics"
    sections: list[tuple[str, str]] = [
        ("schtasks_api", ps("schtasks /Query /TN 'SS API' /FO LIST /V")),
        ("schtasks_worker", ps("schtasks /Query /TN 'SS WORKER' /FO LIST /V")),
        (
            "queue_depth",
            ps(
                "$q='C:\\SS_runtime\\queue';"
                "$queued=(Get-ChildItem -Path (Join-Path $q 'queued') -Filter '*.json' -Recurse "
                "-File -ErrorAction SilentlyContinue | Measure-Object).Count;"
                "$claimed=(Get-ChildItem -Path (Join-Path $q 'claimed') -Filter '*.json' -Recurse "
                "-File -ErrorAction SilentlyContinue | Measure-Object).Count;"
                "Write-Host ('queued=' + $queued + ' claimed=' + $claimed)"
            ),
        ),
        (
            "deploy_log_tail",
            ps(
                "if (Test-Path 'C:\\SS_runtime\\deploy\\deploy-log.jsonl') "
                "{ Get-Content -Path 'C:\\SS_runtime\\deploy\\deploy-log.jsonl' -Tail 60 } "
                "else { Write-Host 'deploy-log.jsonl missing' }"
            ),
        ),
    ]

    paths: dict[str, str] = {}
    for name, cmd in sections:
        try:
            out = ssh_capture(
                user=user,
                host=host,
                port=port,
                identity_file=identity_file,
                remote_cmd=cmd,
            )
        except E2EError as e:
            out = f"{e}\n"
        path = diag_dir / f"{name}.txt"
        write_text(path, out)
        paths[name] = str(path)
    return paths

