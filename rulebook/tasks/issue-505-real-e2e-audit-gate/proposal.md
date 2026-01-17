# Proposal: issue-505-real-e2e-audit-gate

## Why
Windows 47.98 真实环境的 repo-native E2E runner 仍在走旧的 `/confirm` happy-path，无法满足 `ss-production-e2e-audit` 的“审计级全覆盖”要求（显式 plan/freeze + run、真实依赖证据、以及重启可恢复性）。

## What Changes
- 升级 `scripts/ss_ssh_e2e/flow.py`：happy-path 改为 plan/freeze + run，并增加强断言（plan.json/llm.meta/run.meta.json/stata.log）与 1 条结构化失败负例（PLAN_FREEZE_MISSING_REQUIRED）。
- 升级 `scripts/ss_windows_release_gate.py`：以“新全覆盖 E2E + restart recoverability”作为唯一门禁；失败自动 rollback，并落盘证据路径。

## Impact
- Affected specs: `openspec/specs/ss-production-e2e-audit/spec.md`
- Affected code: `scripts/ss_ssh_e2e/*`, `scripts/ss_windows_release_gate.py`
- Breaking change: YES（移除 confirm 驱动链路作为可选路径）
- User benefit: 生产发布门禁具备可审计证据与可恢复性验证

