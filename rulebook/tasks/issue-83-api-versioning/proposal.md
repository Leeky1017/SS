# Proposal: issue-83-api-versioning

## Why
The audit found that SS HTTP routes are unversioned and lack a deprecation policy, making it hard to introduce breaking changes safely while supporting existing clients during a transition window.

## What Changes
- Introduce explicit versioned routing under `/v1` for the current stable HTTP API surface.
- Keep the legacy unversioned routes available during a defined deprecation window.
- Add a deprecation mechanism for legacy routes via response headers (at least `Deprecation` and `Sunset`).
- Update OpenSpec to document the version lifecycle and support windows.
- Add tests to ensure `/v1` and legacy routes can coexist (and legacy routes emit deprecation headers).

## Impact
- Affected specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-api-surface/README.md`
  - `openspec/specs/ss-audit-remediation/task_cards/phase-2__api-versioning.md`
- Affected code:
  - `src/api/routes.py`
  - `src/main.py`
  - `tests/test_jobs_api.py`
  - `tests/test_artifacts_api.py`
  - `tests/test_graceful_shutdown.py`
- Breaking change: NO (legacy routes remain available during the deprecation window)
- User benefit: enables safe HTTP API evolution via explicit `/v1` and visible deprecation signals
