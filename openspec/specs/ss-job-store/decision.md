# Decision: Distributed JobStore backend

## Context

当前 SS 的 JobStore 与 Worker Queue 都是本地目录（`jobs/` + `queue/`）文件后端。在多实例（多 API/worker）部署下，依赖共享文件系统（例如 NFS）会遇到一致性与原子性风险：

- 缓存不一致导致读到旧数据
- 原子替换/锁语义在 NFS 上不可依赖（实现/挂载参数差异）
- 竞态条件与性能问题在并发下放大

目标：为 JobStore 选择生产级分布式后端，并定义从当前文件后端迁移到目标后端的明确路径。

## Minimum guarantees (JobStore)

- 单 job 的写入必须是原子的（不出现部分写入）
- 必须防止 silent lost update：基于 `job.json.version` 的乐观锁（CAS / compare-and-swap）
- 读写必须具备合理的 read-after-write 语义（至少同一 job 的最新状态可见）
- 错误必须显式（not found / conflict / IO）并可观测（结构化日志）

## Options compared

| Option | Pros | Cons | Ops notes | Fit |
|---|---|---|---|---|
| File on NFS | 最简单、无额外依赖 | 一致性/原子性不可靠、性能差 | 依赖 NFS 语义与挂载参数；难以做强保证 | ❌ 不推荐 |
| Redis | 低延迟、天然分布式、适合原子操作（Lua/事务） | 内存成本高；持久化/备份策略需要严谨；大对象不友好 | 需要 AOF/RDB 策略、哨兵/集群、容量规划 | ⚠️ 可作为短期方案 |
| PostgreSQL | 持久、成熟、事务与行级锁；易实现 CAS 更新 | 实现与运维复杂度更高；需要 schema/迁移管理 | 需要 HA、备份、连接池；监控与容量规划 | ✅ 生产推荐 |
| Object storage only (S3) | 成本低、扩展性好、适合 artifacts | 缺少事务/CAS；单靠对象存储难做强一致 job 元数据 | 通常需要配合 DB（metadata） | ➕ artifacts 推荐 |

## Decision

- **JobStore（job 元数据）生产级后端选择：PostgreSQL**（核心理由：事务/CAS 易实现、持久化与备份成熟、运维生态完善）。
- **Redis** 作为可选的短期方案：当团队希望以更低开发成本快速获得“多节点可用”的 job 元数据存储时可选，但必须配套严格的持久化与容量治理。
- **Artifacts**（日志/do-file/导出表图等）中长期建议迁移到对象存储（S3/OSS/MinIO），JobStore 仅保存索引（`artifacts_index`）与必要元数据。

## Configuration surface

配置统一通过 `src/config.py` 暴露（禁止在业务代码里直接读 env）。

- `SS_JOB_STORE_BACKEND`: `file` (default) | `postgres` | `redis`
- `SS_JOB_STORE_POSTGRES_DSN`: PostgreSQL DSN（当 backend=postgres 时必填）
- `SS_JOB_STORE_REDIS_URL`: Redis URL（当 backend=redis 时必填）

Implementation status:

- 当前代码仅实现 `file` 后端；选择 `postgres`/`redis` 将 **fail-fast**（显式错误 + 日志），作为后续实现的接入点。

