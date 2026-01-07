# Phase 1: Graceful shutdown (API + worker)

## Background

The audit found that the API and worker entrypoints lack a coordinated graceful shutdown flow. Abrupt shutdown can leave queue claims unacked and jobs stuck in `running`, and can interrupt in-flight LLM/Stata work without bounded cleanup.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏优雅关闭与资源清理”
- `Audit/03_Integrated_Action_Plan.md` → “任务 1.5：优雅关闭机制”

## Goal

Add a bounded and observable graceful shutdown path for both API and worker processes:
- stop accepting new work
- allow in-flight work to complete within a timeout (or record an interrupted state)
- cleanly release resources and emit shutdown logs

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: data migrations, concurrency protection, typing gate

## Acceptance checklist

- [ ] API process implements lifecycle hooks and emits structured startup/shutdown events
- [ ] Worker responds to SIGTERM/SIGINT and stops claiming new jobs after shutdown begins
- [ ] In-flight work is bounded by a timeout and results in explicit logs and job status outcomes
- [ ] Shutdown behavior is covered by tests where practical (and at minimum documented with reproducible steps)
- [ ] Implementation run log records `ruff check .`, `pytest -q`, and `openspec validate --specs --strict --no-interactive`

## Estimate

- 4-6h

