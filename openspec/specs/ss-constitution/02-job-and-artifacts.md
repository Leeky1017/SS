# 02 — Job 与 Artifacts（job.json v1 / Workspace Layout）

SS 的核心持久化策略：一个 job 目录就是“可复现工作区”。`job.json` 是权威索引，任何关键产物都必须以 artifacts 的形式落盘并可反查。

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
- Artifacts 的 `rel_path` MUST 是 job 目录内相对路径（禁止绝对路径）。

## job.json v1（建议字段口径）

必须包含：
- `schema_version`（int）
- `job_id`（string）
- `status`（string enum）
- `created_at`（ISO string）
- `requirement`（nullable string）

建议包含（按 YAGNI 逐步加，但口径先统一）：
- `inputs.manifest_rel_path`、`inputs.fingerprint`
- `draft`
- `confirmation`
- `llm_plan`
- `runs[]`
- `artifacts_index[]`

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

