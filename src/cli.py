from __future__ import annotations

import argparse

from src.cli_run_template import cmd_run_template
from src.cli_smoke_suite import cmd_run_smoke_suite
from src.cli_templates import cmd_list_templates
from src.config import load_config
from src.infra.logging_config import configure_logging


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="ss")
    sub = parser.add_subparsers(dest="cmd", required=True)

    list_cmd = sub.add_parser("list-templates", help="List template ids")
    list_cmd.add_argument("--limit", type=int, default=50)

    run_cmd = sub.add_parser(
        "run-template",
        help="Run a template end-to-end (generate do-file, run Stata, archive artifacts)",
    )
    run_cmd.add_argument("--template-id", required=True)
    run_cmd.add_argument("--param", action="append", default=[])
    run_cmd.add_argument("--timeout-seconds", type=int, default=300)
    run_cmd.add_argument("--input-csv")
    run_cmd.add_argument("--sample-data", action="store_true")

    smoke_cmd = sub.add_parser(
        "run-smoke-suite",
        help="Run Stata 18 smoke suite and write a structured JSON report",
    )
    smoke_cmd.add_argument("--manifest", help="Path to smoke-suite manifest JSON")
    smoke_cmd.add_argument("--report-path", default="smoke_suite_report.json")
    smoke_cmd.add_argument("--timeout-seconds", type=int, default=300)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    config = load_config()
    configure_logging(log_level=config.log_level)

    if args.cmd == "list-templates":
        return cmd_list_templates(
            library_dir=config.do_template_library_dir,
            limit=int(args.limit),
        )

    if args.cmd == "run-smoke-suite":
        return cmd_run_smoke_suite(
            config=config,
            manifest_arg=str(args.manifest) if args.manifest is not None else None,
            report_path=str(args.report_path),
            timeout_seconds=int(args.timeout_seconds),
        )

    if args.cmd == "run-template":
        return cmd_run_template(
            config=config,
            template_id=str(args.template_id),
            param=list(args.param),
            timeout_seconds=int(args.timeout_seconds),
            input_csv=str(args.input_csv) if args.input_csv is not None else None,
            sample_data=bool(args.sample_data),
        )

    return 2


if __name__ == "__main__":
    raise SystemExit(main())
