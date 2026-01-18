# Task Card: BE-009 PaperWritingService 接口定义

- Priority: P0
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/paper-writing-prompts.md`
  - `openspec/specs/ss-llm-brain/spec.md`

## 问题描述

当前 `StataReportService` 更偏“单步技术解读”，缺少面向论文的段落生成能力。需要定义 `PaperWritingService` 的最小接口与产物契约，作为后续 Prompt 与前端预览的稳定入口。

## 技术分析

- 影响：没有论文段落，交付物不完整；用户需要人工撰写方法/结果/稳健性段落，无法称为“全自动代劳服务”。
- 代码定位锚点：
  - `src/domain/stata_report_service.py`（LLM 调用 + 解析 + artifacts 落盘范式）
  - `src/domain/llm_client.py`（LLM 端口）
  - `src/domain/models.py`（artifacts index 约束）

## 解决方案

1. 新增领域服务接口（建议新文件）：
   - `src/domain/paper_writing_service.py`
2. 定义输入/输出（v1）：
   - 输入：聚合报告（aggregation v1 JSON）、可选 draft/requirement 摘要、写作偏好（language/style）
   - 输出：版本化 JSON（paper paragraphs v1）+ 可读 markdown（可选）
3. 写作服务必须遵循 `ss-llm-brain`：
   - prompt/response/meta 全落盘
   - 解析失败/缺数字时返回结构化错误或占位符（不得编数字）
4. 补齐单元测试：
   - 解析 happy path
   - 缺失数字的占位符 path（断言 placeholders 字段）

## 验收标准

- [ ] `PaperWritingService` 的输出 schema_version=1 且可被解析
- [ ] 缺少数字时输出占位符并记录结构化原因（不抛裸异常）
- [ ] LLM artifacts 落盘与索引遵循 `ss-llm-brain`

## Dependencies

- BE-007

