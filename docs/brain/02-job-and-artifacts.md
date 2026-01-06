# 02 — Job 与 Artifacts（job.json v1 / Workspace Layout）

SS 的持久化策略：一个 job 目录就是“可复现工作区”。**job.json 是权威索引**，所有产物都应能从 job.json 反查到路径与元数据。

## 1) Job 工作区目录结构（建议）

```text
jobs/<job_id>/
  job.json                # 权威索引与状态
  inputs/                 # 用户输入与预处理产物
    manifest.json         # 输入清单（路径、hash、schema 摘要）
  artifacts/              # 统一产物区（可按 kind 再分层）
    llm/
    stata/
    logs/
  runs/
    <run_id>/             # 单次 attempt 的隔离工作目录
      work/               # runner 实际工作目录（只在这里读写）
      artifacts/          # attempt 私有产物（随后可汇总到 jobs/<id>/artifacts）
```

原则：
- worker 的执行目录必须锁定在 `runs/<run_id>/work/`，避免跨目录读写。
- API 的 artifacts 下载必须只允许 job 目录内的白名单路径。

## 2) job.json v1（建议字段与语义）

最低建议包含（字段可按 YAGNI 逐步加，但口径先统一）：

```json
{
  "schema_version": 1,
  "job_id": "job_xxx",
  "status": "created",
  "created_at": "2026-01-06T00:00:00Z",
  "scheduled_at": null,
  "requirement": "user text",
  "inputs": {
    "manifest_rel_path": "inputs/manifest.json",
    "fingerprint": "sha256:...",
    "summary": { "rows": 0, "cols": 0 }
  },
  "draft": {
    "text": "...",
    "created_at": "..."
  },
  "confirmation": {
    "confirmed_at": null,
    "answers": {}
  },
  "llm_plan": {
    "plan_version": 1,
    "steps": []
  },
  "runs": [
    {
      "run_id": "run_xxx",
      "status": "running",
      "started_at": "...",
      "ended_at": null,
      "exit_code": null,
      "error_code": null,
      "artifacts": []
    }
  ],
  "artifacts_index": [
    {
      "artifact_id": "a_xxx",
      "kind": "llm.prompt",
      "rel_path": "artifacts/llm/prompt.txt",
      "created_at": "...",
      "meta": { "model": "stub", "sha256": "..." }
    }
  ]
}
```

关键约束（invariants）：
- `schema_version` 必填；变更必须可迁移。
- `status` 与 `runs[].status` 必须一致（例如 `running` 必须存在当前 attempt）。
- `artifacts_index.rel_path` 只能是 job 目录内相对路径（禁止绝对路径）。

## 3) Artifacts（把一切变成可追溯证据）

Artifacts 是 SS 的核心资产，用于：
- **保护回归**：复现某次计划/执行发生了什么
- **调试**：快速定位哪一步失败（LLM/runner/io）
- **审计**：LLM 输入输出可回放，避免“黑箱脑袋”

建议 kinds（可扩展，但要枚举化）：

- `llm.prompt` / `llm.response` / `llm.trace`（元数据、耗时、预算）
- `plan.json`（冻结计划）
- `stata.do` / `stata.log` / `stata.export.table` / `stata.export.figure`
- `run.stdout` / `run.stderr`（runner 层）

## 4) JobStore 的职责边界

- 唯一负责 `job.json` 的一致性读写（原子写入）。
- 负责对损坏数据做结构化错误（例如 `JOB_DATA_CORRUPTED`）。
- 不负责业务状态机推进（那是 domain）。

并发建议（后续实现）：
- `job.json` 的更新需要文件锁（避免多 worker 同时写）。
- 对“读-改-写”采用 revision / compare-and-swap 语义（见 `03-state-machine-and-idempotency.md`）。

