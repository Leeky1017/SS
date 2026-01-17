# Spec: ss-real-e2e-gate (Issue #503)

## Goal

Make “Windows production deploy is OK” mean “the real v1 user journey runs end-to-end with real dependencies (LLM + worker + Stata), and required artifacts are verifiable”, with sufficient evidence on failure to attribute the responsibility domain.

## Requirements

1. A repo-native command MUST exist to run a remote, black-box E2E flow against the Windows runtime API via SSH port-forwarding to `127.0.0.1:8000`.
2. The E2E flow MUST use only public HTTP endpoints and MUST execute the v1 journey:
   - `POST /v1/task-codes/redeem`
   - `POST /v1/jobs/{job_id}/inputs/upload`
   - `GET /v1/jobs/{job_id}/inputs/preview`
   - `GET /v1/jobs/{job_id}/draft/preview`
   - `POST /v1/jobs/{job_id}/draft/patch`
   - `POST /v1/jobs/{job_id}/confirm`
   - poll `GET /v1/jobs/{job_id}` until terminal
   - `GET /v1/jobs/{job_id}/artifacts` + download required files
3. The runner MUST verify artifacts:
   - On success: `stata.do`, `stata.log`, `run.meta.json` MUST be present and downloadable.
   - On failure: `run.error.json` MUST be present and downloaded first, and `stata.log` MUST be collected when present.
4. When the flow fails or times out, the runner MUST also collect remote diagnostics to local paths:
   - `schtasks /Query /TN "SS API"` and `schtasks /Query /TN "SS WORKER"`
   - queue depth under `C:\\SS_runtime\\queue\\queued` and `C:\\SS_runtime\\queue\\claimed`
   - tail of `C:\\SS_runtime\\deploy\\deploy-log.jsonl`
5. The runner MUST print a structured result suitable for gates:
   - include `job_id`, final `status`, and the local paths of downloaded artifacts/diagnostics
   - MUST NOT print or persist any bearer tokens / secrets (redact if present).
6. The release/deploy gate MUST be enforced with no dual-path:
   - post-switch validation MUST be this real E2E gate
   - health-only gating MUST not remain as an alternate success path.

## Scenarios

- When the Windows runtime is healthy and correctly configured, then the remote E2E runner reaches `succeeded` and verifies required artifacts.
- When the worker is stopped, then the runner surfaces “stuck queued” and prints schtasks + queue depth evidence.
- When Stata fails, then the runner downloads `run.error.json` + `stata.log` and prints their local paths.

