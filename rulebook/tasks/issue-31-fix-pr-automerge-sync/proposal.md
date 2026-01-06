# issue-31-fix-pr-automerge-sync — Proposal

修复 `scripts/agent_pr_automerge_and_sync.sh` 在新版 `gh` 下无法查询 `merged` 字段的问题，改用 `mergedAt` 判断 PR 是否已合并，确保自动化交付链路稳定。

