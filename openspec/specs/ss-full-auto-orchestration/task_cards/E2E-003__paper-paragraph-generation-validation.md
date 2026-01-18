# Task Card: E2E-003 论文段落生成验证

- Priority: P0
- Area: E2E
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/paper-writing-prompts.md`
  - `openspec/specs/ss-full-auto-orchestration/design/report-aggregation-schema.md`

## 问题描述

需要 E2E 验证：pipeline 完成后，系统能生成论文段落产物（methods/main_results 至少两段），并且：
- 输出可解析（schema_version=1）
- 不会编造数字（缺失则占位符）

## 技术分析

- 影响：论文写作是 P0 核心缺口之一；若写作不可用或不可信，系统无法达到“可直接粘贴论文”的交付标准。
- 代码定位锚点：
  - `src/domain/stata_report_service.py`（LLM artifacts 落盘范式参考）
  - `src/domain/models.py`（artifacts index）
  - `src/domain/composition_exec/summary.py`（聚合输入来源之一）

## 解决方案

1. 在 `tests/e2e/` 增加写作验证用例：
   - 用固定 aggregation fixture 或运行一个最小 pipeline 后触发写作
2. 断言：
   - 产物中存在 `paper_paragraphs_v1.json`（或等价命名）并可解析
   - `sections` 至少包含 methods 与 main_results
   - 若数字缺失，存在 placeholders 字段（不得生成随机数字）
3. 失败诊断：
   - 输出引用的 citations rel_path，便于定位

## 验收标准

- [ ] E2E 断言写作 JSON schema_version=1 且可解析
- [ ] methods/main_results 段落存在且为非空文本
- [ ] 缺数字时出现 placeholders，确保“不编数字”策略可验收

## Dependencies

- BE-010

