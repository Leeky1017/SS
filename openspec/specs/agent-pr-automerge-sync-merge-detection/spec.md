# Spec — agent_pr_automerge_and_sync merge detection

## Goal

让 `scripts/agent_pr_automerge_and_sync.sh` 在新版 `gh` CLI 下稳定判断 PR 已合并，并完成后续的 controlplane sync。

## Requirements

- 脚本 MUST 使用 `gh pr view --json mergedAt`（或等价字段）判断 PR 是否已合并。
- 若 PR 未合并，脚本 MUST 继续轮询，直到合并或超时（保持现有重试节奏即可）。
- 若 PR 已合并，脚本 MUST 继续执行 controlplane sync，并校验 `main == origin/main`。
- `ruff check .` 与 `pytest -q` MUST 在 PR checks 中通过。

## Scenarios (verifiable)

### Scenario: merged PR is detected correctly

Given a PR has checks passing and is merged  
When running `scripts/agent_pr_automerge_and_sync.sh`  
Then the script does not error on unknown JSON fields and proceeds to sync controlplane `main`.

