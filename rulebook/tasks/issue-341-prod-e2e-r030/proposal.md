# Proposal: issue-341-prod-e2e-r030

## Why
Plan freeze currently allows plans to be frozen (and later run) even when the draft still contains blocking unknowns or the selected do-template has missing required parameters. This causes “blocking unknowns” to slip into the worker, producing non-diagnosable failures or silent wrong runs.

## What Changes
- Make `/v1/jobs/{job_id}/plan/freeze` reject missing required inputs as a hard gate.
- Gate checks cover both v1 draft blockers (stage questions + blocking open_unknowns) and do-template meta required params.
- Failures return a structured error payload suitable for retry after correction.

## Impact
- Prevents freezing/running plans with blocking unknowns or missing required template params.
- Makes “missing parameters yield structured errors” audit scenario diagnosable and retryable.

