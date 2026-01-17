from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Any

from ss_ssh_e2e.diagnostics import ps
from ss_ssh_e2e.errors import write_text
from ss_ssh_e2e.tunnel import ssh_base_args


def restart_remote_runtime(
    *,
    out_dir: Path,
    user: str,
    host: str,
    port: int,
    identity_file: str,
) -> dict[str, Any]:
    cmd = ps(
        "$tasks=@('SS API','SS WORKER');"
        "$failed=$false;"
        "foreach($t in $tasks){"
        "  & schtasks /End /TN $t | Out-String | Write-Host;"
        "  if ($LASTEXITCODE -ne 0) { $failed=$true };"
        "  Start-Sleep -Seconds 1;"
        "  & schtasks /Run /TN $t | Out-String | Write-Host;"
        "  if ($LASTEXITCODE -ne 0) { $failed=$true };"
        "}"
        "if ($failed) { exit 1 } else { exit 0 }"
    )
    ssh_cmd = [
        "ssh",
        *ssh_base_args(identity_file=identity_file, port=port),
        f"{user}@{host}",
        cmd,
    ]
    proc = subprocess.run(
        ssh_cmd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    evidence_path = out_dir / "restart.remote.txt"
    write_text(evidence_path, f"STDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}")
    ok = proc.returncode == 0
    result: dict[str, Any] = {
        "attempted": True,
        "ok": ok,
        "returncode": proc.returncode,
        "evidence": {"restart.remote.txt": str(evidence_path)},
    }
    if not ok:
        result["error"] = "restart_failed"
    return result
