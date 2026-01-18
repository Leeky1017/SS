# Task Card: BE-007 ReportAggregationService 接口定义

- Priority: P0
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/report-aggregation-schema.md`
  - `openspec/specs/ss-job-contract/spec.md`

## 问题描述

多步执行后，系统目前只有 `composition_summary.json`（元数据），缺少一个面向用户与写作的“聚合报告层”。需要定义并实现 `ReportAggregationService` 的最小接口与产物契约。

## 技术分析

- 影响：没有聚合层，前端无法稳定展示多步结果；论文写作无法从统一结构中取数；用户需要手动从多个 step 产物中拼装。
- 代码定位锚点：
  - `src/domain/composition_exec/summary.py`（输入：pipeline summary）
  - `src/domain/models.py`（`ArtifactKind` / artifacts index 约束）
  - `src/domain/output_formatter_service.py`（与格式化服务的集成点）

## 解决方案

1. 新增领域服务接口（建议新文件）：
   - `src/domain/report_aggregation_service.py`
2. 定义输入/输出（v1）：
   - 输入：`job_id`、`pipeline_run_id`、`composition_summary_rel_path`、step artifacts index
   - 输出：`AggregationOutcome`（success/error + artifact refs）
3. 输出必须写入版本化聚合 JSON（schema v1），并写入 artifacts index
4. 失败路径必须结构化：
   - 缺少 summary / 路径不安全 / 解析失败等必须返回稳定 `error_code`

## 验收标准

- [ ] 聚合服务接口清晰，输入/输出可序列化并易于测试
- [ ] 成功路径写入版本化 aggregation JSON 并更新 artifacts index
- [ ] 失败路径返回结构化错误（`error_code` + `message`）且具备单元测试

## Dependencies

- BE-003

