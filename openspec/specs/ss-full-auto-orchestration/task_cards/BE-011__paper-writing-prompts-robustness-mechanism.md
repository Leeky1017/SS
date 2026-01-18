# Task Card: BE-011 论文段落 Prompt 实现（稳健性/机制）

- Priority: P1
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/paper-writing-prompts.md`
  - `openspec/specs/ss-full-auto-orchestration/design/report-aggregation-schema.md`

## 问题描述

稳健性与机制/异质性段落是论文实证部分的关键，但也最容易“编造结论”。需要在 Prompt 与解析层增加更严格的约束，确保：
- 只基于聚合结果写作
- 不一致时如实陈述
- 缺失时输出占位符

## 技术分析

- 影响：若稳健性/机制段落不可靠，会直接损害系统可信度；即便表格正确，文字不可信也无法交付。
- 代码定位锚点：
  - `src/domain/stata_report_llm.py`（解析失败处理参考）
  - `src/domain/stata_report_models.py`（结构化输出模型参考）
  - `src/domain/models.py`（artifacts index 约束）

## 解决方案

1. 在 `PaperWritingService` 中实现 robustness/mechanism/heterogeneity 段落 Prompt：
   - 明确列出可用输入字段（robustness_compare、mechanism steps 等）
   - 强制输出 JSON schema v1
2. 强化一致性约束：
   - 若稳健性结果方向/显著性不一致，必须在 `text` 中陈述差异，并在 `placeholders/reasons` 记录风险提示
3. 补齐测试：
   - 一致性场景：稳健性结论“支持主结论”
   - 不一致场景：必须输出“存在差异”的表述（断言关键词/结构字段）

## 验收标准

- [ ] robustness/mechanism/heterogeneity 段落输出可解析且 schema_version=1
- [ ] 不一致时不会“强行一致”，测试断言其差异陈述存在
- [ ] 缺少机制/异质性输入时输出占位符并记录原因（不抛异常）

## Dependencies

- BE-010
- BE-012

