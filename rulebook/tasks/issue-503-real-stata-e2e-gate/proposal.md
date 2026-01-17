# Proposal: issue-503-real-stata-e2e-gate

## Why
- Windows Server deploy validation currently stops at `GET /health/ready`, which can be green even when the real `/v1` user journey (redeem → upload → draft → run → artifacts) fails due to worker/queue/Stata/LLM/runtime issues.
- We need a reproducible, black-box, real-dependency E2E gate that can run against `47.98.174.3` and automatically collect enough evidence on failures to attribute the responsibility domain (API / worker / queue / Stata / inputs / LLM).

## What Changes
- Add a repo-native remote E2E runner that:
  - uses SSH port-forwarding to reach the runtime API on `127.0.0.1:8000`
  - executes the full v1 flow (redeem → upload → preview → draft/patch/confirm → poll → artifacts)
  - verifies key artifacts (`stata.do`, `stata.log`, `run.meta.json`; and `run.error.json` when failed)
  - collects remote diagnostics on failure (`schtasks`, queue depth, deploy log tail)
- Replace the release/deploy post-switch gate to require this real E2E (no dual-path health-only fallback).

## Impact
- Affected specs: `openspec/specs/ss-production-e2e-audit/spec.md` (evidence expectations), plus this task spec pack.
- Affected code: `scripts/` (remote E2E runner + release gate wiring).
- Breaking change: YES (deploy/release gate becomes stricter; “ready” now means “real v1 flow succeeds and artifacts verified”).
- User benefit: production go/no-go is deterministic, repeatable, and diagnosable.
