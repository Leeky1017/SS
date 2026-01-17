# Task Card: E2E-001 Panel regression workflow

- Priority: P1-HIGH
- Area: E2E / User journey
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-testing-strategy/README.md`

## 问题描述

需要用真实用户路径验证“面板回归”从上传到产出下载的完整链路，并覆盖可操作错误场景，作为 UX remediation 的回归门禁。

## 技术分析

- 此 E2E 覆盖后端与前端任务卡的关键依赖：
  - BE-005/006/008/009（辅助文件、候选列、必填变量选择、可操作错误）
  - FE-026/030/037/038/043（上传进度、轮询超时、会话过期、状态持久化、可操作错误）
- 代码定位锚点：
  - `tests/e2e/`
  - `scripts/ss_ssh_e2e/v1_journey.py`

## 解决方案

1. 新增/扩展 E2E 测试场景：用户上传两个 Excel 文件，完成面板回归分析并下载结果。
2. Happy-path 步骤：
   1) 上传主文件（多 sheet，选择“面板数据”sheet）
   2) 上传辅助文件（选择指定 sheet）
   3) 变量选择：Y=经济发展水平、X=政府干预程度
   4) 选择 ID=省份、Time=年份
   5) 选择合并键=province+year（如适用）
   6) 确认并执行（confirm → run → poll）
   7) 下载并验证产出 artifacts：描述统计表、主回归表、稳健性表（以及日志/元信息）
3. Failure-path（必卡点）：
   - 不提供 ID/Time 变量时，返回结构化错误（`error_code=PLAN_FREEZE_MISSING_REQUIRED`，包含可操作字段如 `missing_fields`/`next_actions`/detail）。
   - 前端（或 E2E driver）按指引补全后重试成功。

## 验收标准

- [ ] Happy-path：完整流程无阻断，最终可下载所有预期 artifacts（至少包含结果表与 run evidence）
- [ ] Failure-path：断言稳定 `error_code` 与可操作字段，且补全后可恢复到成功路径

## Dependencies

- 无
