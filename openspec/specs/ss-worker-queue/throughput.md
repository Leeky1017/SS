# Throughput: ss-worker-queue

## Definitions

- **Throughput**: `claim + ack` operations per minute (how fast workers can pull jobs from the queue when jobs are immediately acked).
- **Claim latency**: wall-clock time spent inside `WorkerQueue.claim(worker_id=...)` until a claim is returned (or `None`).
- **Backlog**: number of queue entries currently waiting in the backend.

This document focuses on queue mechanics only (not job execution time). In SS, job runtime (Stata/LLM) is typically the dominant component, but queue scalability becomes critical when worker count and backlog grow.

## Current backend: FileWorkerQueue (file-based)

Implementation: `src/infra/file_worker_queue.py`

Key properties:

- **Atomic claim**: done via filesystem rename (queued → claimed).
- **Lease semantics**: claim records `lease_expires_at`; expired claims can be reclaimed.
- **Backlog scan cost**: each `claim()` scans `queued/*.json` (glob + sort) and attempts to claim one entry.

Implications:

- Claim work is **O(backlog)** per claim due to directory scanning and sorting.
- As backlog grows, claim latency grows quickly, even if individual file operations are fast.
- Correctness and performance depend on filesystem semantics; **do not use NFS/shared FS** as a “distributed queue”.

## Measured envelope (local dev reference)

Benchmark script: `scripts/bench_queue_throughput.py`

Environment (reference):

- `python=3.12.3`
- `platform=Linux-6.6.87.2-microsoft-standard-WSL2-x86_64-with-glibc2.39`

Results (claim+ack only; job execution excluded):

1) Backlog 2,000 (process all 2,000 claims), 4 workers:

- `jobs_min≈6758`, `claim_p95_ms≈69`

2) Backlog 20,000 (process 200 claims), 4 workers:

- `jobs_min≈299`, `claim_p95_ms≈931`

Interpretation:

- File queue can achieve high throughput when backlog is bounded.
- Claim latency degrades sharply as backlog grows, due to O(backlog) scanning.

## Throughput targets and constraints

### Tier 0: File queue (default; single-node only)

Use-case: development, demos, or low-scale single-node deployments on local disk.

Constraints:

- Worker count assumption: **≤ 4 workers** on one node.
- Backlog assumption: **≤ 2,000 queued entries** (keeps p95 claim latency low in local measurements).
- Deployment constraint: queue directory MUST be on local disk; MUST NOT rely on shared FS semantics.

Target:

- Sustained queue throughput SHOULD be ≥ **20 jobs/min** under the above constraints (aligns with audit baseline KPI).

Migration trigger:

- If backlog regularly exceeds **2,000**, or p95 claim latency exceeds **250ms**, migrate to a distributed queue backend.

### Tier 1: Production queue (distributed backend)

Target (aligned with audit KPI):

- Queue throughput SHOULD support ≥ **100 jobs/min** with **≥ 10 workers**.
- p95 claim latency SHOULD be **≤ 200ms** under expected backlog.

## Validation method

Before changing queue backend (or after changing claim/release semantics):

- Run the benchmark script for at least two backlog sizes and record output in `openspec/_ops/task_runs/ISSUE-<N>.md`.
- Validate correctness invariants: single-claimer semantics, bounded retries, and reclaim on lease expiry.

