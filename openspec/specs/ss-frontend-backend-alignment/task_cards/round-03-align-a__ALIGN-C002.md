# [ROUND-03-ALIGN-A] ALIGN-C002: redeem endpoint + token 生成/存储/校验（含 pytest）

## Problem

当前后端缺少“task code → job_id + token”的统一入口与 token 校验能力，导致前端无法在 v1 合同下完成：
- redeem 获取 token
- 带 token 调用上传/Step3/确认链路

## Goal

实现 `POST /v1/task-codes/redeem` 与 token 全链路（生成/存储/校验），并提供 pytest 覆盖：
- redeem 幂等（同一 `task_code` 重复 redeem → 同一 `job_id`）
- token 不轮换策略符合 spec（同一 `task_code` 重复 redeem → 同一 `token`）
- `expires_at` 的滑动过期语义符合 spec

## In scope

- API：新增 `POST /v1/task-codes/redeem`（路径与字段按 `ss-frontend-backend-alignment` v1 合同）
- Domain：实现 task-code redeem 的最小职责（校验 task_code、创建/定位 job、绑定 token）
- Infra：token 的生成与持久化（允许用 job store 落盘；必须能按 token 查回授权 job）
- 配置：引入并从 `src/config.py` 加载 `SS_V1_ENABLE_LEGACY_POST_JOBS`
- Structured errors：所有失败返回 SS `SSError` 结构化错误（`error_code` + `message`）
- Pytest：新增/覆盖 redeem 与 token 相关测试（不 mock 内部模块，只 mock 外部边界）

## Out of scope

- entitlement/配额/计费体系
- 人类用户账户体系（登录/注册/OAuth）
- 高级安全策略（IP 绑定、速率限制、WAF）

## Dependencies

- ALIGN-C001（v1 合同冻结）
- 现有 job store 能力（file/postgres/redis 之一）
- `src/infra/exceptions.py`（结构化错误基线）

## Acceptance

- [ ] `POST /v1/task-codes/redeem` 按 v1 合同返回 `job_id`/`token`/`expires_at`/`is_idempotent`，且不包含 `entitlement`
- [ ] 同一 `task_code` 重复 redeem 返回同一 `job_id` + 同一 `token`
- [ ] `expires_at` 满足“滑动过期：now + 7 days”的语义
- [ ] `ruff check .` 通过
- [ ] `pytest -q` 通过，且至少包含：
  - [ ] redeem 幂等测试
  - [ ] token 不轮换测试
  - [ ] 过期时间刷新语义测试（可用冻结时间/注入 clock 方式实现）

