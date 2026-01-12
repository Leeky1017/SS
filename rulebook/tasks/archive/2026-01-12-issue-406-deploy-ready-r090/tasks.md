## 1. Implementation
- [x] 1.1 Update `openspec/specs/ss-deployment-docker-readiness/spec.md` with Windows + Docker Desktop (WSL2) scenario + `SS_STATA_CMD` example.
- [x] 1.2 Update `docker-compose.yml` to support Windows-path `SS_STATA_CMD` injection (spaces-safe).
- [x] 1.3 Update gate task card `openspec/specs/ss-deployment-docker-readiness/task_cards/gate__DEPLOY-READY-R090.md` for Windows scenario + acceptance items.
- [x] 1.4 Create/update run log `openspec/_ops/task_runs/ISSUE-406.md` (plan + evidence, append-only Runs).
- [x] 1.5 Persist `output_formats` when triggering a run (restart-safe).
- [x] 1.6 Add missing template params mapping for `T07` (`__NUMERIC_VARS__`).
- [x] 1.7 Regenerate `requirements.txt` via `pip-compile` (ensures `docx`/`pdf` deps in prod image).
- [x] 1.8 Add regression tests for `output_formats` persistence and `T07` template params.

## 2. Testing
- [x] 2.1 `docker-compose up -d` and verify `minio`, `ss-api`, `ss-worker` are healthy.
- [x] 2.2 Run `/v1` journey end-to-end (redeem/upload/draft/freeze/run/poll/artifacts/download) and verify output formats.
- [x] 2.3 `docker-compose restart ss-api ss-worker` and verify job/artifacts recovery + redeem idempotency.

## 3. Documentation
- [x] 3.1 Record key commands + key outputs + verdict in `openspec/_ops/task_runs/ISSUE-406.md`.
- [x] 3.2 Update task card completion section with PR + run log evidence after PR is opened.
