# Migration: file worker queue → production queue backend

## Preconditions

- JobStore backend decision exists and is configured via `src/config.py`: `openspec/specs/ss-job-store/decision.md`
- Queue correctness invariants remain unchanged:
  - single-claimer semantics
  - reclaim on lease expiry
  - bounded retries

## Target architecture

- Dev / single-node: `FileWorkerQueue`
- Production: PostgreSQL-backed queue (default), with optional Redis/RabbitMQ as future scale-up backends

## PostgreSQL queue design sketch

Minimal table (illustrative):

- `queue_entries`
  - `job_id` (PK)
  - `enqueued_at` (TIMESTAMPTZ)
  - `available_at` (TIMESTAMPTZ) — for backoff / delayed retries
  - `claimed_by` (TEXT)
  - `lease_expires_at` (TIMESTAMPTZ)
  - `attempts` (INT)

Claim semantics (single-claimer):

- Transactional claim using row locks:
  - select one available row using `FOR UPDATE SKIP LOCKED`
  - update `claimed_by` + `lease_expires_at`

Ack/release semantics:

- `ack`: delete row (or mark done)
- `release`: set `available_at = now + backoff`, clear `claimed_by`, bump attempts (bounded by max)
- `reclaim`: treat rows with expired `lease_expires_at` as available

## Rollout plan

### Option A: Offline cutover (recommended first)

1. Stop workers.
2. Ensure queue is drained (or explicitly discard file queue backlog if acceptable for the deployment).
3. Deploy a version that supports Postgres queue, configured via `src/config.py`.
4. Start workers; validate claim/ack/retry correctness and measure claim latency/throughput.

Fallback:

- Switch config back to `file` and restart workers.

### Option B: Online dual-mode (no downtime; higher complexity)

1. Deploy a version that can **enqueue to both** backends for a window (dual-write).
2. Workers **claim from Postgres first**, then optionally fall back to file queue to drain remaining entries.
3. After a stable window, stop dual-write and remove file queue usage.

Fallback:

- Keep dual-write during the window; revert worker claim ordering if Postgres queue has issues.

## Validation checklist

- Correctness:
  - Two workers cannot claim the same job concurrently.
  - Expired claims can be reclaimed.
  - Retry attempts are bounded and recorded.
- Performance:
  - Run `scripts/bench_queue_throughput.py` (or an equivalent Postgres-backed benchmark) and record results in the run log.

