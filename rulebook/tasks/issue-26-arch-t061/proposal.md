# Proposal: issue-26-arch-t061

## Why
Make SS logs diagnosable and machine-parsable by standardizing event codes + required context
fields, and ensure all entrypoints configure logging from `src/config.py` (no scattered env reads).

## What Changes
- Add a shared logging initializer that configures JSON structured logs with stable keys.
- Wire `src/main.py`, `src/worker.py`, and `src/cli.py` to use the initializer and `Config.log_level`.
- Add unit tests to protect the logging contract (required keys always present).

## Impact
- Affected specs: `openspec/specs/ss-observability/spec.md`, `openspec/specs/ss-constitution/01-principles.md`
- Affected code: `src/infra/logging_config.py`, `src/main.py`, `src/worker.py`, `src/cli.py`, `tests/*`
- Breaking change: NO
- User benefit: Consistent, queryable logs across API/worker/CLI with required context keys.
