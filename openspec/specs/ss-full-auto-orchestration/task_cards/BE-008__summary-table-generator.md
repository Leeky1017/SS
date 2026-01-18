# Task Card: BE-008 汇总表生成器实现

- Priority: P0
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/report-aggregation-schema.md`
  - `openspec/specs/ss-full-auto-orchestration/design/full-pipeline-plan-schema.md`

## 问题描述

稳健性对比表、异质性对比表是论文交付物的核心。当前系统只能输出单步表格，缺少“跨 step 汇总”的生成器。

## 技术分析

- 影响：没有汇总表，用户仍需人工对齐多个回归表的核心系数，无法达到“代劳服务”的交付标准。
- 代码定位锚点：
  - `src/domain/output_formatter_service.py`（输出格式化能力）
  - `src/domain/stata_result_parser.py`（从表格/日志提取关键数字的参考）
  - `src/domain/models.py`（artifact 索引与 kind 约束）

## 解决方案

1. 在 `ReportAggregationService` 内实现（或拆分）“汇总表生成器”：
   - 输入：主回归 step + 稳健性 steps +（可选）异质性 steps 的关键产物路径
   - 输出：`robustness_compare.xlsx/csv`、`heterogeneity_compare.xlsx/csv`（至少一种）
2. 汇总规则（v1）：
   - 以主回归为基准列，稳健性为对比列
   - 每列包含：核心系数、标准误、显著性、样本量
   - 缺字段时留空并在 notes 记录原因
3. 产物必须写入 artifacts index（并确保 rel_path 安全）
4. 补齐单元/集成测试：
   - 用最小样例表格验证汇总输出结构稳定

## 验收标准

- [ ] 生成稳健性对比表（文件存在且可被测试读取/解析）
- [ ] 生成异质性对比表（若输入包含异质性 steps）
- [ ] 聚合产物被写入 artifacts index，且 rel_path 符合 job-contract 的路径安全要求

## Dependencies

- BE-007

