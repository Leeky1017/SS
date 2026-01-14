# Proposal: issue-468-align-c006-error-codes

## Why
当前前端会把内部技术术语与失败细节直接暴露给用户（例如内部字段名、实现路径与状态信息），且错误提示缺少统一代号与可操作指引，需要统一改为“数字代号 + 友好提示”，并集中管理映射以便排查。

## What Changes
- Add an internal error-code index `ERROR_CODES.md` (internal-only).
- Add a frontend mapping module that renders all failures as `错误代号 EXXXX：...` and never displays backend `message`/`detail` directly.
- Audit and update user-facing UI copy to remove internal technical terminology.
- Ensure backend errors expose stable `error_code` values for frontend mapping.

## Impact
- Affected specs: `openspec/specs/ss-ux-loop-closure/spec.md`
- Affected code: frontend error handling + user-facing copy; backend error shaping (if needed)
- Breaking change: NO
- User benefit: clearer, implementation-agnostic guidance and consistent numeric error codes
