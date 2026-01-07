# Decision: Production queue backend

## Context

SS currently uses a file-backed worker queue (`FileWorkerQueue`). This is suitable for a single-node setup, but it has an O(backlog) claim path and relies on filesystem semantics that do not generalize to multi-node deployments (shared FS/NFS).

This decision aligns queue scaling with the JobStore Phase-2 decision (`openspec/specs/ss-job-store/decision.md`), where **PostgreSQL is the recommended production backend** for job metadata.

## Options compared

| Option | Pros | Cons | Ops notes | Fit |
|---|---|---|---|---|
| File queue | Zero extra dependencies; simple | Not multi-node safe; claim scan is O(backlog); no advanced features | Must be local disk; avoid NFS | ✅ dev only |
| PostgreSQL queue | Reuses existing production dependency; strong transactional semantics; `SKIP LOCKED` supports multi-worker claim | Higher implementation complexity; DB load/locking considerations | Needs HA/backup/connection pool; schema migrations | ✅ production default |
| Redis (Streams/Lists) | Low latency; good for high throughput; consumer groups | Requires Redis ops; persistence/memory planning; semantic complexity | Requires AOF/RDB strategy and capacity planning | ⚠️ high-throughput option |
| RabbitMQ | Mature queue semantics; ack/DLQ; priority queues | Extra service dependency; AMQP ops | Requires broker HA/monitoring and tuning | ⚠️ advanced scheduling option |

## Decision

- **Default production queue backend: PostgreSQL**.
  - Rationale: SS already recommends Postgres for JobStore metadata; using Postgres for queue avoids a second operational dependency while providing atomic claim semantics suitable for multi-worker deployments.
- **Redis / RabbitMQ** are optional scale-up paths:
  - Redis: when extremely low claim latency and very high enqueue/claim rates are required.
  - RabbitMQ: when priority queues, DLQ, and broker-level routing are required (fits Phase-3 scheduling work).

## Configuration surface (planned)

Configuration remains centralized in `src/config.py` (no direct env reads in business code).

- `SS_QUEUE_BACKEND`: `file` (default) | `postgres` | `redis` | `rabbitmq`
- Backend-specific settings:
  - Postgres: reuse `SS_JOB_STORE_POSTGRES_DSN` (or add a dedicated `SS_QUEUE_POSTGRES_DSN` if separation is required)

Implementation status:

- Current code implements only `file`.
- Selecting other backends SHOULD fail-fast with an explicit error until implemented.

