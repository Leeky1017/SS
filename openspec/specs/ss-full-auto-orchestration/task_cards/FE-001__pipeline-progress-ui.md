# Task Card: FE-001 Pipeline 执行进度展示

- Priority: P1
- Area: Frontend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-frontend-architecture/spec.md`

## 问题描述

多步 pipeline 执行时，用户需要明确的进度反馈（第 k/n 步、当前步骤名称、已完成/失败/跳过）。当前前端缺少该展示，用户会误判卡死或重复操作。

## 技术分析

- 影响：无进度反馈直接拉低“代劳服务”体验；也增加支持成本（用户不断询问是否卡住）。
- 代码定位锚点：
  - `src/domain/composition_exec/summary.py`（进度数据来源 schema）
  - `src/domain/models.py`（artifacts index / runs）
  - `frontend/src/features/`（Job 详情页/执行页的 UI 入口，实际以仓库结构为准）

## 解决方案

1. 对接 BE-015 提供的 progress 字段/端点：
   - 轮询策略：遵循现有 polling 约定（避免过度请求）
2. UI 展示（v1）：
   - 顶部：第 k/n 步 + 当前 step 的 purpose
   - 列表：每步 status（succeeded/failed/skipped/running）
   - 失败时：显示结构化错误 message，并给出下一步建议（如“查看第 X 步日志”）
3. 状态管理：
   - 复用现有 job store/query（遵循 `ss-frontend-architecture`）

## 验收标准

- [ ] running 时可显示当前 step 与总步数
- [ ] succeeded/failed 时展示最终状态，并保留每步状态列表
- [ ] 失败场景能展示后端返回的结构化错误信息（不显示堆栈）

## Dependencies

- BE-015

