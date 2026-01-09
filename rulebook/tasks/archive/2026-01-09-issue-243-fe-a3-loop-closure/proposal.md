# Proposal: issue-243-fe-a3-loop-closure

## Why
Frontend currently stops at Step 1/Step 2 placeholder, so users cannot upload data, validate columns, precheck the blueprint, confirm, or download artifacts; this blocks the minimum `/v1` loop closure required by `ss-frontend-desktop-pro`.

## What Changes
- Implement FE-C004/005/006 in `frontend/`: Step 2 upload+preview, Step 3 blueprint precheck (with downgrade), and job status + artifacts list/download.
- Extend the frontend `/v1` API client types to cover draft preview pending + Step 3 fields, and add best-effort draft patch support.
- Persist snapshots to support refresh-resume and make all error states recoverable (message + request id + retry/redeem).

## Impact
- Affected specs: `openspec/specs/ss-frontend-desktop-pro/spec.md`, `openspec/specs/frontend-stata-proxy-extension/spec.md`, `openspec/specs/ss-job-contract/spec.md`
- Affected code: `frontend/src/**`
- Breaking change: NO
- User benefit: End-to-end usable loop: redeem/create → upload → preview → blueprint precheck → confirm → poll status → download artifacts.
