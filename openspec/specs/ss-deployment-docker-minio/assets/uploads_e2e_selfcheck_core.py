from __future__ import annotations

import json
import os
import socket
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class ComposeConfig:
    project_name: str
    compose_file: Path
    env_file: Path


def die(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def run(cmd: list[str], *, env: dict[str, str] | None = None) -> str:
    try:
        completed = subprocess.run(
            cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            env=env,
        )
        return completed.stdout
    except subprocess.CalledProcessError as exc:
        raise SystemExit(f"ERROR: command failed: {' '.join(cmd)}\n{exc.stdout}") from exc


def compose(compose_cfg: ComposeConfig, args: list[str]) -> str:
    env = dict(os.environ)
    env["SS_DOCKER_ENV_FILE"] = str(compose_cfg.env_file)
    cmd = [
        "docker",
        "compose",
        "--project-name",
        compose_cfg.project_name,
        "-f",
        str(compose_cfg.compose_file),
        "--env-file",
        str(compose_cfg.env_file),
        *args,
    ]
    return run(cmd, env=env)


def env_value(env_file: Path, key: str, default: str) -> str:
    if not env_file.exists():
        return default
    for line in env_file.read_text(encoding="utf-8").splitlines():
        if line.startswith(f"{key}="):
            return line.split("=", 1)[1].strip()
    return default


def assert_resolvable_endpoint(endpoint: str) -> None:
    parsed = urllib.parse.urlparse(endpoint)
    host = parsed.hostname
    if host is None or host.strip() == "":
        die(f"invalid SS_UPLOAD_S3_ENDPOINT: {endpoint}")
    try:
        socket.gethostbyname(host)
    except OSError as exc:
        message = (
            "ERROR: SS_UPLOAD_S3_ENDPOINT host is not resolvable from this machine.\n\n"
            "For Linux hosts, if you keep the default "
            "`http://host.docker.internal:9000`, add a hosts entry:\n"
            "  127.0.0.1 host.docker.internal\n"
        )
        raise SystemExit(message) from exc


def http_json(
    *,
    method: str,
    url: str,
    token: str | None = None,
    payload: dict[str, Any] | None = None,
    timeout_seconds: int = 30,
) -> dict[str, Any]:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token is not None:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=timeout_seconds) as resp:
            raw = resp.read()
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        body = raw.decode("utf-8", "replace")
        raise SystemExit(f"ERROR: HTTP {exc.code} {method} {url}\n{body}") from exc
    if raw.strip() == b"":
        return {}
    return json.loads(raw.decode("utf-8"))


def put_bytes(*, url: str, data: bytes, timeout_seconds: int = 120) -> str | None:
    req = urllib.request.Request(url, data=data, method="PUT")
    try:
        with urllib.request.urlopen(req, timeout=timeout_seconds) as resp:
            return resp.headers.get("ETag")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        raise SystemExit(f"ERROR: HTTP {exc.code} PUT {url}\n{body}") from exc


def wait_for_live(*, base_url: str, timeout_seconds: int = 90) -> None:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        try:
            http_json(method="GET", url=f"{base_url}/health/live")
            return
        except SystemExit:
            time.sleep(1)
    die(f"SS /health/live did not become ready at {base_url}")


def make_csv(path: Path, *, target_bytes: int) -> None:
    with path.open("w", encoding="utf-8") as f:
        f.write("x,y\n")
        i = 0
        while f.tell() < target_bytes:
            f.write(f"{i},{i+1}\n")
            i += 1


def write_env_with_multipart_threshold(*, base_env_file: Path, dst_env_file: Path) -> None:
    lines = base_env_file.read_text(encoding="utf-8").splitlines()
    updated: list[str] = []
    found = False
    for line in lines:
        if line.startswith("SS_UPLOAD_MULTIPART_THRESHOLD_BYTES="):
            updated.append("SS_UPLOAD_MULTIPART_THRESHOLD_BYTES=1")
            found = True
        else:
            updated.append(line)
    if not found:
        updated.append("SS_UPLOAD_MULTIPART_THRESHOLD_BYTES=1")
    dst_env_file.write_text("\n".join(updated) + "\n", encoding="utf-8")


def job_dir(job_id: str) -> str:
    return f"/var/lib/ss/jobs/{job_id}"


def read_container_json(compose_cfg: ComposeConfig, *, rel_path: str) -> dict[str, Any]:
    raw = compose(compose_cfg, ["exec", "-T", "ss", "sh", "-lc", f"cat {rel_path}"])
    return json.loads(raw)


def verify_inputs(
    *,
    base_url: str,
    compose_cfg: ComposeConfig,
    job_id: str,
    token: str,
    original_name: str,
) -> int:
    preview = http_json(
        method="GET",
        url=f"{base_url}/v1/jobs/{job_id}/inputs/preview?rows=5&columns=10",
        token=token,
    )
    row_count = preview.get("row_count")
    if not isinstance(row_count, int) or row_count < 1:
        die(f"inputs/preview unexpected: {preview}")

    job_json = read_container_json(compose_cfg, rel_path=f"{job_dir(job_id)}/job.json")
    inputs = job_json.get("inputs") or {}
    if inputs.get("manifest_rel_path") != "inputs/manifest.json":
        die(f"job.json inputs mismatch: {inputs}")
    fingerprint = inputs.get("fingerprint")
    if not isinstance(fingerprint, str) or not fingerprint.startswith("sha256:"):
        die(f"job.json fingerprint missing: {inputs}")

    manifest = read_container_json(compose_cfg, rel_path=f"{job_dir(job_id)}/inputs/manifest.json")
    if manifest.get("schema_version") != 2:
        die(f"manifest schema mismatch: {manifest}")
    datasets = manifest.get("datasets")
    if not isinstance(datasets, list) or len(datasets) != 1:
        die(f"manifest datasets mismatch: {manifest}")
    ds0 = datasets[0]
    if (
        ds0.get("original_name") != original_name
        or ds0.get("role") != "primary_dataset"
        or ds0.get("format") != "csv"
    ):
        die(f"manifest dataset mismatch: {ds0}")

    return row_count


def slice_part_bytes(*, file_path: Path, part_size: int, part_number: int) -> bytes:
    offset = (part_number - 1) * part_size
    with file_path.open("rb") as f:
        f.seek(offset)
        return f.read(part_size)
