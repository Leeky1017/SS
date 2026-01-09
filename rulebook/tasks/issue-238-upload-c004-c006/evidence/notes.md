# Notes: issue-238-upload-c004-c006

## Decisions
- Use a job-scoped file lock for upload-sessions state + finalize to guarantee strong idempotency and prevent `inputs/manifest.json` lost updates under concurrent finalize.
- Store upload session id as `usv1.<job_id>.<random>` so refresh/finalize can locate the job without a global index.

## Stress/bench plan (manual, non-CI)
- Concurrency dimensions:
  - Create upload sessions: N=50/100 concurrent calls.
  - Finalize: N=20 concurrent calls (same session id) + N=20 (different session ids) to probe manifest update races.
  - Multipart: vary `part_count` (2/8/64) and `part_size` (min/default/max).
- Metrics:
  - P50/P95 latency per endpoint.
  - Failure rate + retry rate (notably `CHECKSUM_MISMATCH`).
  - CPU/IO (coarse: `time`, `top`, or container stats).
- Evidence recording:
  - Commands + key outputs appended to `openspec/_ops/task_runs/ISSUE-238.md`.
