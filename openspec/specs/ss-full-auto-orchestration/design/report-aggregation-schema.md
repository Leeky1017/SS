# Design: Report aggregation schema (ss-full-auto-orchestration)

## Goals

- 定义多步结果聚合的数据结构（aggregation schema v1），将 `composition_exec` 的 step 产物收敛为统一“报告层”。
- 定义汇总表生成规则（稳健性对比表、异质性对比表），并明确与 `OutputFormatterService` 的集成点。
- 支持后续 `PaperWritingService` 直接消费（避免重复解析 Stata 输出）。

## Inputs（数据来源）

聚合器的输入来自“可审计产物”，不依赖进程内状态：
- `composition_summary.json`（`composition_exec` 输出；包含 step、run_id、products、decisions）
- step evidence：每步 `runs/<step_run_id>/` 目录下的表格/日志/导出物
- 可选：单步解读/报告（如 `stata.report.interpretation`）

## Output schema（aggregation v1）

```json
{
  "schema_version": 1,
  "job_id": "string",
  "pipeline_run_id": "string",
  "generated_at": "ISO8601",
  "steps": [
    {
      "step_id": "string",
      "type": "string",
      "purpose": "string",
      "status": "succeeded | failed | skipped",
      "run_id": "string|null",
      "outputs": {
        "tables": [{"rel_path": "string", "label": "string"}],
        "figures": [{"rel_path": "string", "label": "string"}],
        "reports": [{"rel_path": "string", "label": "string"}]
      },
      "key_numbers": {
        "coef": "number|null",
        "se": "number|null",
        "p_value": "number|null",
        "n": "number|null"
      }
    }
  ],
  "summary_tables": [
    {
      "table_id": "robustness_compare | heterogeneity_compare",
      "title": "string",
      "rel_path": "string",
      "source_steps": ["step_id", "..."]
    }
  ],
  "notes": ["string", "..."]
}
```

说明：
- `steps[].outputs` 只引用 job-relative `rel_path`（禁止绝对路径与 `..`）。
- `key_numbers` 是给写作/展示用的“关键数值提取”，允许为空；不得阻塞聚合。

## Summary table rules（汇总表生成规则 v1）

### 1) 稳健性对比表（robustness_compare）

目标：把主回归与各稳健性回归的关键系数并排展示。

规则（v1，最小可用）：
- 选择主回归 step（`purpose` 包含 `main` 或由 plan 标注）作为基准列（Column 1）
- 选择所有 `robustness_check` steps 作为对比列
- 每列最少包含：核心系数、标准误、显著性星号、样本量
- 若列缺少某字段，显示为空并在 `notes[]` 记录原因

### 2) 异质性对比表（heterogeneity_compare）

目标：把分组回归/交互项等异质性结果按组展示。

规则（v1）：
- 选择所有 `heterogeneity_analysis` steps
- 若 step 有 `group` 信息（来自模板参数或 step purpose），按组聚合

## Integration with OutputFormatterService

聚合器 SHOULD：
- 生成一个“原生 JSON”聚合产物（供写作/前端消费）
- 生成至少 1 个“汇总表”文件（推荐 `.xlsx` 或 `.csv`），并以 artifact 形式索引

与 `OutputFormatterService` 的协作方式（建议）：
- 聚合器先生成 canonical 数据文件（JSON/CSV）
- 再调用 `OutputFormatterService` 生成用户请求的格式（xlsx/docx/pdf），避免重复造轮子

## Artifact kinds（建议新增）

为避免复用 `stata.export.*` 造成语义混淆，建议新增（后续需同步 `ss-job-contract` 与 `ArtifactKind` 枚举）：
- `report.aggregation.json`
- `report.aggregation.table`
- `paper.paragraphs.json`
- `paper.paragraphs.md`

## Integration points（代码对齐点）

- 多步执行摘要：
  - `src/domain/composition_exec/summary.py`
- 输出格式化：
  - `src/domain/output_formatter_service.py`
- 现有单步解读参考：
  - `src/domain/stata_report_service.py`

