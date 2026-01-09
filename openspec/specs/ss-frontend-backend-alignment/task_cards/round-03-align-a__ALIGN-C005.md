# [ROUND-03-ALIGN-A] ALIGN-C005: User-journey 级测试补齐（以前端真实调用顺序为准，锁回归）

## Problem

即使单点接口测试通过，缺少“前端真实调用顺序”的 user-journey 测试时，容易出现：
- 某个接口改动字段名/状态码导致前端链路断裂，但单测未覆盖
- 鉴权与幂等语义在组合场景下失真（例如：redeem→upload→preview 的 token 传递）
- Step 3 阻断项在集成路径被绕过

## Goal

新增 user-journey 级 pytest 覆盖，按 Desktop Pro 前端真实顺序锁定回归：
- redeem → token
- inputs/upload（带 token）
- draft/preview（可覆盖 202→200）
- draft/patch（带 token）
- confirm（带 token + answers/feedback）
-（可选）status/artifacts 的最小校验

## In scope

- 新增/完善 integration tests（或 user-journey tests）：
  - 使用真实 HTTP 路由（FastAPI TestClient），不直接调用 domain service
  - 覆盖 missing-token / wrong-token 的拒绝路径，断言稳定 `error_code`
  - 覆盖 Step 3 阻断项：未解锁时 confirm 必须失败；解锁后成功
- 复用固定测试数据（CSV/Excel fixture）以模拟真实上传

## Out of scope

- 前端 e2e（Playwright/Cypress）与 UI 截图回归
- 性能/压力测试
- Worker 执行到产物下载的全链路（另开卡）

## Dependencies

- ALIGN-C002（redeem + token）
- ALIGN-C003（鉴权覆盖）
- ALIGN-C004（Step3 preview/patch/confirm 对齐 + 阻断校验）

## Acceptance

- [ ] `pytest -q` 包含至少一个 user-journey 测试覆盖：
  - [ ] redeem→token→upload→preview→patch→confirm（严格按顺序）
  - [ ] 无 token/错 token 的拒绝路径（稳定 `error_code`）
  - [ ] Step 3 阻断项无法绕过（confirm 被后端拒绝）
- [ ] 测试命名遵循 `test_<function><scenario><expected>()` 规范
- [ ] `ruff check .` 与 `pytest -q` 在 CI 下均通过

