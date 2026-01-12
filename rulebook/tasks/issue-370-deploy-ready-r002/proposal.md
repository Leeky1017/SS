# Proposal: issue-370-deploy-ready-r002

## Why
Production deployment requires predictable, auditable output artifacts for download and post-processing, but the current do-template library’s real output formats and naming/kind consistency are unclear. This audit grounds DEPLOY-READY-R031 (unified output formatter) with evidence from `assets/stata_do_library/`.

## What Changes
- Add an evidence-backed audit report summarizing output formats declared in `do/meta/*.meta.json` and output behaviors observed in sampled template sources.
- Produce a capability matrix for `csv/xlsx/dta/docx/pdf/log/do` and highlight gaps/mismatches (meta vs implementation).
- Identify artifact kind / naming consistency problems and recommend a remediation strategy for DEPLOY-READY-R031.
- Update the task card metadata to link Issue #370 and record completion evidence.

## Impact
- Affected specs: `openspec/specs/ss-deployment-docker-readiness/spec.md`, `openspec/specs/ss-job-contract/spec.md`
- Affected code: none (audit-only)
- Breaking change: NO
- User benefit: A clear, actionable statement of supported output formats and the remediation work needed for production-ready artifact handling.
