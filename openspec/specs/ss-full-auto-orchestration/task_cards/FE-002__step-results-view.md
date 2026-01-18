# Task Card: FE-002 多步结果分 step 展示

- Priority: P1
- Area: Frontend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/report-aggregation-schema.md`
  - `openspec/specs/ss-full-auto-orchestration/spec.md`

## 问题描述

多步 pipeline 会产生多组表格/图形/报告。用户需要按 step 查看结果（并能定位到稳健性/异质性等），否则多步执行反而增加困惑。

## 技术分析

- 影响：无法分 step 展示会让用户难以理解 pipeline 做了什么，也无法快速定位失败或异常结果。
- 代码定位锚点：
  - `src/domain/composition_exec/summary.py`（step outputs/evidence_dir 字段）
  - `src/domain/models.py`（artifacts index 与下载机制）
  - `frontend/src/features/`（结果展示页入口）

## 解决方案

1. 数据来源优先级（v1）：
   - 优先消费聚合报告（BE-007 输出 aggregation schema v1）
   - 若聚合不可用，退化为读取 `composition_summary.json` + artifacts index
2. UI 展示（v1）：
   - 左侧 step 列表（purpose + status）
   - 右侧 step 详情：该 step 的 tables/figures/reports 下载与预览入口
3. 交互：
   - 支持“只看稳健性”“只看异质性”过滤（基于 step type）

## 验收标准

- [ ] 用户可按 step 浏览产物，并能下载对应表格/报告
- [ ] UI 能区分主回归/稳健性/异质性 step（基于 type 或 purpose）
- [ ] 在聚合缺失时，仍能基于 summary/index 做降级展示

## Dependencies

- BE-007
- BE-015

