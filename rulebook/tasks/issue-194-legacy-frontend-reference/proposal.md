# Proposal: issue-194-legacy-frontend-reference

## Why
Provide a stable, in-repo legacy frontend reference for SS frontend development discussions and UI reuse without depending on the old repository layout.

## What Changes
- Add a reference-only copy of legacy `stata_service/frontend` under `legacy/stata_service/frontend/` (excluding `node_modules` and build outputs).
- Add a short reference note and local `.gitignore` within the legacy folder.

## Impact
- Affected specs: None
- Affected code: `legacy/stata_service/frontend/**` (new)
- Breaking change: NO
- User benefit: Faster SS frontend prototyping and consistent UI reference
