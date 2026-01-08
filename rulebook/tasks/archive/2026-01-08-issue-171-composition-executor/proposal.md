# Proposal: issue-171-composition-executor

## Why
Support "composition plans" (plans without a `run_stata` step) end-to-end: the worker must be able to execute multi-step pipelines that merge/append datasets, run steps in isolated runs, and record a complete evidence chain for auditability.

## What Changes
- Add a composition execution engine that validates `dataset_ref`, computes execution order from `depends_on`, materializes per-step inputs, and writes pipeline-level summaries.
- Extend the Stata runner boundary to support step-specific inputs directories for safe, deterministic input materialization.
- Route worker execution to the composition executor when a plan has no `run_stata` step.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-3.3__composition-executor-modes-and-evidence.md`
- Affected code: `src/domain/composition_exec/`, `src/domain/worker_plan_executor.py`, `src/domain/stata_runner.py`, `src/infra/local_stata_runner.py`
- Breaking change: NO (new behaviors activate only for composition plans)
- User benefit: Multi-step empirical pipelines become executable and auditable (step-level run dirs + pipeline summary).

## Summary

Implement a composition plan execution engine that:
- computes execution order from plan dependencies,
- materializes `dataset_ref` bindings into each step workspace,
- supports merge/append, parallel, and conditional behaviors,
- and writes complete evidence (per-step run dirs + pipeline-level `composition_summary.json`).

## Impact

- Worker execution path gains a composition-aware branch for plans without a `run_stata` step.
- Adds new artifact kinds for composition summaries and products.
- Adds end-to-end tests for each supported composition mode.
