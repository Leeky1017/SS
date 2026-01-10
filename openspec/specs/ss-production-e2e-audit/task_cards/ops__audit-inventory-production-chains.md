# [OPS] PROD-AUDIT-01: Inventory production chains (wired vs present)

## Metadata

- Priority: P0
- Issue: #274 https://github.com/Leeky1017/SS/issues/274
- Spec: `openspec/specs/ss-production-e2e-audit/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`

## Goal

Produce an evidence-backed inventory of SS “production chains”:
- `/v1/**` chain (API + worker)
- any non-`/v1` HTTP chain
- do-template library chain (assets → index → selection → rendering → runner execution)

And clearly separate:
- wired components (reachable/invoked at runtime)
- present-but-not-wired components (exist in repo but not invoked)

## In scope

- Enumerate routes by reading `src/api/**` and the application entrypoint wiring.
- Identify any non-`/v1` endpoints and classify whether they are reachable in the running API.
- Trace do-template library usage from selection to runner, including where template assets are loaded from.

## Out of scope

- Fixing any discovered wiring issues (audit-only).

## Acceptance checklist

- [ ] Inventory includes `/v1` routes used by the E2E journey and their handler locations.
- [ ] Inventory includes any non-`/v1` routes and states whether they are reachable in production start mode.
- [ ] Inventory states whether `assets/stata_do_library/**` is executed in the E2E chain, and where the integration boundary is.
- [ ] Evidence captured in `openspec/_ops/task_runs/ISSUE-274.md` with command output snippets and path references.

