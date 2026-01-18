# Task Card: BE-015 执行进度追踪 API

- Priority: P1
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-state-machine/spec.md`

## 问题描述

全链路多步执行需要用户可感知的进度（例如“第 3/8 步：稳健性检验 1”）。当前缺少一个稳定的进度查询 API，前端无法实时展示 pipeline 状态。

## 技术分析

- 影响：无进度会导致用户误判卡死/重复提交；同时也不利于定位执行失败发生在哪一步。
- 代码定位锚点：
  - `src/domain/composition_exec/summary.py`（`composition_summary.json` 是进度数据的重要来源）
  - `src/domain/models.py`（`Job.runs` / artifacts index）
  - `src/api/jobs.py`（jobs 查询 API 的扩展入口，需保持 API thin）

## 解决方案

1. 定义进度数据模型（v1）：
   - total_steps、completed_steps、running_step_id（或 index）、per_step_status（succeeded/failed/skipped）
   - progress 必须可从持久化产物推导（优先 `composition_summary.json` + run state）
2. 设计 API 方案（择一）：
   - A) 扩展 `GET /v1/jobs/{job_id}` 返回 `progress` 字段（推荐：减少 API 数量）
   - B) 新增 `GET /v1/jobs/{job_id}/progress`
3. 错误处理：
   - 缺少 summary 或路径不安全时返回结构化错误
4. 日志：
   - 进度查询应有 access log；关键失败应有 `event=SS_PROGRESS_QUERY_FAILED`

## 验收标准

- [ ] 进度 API 返回包含 total/current/per_step_status 的稳定结构（契约可测）
- [ ] 失败路径返回 `{"error_code":"...","message":"..."}` 且不泄露内部异常
- [ ] 能正确展示：running 时的当前 step；succeeded/failed 时的最终状态

## Dependencies

- BE-003

