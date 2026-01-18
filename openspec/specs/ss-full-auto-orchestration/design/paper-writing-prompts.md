# Design: Paper writing prompts (ss-full-auto-orchestration)

## Goals

- 把当前“技术报告解读”（`StataReportService`）升级为“论文段落生成”：方法、结果、稳健性、机制/异质性四类段落。
- 定义可执行的 Prompt 模板与**输出 schema**，保证可解析、可审计、可回放。
- 强制 **数值可追溯**：段落中的关键数字必须能映射到聚合报告/原始表格产物，不得凭空生成。

## Constraints (non-negotiable)

- 输出必须是 JSON（无 markdown 包裹、无额外文本），并带 `schema_version`。
- 若缺少数字来源，必须输出占位符（例如“（待补）”）并给出结构化原因。
- 所有 LLM 调用必须落 `llm.prompt/llm.response/llm.meta` 产物（见 `ss-llm-brain`），且不得在 application logs 中打印原文。

## Output schema（v1）

```json
{
  "schema_version": 1,
  "language": "zh-CN",
  "style": "academic",
  "job_id": "string",
  "pipeline_run_id": "string",
  "sections": [
    {
      "section_id": "methods | main_results | robustness | mechanism | heterogeneity",
      "title": "string",
      "text": "string",
      "citations": [
        {
          "kind": "table | figure | artifact",
          "rel_path": "job-relative rel_path",
          "note": "string"
        }
      ],
      "placeholders": [
        {
          "key": "missing_number",
          "reason": "string"
        }
      ]
    }
  ]
}
```

说明：
- `citations[]` 用于“数字追溯”最小闭环：至少能定位到某个表格或聚合 JSON 的字段来源。
- `placeholders[]` 用于明确告诉用户/测试：哪些数字缺失、为什么缺失。

## Prompt templates（v1）

统一输入（从 `ReportAggregationService` 输出中提取）：
- 研究问题摘要（requirement + draft）
- 主回归关键结果（系数、标准误、显著性、样本量、R2 等）
- 稳健性对比表（如有）
- 机制/异质性结果（如有）
- 变量定义与数据结构信息（如有）

### 1) 方法部分（methods）

写作目标：
- 描述数据、样本、变量定义（可用信息范围内）
- 描述识别策略/模型设定（OLS/FE/DID/IV 等）
- 描述标准误处理（聚类层级/稳健标准误）

硬约束：
- 不得宣称未执行的检验/模型
- 不得编造变量定义；未知则输出占位符

### 2) 主回归结果（main_results）

写作目标：
- 陈述核心系数方向、大小、显著性
- 简述经济含义/管理含义（保持克制）

硬约束：
- 所有数字必须来自输入（不能重新“算”）
- 若存在多列/多模型，必须明确指代（例如“列(1)”）

### 3) 稳健性部分（robustness）

写作目标：
- 总结稳健性检验集合与一致性
- 强调主要结论不受设定变化影响（如事实支持）

硬约束：
- 若稳健性结果不一致，必须如实陈述，禁止“强行一致”

### 4) 机制/异质性部分（mechanism / heterogeneity）

写作目标：
- 机制：按预设路径陈述中介/调节证据
- 异质性：按分组维度陈述差异

硬约束：
- 机制/异质性若未执行或证据不足，必须输出占位符与原因

## Artifact layout（建议）

写作服务 SHOULD 写入：
- `artifacts/paper_paragraphs_v1.json`（kind 建议新增：`paper.paragraphs.json`）
- `artifacts/paper_paragraphs_v1.md`（人类可读）

并更新 `job.artifacts_index`（见 `ss-job-contract`）。

## Integration points（代码对齐点）

- 现有参考：
  - `src/domain/stata_report_service.py`（LLM 调用、解析、落盘、结构化日志的范式）
- 新增建议：
  - `src/domain/paper_writing_service.py`
  - `src/domain/paper_writing_prompts.py`

