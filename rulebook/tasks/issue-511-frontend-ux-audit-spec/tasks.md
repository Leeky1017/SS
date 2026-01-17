# Tasks: issue-511-frontend-ux-audit-spec

## Spec-first

- [ ] Add `openspec/specs/ss-frontend-ux-audit/spec.md` (Purpose/Requirements/Scenarios; strict OpenSpec format)
- [ ] Add task cards under `openspec/specs/ss-frontend-ux-audit/task_cards/` to break work into implementable chunks
- [ ] Ensure task cards include: scope, acceptance checklist, dependencies/risks, and links to related specs

## Validation

- [ ] Run `openspec validate --specs --strict --no-interactive`

## Delivery

- [ ] Update `openspec/_ops/task_runs/ISSUE-511.md` with commands + key outputs
- [ ] Run `scripts/agent_pr_preflight.sh` and record output in `openspec/_ops/task_runs/ISSUE-511.md`
- [ ] Create PR with body containing `Closes #511`, enable auto-merge, and backfill links in `openspec/_ops/task_runs/ISSUE-511.md`

