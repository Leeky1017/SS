# Scalability: Job store sharding strategy

## Background

The audit noted that large job volumes can overwhelm a single directory layout, requiring a sharding strategy to avoid filesystem limitations and degraded performance.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “Job Store 分片策略缺失”

## Goal

Define and implement a sharded path scheme for the file backend (or the chosen backend), while maintaining backward compatibility for existing jobs.

## Dependencies & parallelism

- Hard dependencies: `phase-1__data-version-upgrade.md` (backward compatibility strategy should align with migration policy)
- Parallelizable with: ops track tasks

## Acceptance checklist

- [ ] Define the shard function and directory layout (e.g., prefix-based shard directories)
- [ ] Existing jobs remain loadable without manual moves, or a safe migration path is provided
- [ ] Tests cover path resolution and compatibility behavior
- [ ] Document operational implications (backup/restore, cleanup, listing performance)
- [ ] Implementation run log records `ruff check .` and `pytest -q`

## Estimate

- 4-6h

