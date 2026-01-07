# Migration: file JobStore → distributed backend

## Preconditions

- `job.json` 必须是版本化契约并支持迁移：`openspec/specs/ss-job-contract/README.md`
- 文件后端必须已具备“防止 silent lost update”的语义（`job.json.version` + 冲突显式失败）

## Target architecture (Phase 2)

- JobStore（job 元数据）：PostgreSQL
- Worker queue（claim/lease）：可继续使用 Redis/DB（本任务不覆盖 queue 的迁移）
- Artifacts：短期可继续保留文件系统；中长期迁移到对象存储（JobStore 保存索引）

## Data model sketch (PostgreSQL)

最小化表结构（示意）：

- `jobs`
  - `job_id` (PK)
  - `payload` (JSONB，包含 `schema_version`/`version`/status 等)
  - `version` (INT，从 `payload.version` 镜像出来便于 CAS 更新)
  - `updated_at` (TIMESTAMPTZ)

写入语义：

- Create: `INSERT`（若已存在则报错或显式冲突）
- Save (CAS): `UPDATE ... WHERE job_id = $1 AND version = $2`，受影响行数为 0 则冲突

## Migration plan

### Option A: Offline (recommended first)

适用于早期流量小/可接受短暂停机的场景。

1. 停止 API + worker（确保没有写入发生）。
2. 运行一次性迁移工具（file → postgres）：
   - 遍历 `jobs/<job_id>/job.json`
   - 对 payload 执行 `load()` 等价的 schema migration（v1/v2 → current）
   - 写入 Postgres（保持 `job_id` 与 `version`）
3. 将配置切换为 Postgres：
   - `SS_JOB_STORE_BACKEND=postgres`
   - `SS_JOB_STORE_POSTGRES_DSN=postgresql://ss:ss@localhost:5432/ss`
4. 启动 API + worker，观察关键指标与错误日志（not found/conflict/io）。

Fallback（回滚）：

- 不删除 `jobs/` 目录；如出现严重问题，直接把 `SS_JOB_STORE_BACKEND` 切回 `file` 并重启。

### Option B: Online (no downtime)

适用于需要无停机迁移的场景（实现成本更高）。

1. 上线支持“并行后端”的版本（dual-read / dual-write）：
   - Read: 优先读 Postgres，若 `job_id` 不存在则回退读 file
   - Write: 对新写入（create/save）同时写 Postgres + file（或反之）
2. 后台 backfill：把历史 `jobs/` 导入 Postgres（与 Option A 相同的迁移逻辑）。
3. 观察一段窗口期（例如 1-2 周），确保 Postgres 命中率接近 100% 且错误率稳定。
4. 关闭 file 写入（仅保留只读或完全切换）。

Fallback（回滚）：

- 在窗口期内保留 dual-write；如需回滚，切回 file 仍有完整数据。

## Data migration considerations

- Schema version：迁移必须遵循 `SUPPORTED_JOB_SCHEMA_VERSIONS`，并将旧版本升级到 current。
- Version conflicts：迁移过程中若 job 在 file 侧仍可能被写入，必须先停机或引入“迁移时冻结写入”的机制。
- Artifacts：如果 artifacts 仍在文件系统，必须确保 worker 与 API 均可访问对应路径；否则需要先迁移 artifacts 到对象存储并更新 `artifacts_index`。
