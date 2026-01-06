# Proposal: issue-25-arch-t052-dofile-generator

## Why

SS needs deterministic, auditable do-file generation so the same plan + inputs always produces the same runnable Stata script and expected artifacts.

## What Changes

- Introduce a deterministic `DoFileGenerator` that converts an `LLMPlan` + inputs manifest into an executable Stata do-file.
- Provide a minimal descriptive-analysis template: load data, describe/summarize, export a basic table artifact.
- Keep outputs reproducible (stable ordering/format) and cover edge cases with unit tests.

## Impact
- Affected specs: `openspec/specs/ss-stata-runner/spec.md`
- Affected code: `src/domain/`, `src/infra/`, `tests/`
- Breaking change: NO
- User benefit: Runnable, auditable, deterministic do-file generation as the foundation for richer analysis steps.
