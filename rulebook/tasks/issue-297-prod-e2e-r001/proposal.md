# Proposal: issue-297-prod-e2e-r001

## Why
- Production remediation requirement: SS MUST NOT expose any non-`/v1` business endpoints; legacy unversioned `/jobs/**` creates a second HTTP chain (audit finding F005).

## What Changes
- Stop mounting unversioned business routers at runtime (remove legacy `/jobs/**` surface).
- Keep ops endpoints (`/health/*`, `/metrics`) reachable, but separated from business routers.

## Impact
- Affected specs:
  - `openspec/specs/ss-production-e2e-audit-remediation/spec.md` (F005 remediation requirement)
- Affected code:
  - `src/api/routes.py`
  - `src/main.py`
  - `tests/**` (routing regression test)
- Breaking change: YES (legacy unversioned `/jobs/**` removed)
- User benefit: single authoritative business HTTP surface (`/v1/**`), simpler auth/guard maintenance and reduced attack surface.
