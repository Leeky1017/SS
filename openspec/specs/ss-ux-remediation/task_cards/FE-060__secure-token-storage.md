# Task Card: FE-060 Secure token storage

- Priority: P2-MEDIUM
- Area: Frontend / Security
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Token 存储不安全/不透明，用户无法控制。

## 技术分析

- 现状：
  - token 使用 `localStorage` 持久化（按 `jobId` 存储），任何同源 XSS 都可以直接读取并外传；同时 localStorage 默认长期保留，暴露窗口更大。
  - token 读取路径分散（请求时自动附加 `Authorization`），用户层面缺少可见的“当前已登录/已持有 token”状态与清理入口。
  - 清理策略不完整：仅在部分路径调用清理（如 401/403 或 reset），多 jobId token 可能残留。
- 影响：一旦发生 XSS 或同源脚本被注入，攻击者可窃取 token 并冒用用户身份访问/操作任务。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/state/storage.ts`
  - `frontend/src/api/client.ts`

## 解决方案

1. 最小化 token 暴露面（仅必要时读取）
2. 提供清除/过期策略与用户提示

## 验收标准

- [ ] token 可被一键清除
- [ ] 401/403 时自动清除并引导重新兑换

## Dependencies

- 无
