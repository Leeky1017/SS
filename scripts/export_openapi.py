from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


def _ensure_minimal_env_for_openapi_export() -> None:
    os.environ.setdefault("SS_ENV", "development")
    os.environ.setdefault("SS_LLM_PROVIDER", "yunwu")
    os.environ.setdefault("SS_LLM_API_KEY", "test-key")


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Export SS FastAPI OpenAPI spec as JSON.")
    parser.add_argument(
        "--out",
        type=str,
        required=True,
        help="Output JSON path (use '-' for stdout).",
    )
    return parser


def main() -> int:
    args = _build_parser().parse_args()

    _ensure_minimal_env_for_openapi_export()
    from src.main import create_app

    app = create_app()
    spec = app.openapi()

    payload = json.dumps(spec, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if args.out == "-":
        print(payload, end="")
        return 0

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(payload, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

