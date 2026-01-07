# Proposal: issue-116-stress-tests-exec

## Why
Stress tests should validate the full stress scenario (including actual job execution). The current suite
can enqueue jobs without ensuring workers drain the queue, which undercuts the scenario intent and can
cause unbounded queue growth in long runs.

## What Changes
- Update stress load test to wait for configured run jobs to reach terminal status before stopping workers.
- Update stability loop to drain the worker queue during the run (bounded, per-iteration).

## Impact
- Affected code:
  - `tests/stress/test_load_100_concurrent_users.py`
  - `tests/stress/test_24h_stability.py`
- Breaking change: NO
- User benefit: Stress tests match the intended scenario (enqueue + execute), improving signal quality.
