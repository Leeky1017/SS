# SS Job Contract — Index

本目录定义 SS 的 job 工作区与 `job.json` v1（可复现工作区 + 权威索引）。

## Schema version 策略（强约束）

- `job.json` 必须包含 `schema_version`（int）。
- 写入策略：永远写入当前版本（current write version）。
- 读取策略：支持一段有限的旧版本（supported read versions），并在 `load()` 时通过显式迁移步骤升级到当前版本（并回写）。
- 兼容性窗口（当前）：
  - current write version: `3`
  - supported read versions: `1`, `2`, `3`
- 缺失/未知 `schema_version`：视为数据损坏，拒绝加载（需要人工修复或显式迁移扩展）。
- 迁移可观测性：每次迁移必须记录结构化日志事件 `SS_JOB_JSON_SCHEMA_MIGRATED`，包含：
  - `job_id`
  - `from_version`
  - `to_version`

## Job 工作区（建议结构）

```text
jobs/<job_id>/
  job.json
  inputs/
    manifest.json
  artifacts/
    llm/
    stata/
    logs/
  runs/
    <run_id>/
      work/
      artifacts/
      meta.json
```

硬约束：
- Runner 的 `cwd` MUST 固定在 `runs/<run_id>/work/`。
- Artifacts 的 `rel_path` MUST 是 job 目录内相对路径（禁止绝对路径与 `..` 逃逸）。

## job.json v3（当前写入版本；字段清单与语义）

位置：`jobs/<job_id>/job.json`

最小合法示例：

```json
{
  "schema_version": 3,
  "version": 1,
  "job_id": "job_0123456789abcdef",
  "status": "created",
  "created_at": "2026-01-06T17:50:00+00:00",
  "requirement": "...",
  "runs": [],
  "artifacts_index": []
}
```

必须包含：
- `schema_version`（int；v3 固定为 `3`）
- `version`（int；>= 1；每次成功写入必须单调递增）
- `job_id`（string）
- `status`（string enum）
- `created_at`（ISO string）
- `requirement`（nullable string）
- `runs[]`（list；允许为空）
- `artifacts_index[]`（list；允许为空）

字段语义（v3）：

- `schema_version`: 版本号（v3 固定为 `3`；v1/v2 读取后会迁移到 v3）。
- `version`: 并发控制版本号（单调递增）；用于防止并发写入时的 silent overwrite（保存时需要做乐观锁冲突检测）。
- `job_id`: job 唯一标识（建议前缀 `job_`，其余为安全的短 token）。
- `status`: job 状态（枚举；v1 为 `created` / `draft_ready` / `confirmed` / `queued` / `running` / `succeeded` / `failed`；允许迁移见 `openspec/specs/ss-state-machine/spec.md`）。
- `created_at`: job 创建时间（ISO8601）。
- `requirement`: 用户需求文本；允许为 `null`（表示尚未提供/为空）。
- `runs[]`: 运行尝试列表（worker 执行记录与重试）。
- `artifacts_index[]`: Artifacts 索引（见下）。

可选字段（v3 预留，按 YAGNI 逐步落地，但口径先统一）：

- `scheduled_at`（ISO string | null）：当进入排队/调度态时写入。
- `inputs`：
  - `manifest_rel_path`（string | null）：相对 job 目录的输入清单路径（例如 `inputs/manifest.json`）。
  - `fingerprint`（string | null）：输入指纹（用于幂等/重跑判定）。
- `draft`：LLM 草案预览（写回 job.json 以便审计与复现）。
- `confirmation`：用户确认信息（冻结需求/约束，驱动状态机推进）。
- `llm_plan`：LLM 规划输出（schema-bound），并应通过 artifacts 可回放。
- `runs[]`：运行尝试列表（worker 执行记录与重试）。
- `artifacts_index[]`：Artifacts 索引（见下）。

## Artifacts（必须一等公民）

Artifacts 的作用：
- 复现（LLM prompt/response、do-file、log、输出表/图）
- 审计（主脑输入输出可回放）
- 调试（错误证据可定位）

建议 kinds（枚举化，不允许随意字符串）：
- `llm.prompt` / `llm.response` / `llm.meta`
- `plan.json`
- `stata.do` / `stata.log`
- `run.stdout` / `run.stderr`
- `stata.export.table` / `stata.export.figure`

Artifacts 索引字段建议（v1）：

- `kind`（enum）：必须来自预定义枚举（禁止自由字符串）。
- `rel_path`（string）：相对 job 目录路径；必须满足：
  - 不能是绝对路径（例如 `/tmp/a.log`）
  - 不能包含 `..`（防止目录穿越）
  - 建议使用 `/` 分隔（posix 风格）
