# Proposal: issue-477-api-contract-alignment

## Why
静态审计发现前后端 API 契约存在 5 处不一致，导致前端类型无法表达后端实际字段/值域，
并且 `draft/preview` 存在透传 list(...) 缺少类型守卫的高风险 500 路径，需要尽快对齐与加固。

## What Changes
- 对齐 `frontend/src/api/types.ts` 与后端 schema：补齐缺失字段与更精确的 `JsonValue` 类型。
- 收紧 `DraftPreview*` 响应的 `status` 值域为 `Literal[...]`，确保前端 discriminator 稳定。
- 在 `src/api/draft.py` 复用 `list_of_dicts()` 做透传字段类型守卫，避免异常形态导致 500。

## Impact
- Affected specs: none
- Affected code: `frontend/src/api/types.ts`, `src/api/schemas.py`, `src/api/draft.py`
- Breaking change: NO
- User benefit: 前后端契约一致，类型检查更强；避免 draft preview 因异常数据形态触发 500
