# Task Card: BE-010 论文段落 Prompt 实现（方法/结果）

- Priority: P0
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/paper-writing-prompts.md`
  - `openspec/specs/ss-full-auto-orchestration/design/report-aggregation-schema.md`

## 问题描述

即便有写作服务接口，仍缺少可执行的 Prompt 模板与解析器来生成：
- 方法部分（methods）
- 主回归结果部分（main_results）

## 技术分析

- 影响：没有方法/结果段落，用户无法把系统产出直接粘贴进论文；系统交付物停留在“表格+日志”层。
- 代码定位锚点：
  - `src/domain/stata_report_service.py`（prompt/parse 的实现参考）
  - `src/domain/stata_report_llm.py`（build prompt + parse 的模式参考）
  - `src/domain/llm_client.py`（LLM 调用入口）

## 解决方案

1. 在 `PaperWritingService` 中实现 methods/main_results 的 Prompt：
   - 输入仅使用 aggregation schema v1（禁止直接读取原始大数据）
   - 明确要求：只输出 JSON，schema_version=1
2. 实现解析器与校验：
   - 必填字段：`sections[].section_id/title/text`
   - 数值追溯：`citations[]` 必须指向 rel_path（或至少指向 aggregation JSON 的来源）
3. 补齐单元测试：
   - 给定最小 aggregation fixture，生成可解析 JSON
   - 当缺少关键数字时输出 placeholders（不生成虚假数字）

## 验收标准

- [ ] methods 与 main_results 两段输出均符合 schema v1 且可解析
- [ ] 数值不可得时输出 placeholders，并在测试中断言
- [ ] 输出 artifacts 被写入 job artifacts index（按 job-contract 路径安全）

## Dependencies

- BE-009

