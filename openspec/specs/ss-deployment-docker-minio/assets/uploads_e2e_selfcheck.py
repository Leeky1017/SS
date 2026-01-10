#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import tempfile
from pathlib import Path

from uploads_e2e_selfcheck_core import (
    ComposeConfig,
    assert_resolvable_endpoint,
    compose,
    die,
    env_value,
    make_csv,
    run,
    wait_for_live,
    write_env_with_multipart_threshold,
)
from uploads_e2e_selfcheck_flows import direct_flow, multipart_flow


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Docker + MinIO uploads E2E self-check (direct + multipart).",
        epilog=(
            "Multipart ETag note: each part PUT returns an ETag header; pass it back to finalize as {part_number, etag}.\n"
            "Manual example:\n"
            "  curl -sS -o /dev/null -D headers.txt -X PUT --data-binary @part.bin \"$PRESIGNED_URL\"\n"
            "  grep -i '^etag:' headers.txt"
        ),
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("--project-name", default=os.environ.get("SS_SELFTEST_PROJECT_NAME", "ss-minio-selfcheck"))
    parser.add_argument("--env-file", default=os.environ.get("SS_SELFTEST_ENV_FILE", str(Path(".env").resolve())))
    parser.add_argument("--api-base-url", default=os.environ.get("SS_SELFTEST_API_BASE_URL", ""))
    return parser.parse_args()


def _ensure_env_file(env_file: Path, *, assets_dir: Path) -> None:
    if env_file.exists():
        return
    example = assets_dir / ".env.example"
    die(f"missing env file: {env_file} (copy {example} -> {assets_dir / '.env'})")


def _run_selfcheck(*, base_url: str, base_env_file: Path, compose_file: Path, project_name: str) -> None:
    compose_direct = ComposeConfig(project_name=project_name, compose_file=compose_file, env_file=base_env_file)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        direct_file = tmp_dir / "direct.csv"
        make_csv(direct_file, target_bytes=64)

        print(f"Starting docker compose project: {compose_direct.project_name}")
        compose(compose_direct, ["up", "-d"])
        wait_for_live(base_url=base_url)
        direct_flow(base_url=base_url, compose_cfg=compose_direct, file_path=direct_file)

        print("Restarting stack with SS_UPLOAD_MULTIPART_THRESHOLD_BYTES=1")
        compose(compose_direct, ["down"])
        multipart_env_file = tmp_dir / ".env.multipart"
        write_env_with_multipart_threshold(base_env_file=base_env_file, dst_env_file=multipart_env_file)

        part_size = int(env_value(multipart_env_file, "SS_UPLOAD_MULTIPART_PART_SIZE_BYTES", "8388608"))
        multipart_file = tmp_dir / "multipart.csv"
        make_csv(multipart_file, target_bytes=part_size + 1024)

        compose_multipart = ComposeConfig(project_name=project_name, compose_file=compose_file, env_file=multipart_env_file)
        compose(compose_multipart, ["up", "-d"])
        wait_for_live(base_url=base_url)
        multipart_flow(base_url=base_url, compose_cfg=compose_multipart, file_path=multipart_file)


def main() -> int:
    args = _parse_args()
    assets_dir = Path(__file__).resolve().parent
    base_env_file = Path(args.env_file).resolve()
    _ensure_env_file(base_env_file, assets_dir=assets_dir)

    run(["docker", "compose", "version"])
    compose_file = assets_dir / "docker-compose.yml"

    api_port = env_value(base_env_file, "SS_API_PORT", "8000")
    base_url = args.api_base_url.strip() or f"http://127.0.0.1:{api_port}"

    s3_endpoint = env_value(base_env_file, "SS_UPLOAD_S3_ENDPOINT", "")
    if s3_endpoint.strip() == "":
        die(f"SS_UPLOAD_S3_ENDPOINT missing in {base_env_file}")
    assert_resolvable_endpoint(s3_endpoint)

    _run_selfcheck(
        base_url=base_url,
        base_env_file=base_env_file,
        compose_file=compose_file,
        project_name=args.project_name,
    )
    print("DONE. To stop containers:")
    print(f"  docker compose --project-name {args.project_name} -f {compose_file} --env-file {base_env_file} down")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

