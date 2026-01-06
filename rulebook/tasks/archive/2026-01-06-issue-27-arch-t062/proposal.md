# Proposal: issue-27-arch-t062

## Why
SS 已提供 artifacts 下载、LLM artifacts 落盘与 Stata runner 执行边界；需要在早期固化安全红线：路径遍历/符号链接逃逸、Do-file 注入与敏感信息泄露，避免后续扩展时返工与引入高危漏洞。

## What Changes
- Enforce job-relative path rules for artifact read/write (no absolute path / `..` traversal; prevent symlink escape).
- Redact sensitive values before persisting LLM artifacts and before logging potentially sensitive fields.
- Add a minimal do-file safety gate for runner execution (reject unsafe statements/paths early).
- Add focused tests covering typical attack inputs.

## Impact
- Affected specs:
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`
- Affected code:
  - `src/domain/artifacts_service.py`
  - `src/infra/job_store.py`
  - `src/infra/llm_tracing.py`
  - `src/infra/stata_run_support.py`
  - `src/infra/stata_run_attempt.py`
  - `tests/unit/`
- Breaking change: YES (unsafe `rel_path` now rejected for read/write)
- User benefit: safer defaults; typical traversal/injection inputs fail fast with structured errors and test coverage.
