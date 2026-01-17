# Proposal: issue-509-data-persist-datasets

## Why
将用户提供的真实面板数据文件纳入版本库，保证问题可复现、可追溯，并为后续补齐 E2E/回归测试提供稳定输入。

## What Changes
- 提交 `数据文件（测试）/` 下的用户数据文件到 git，确保不会因回滚/环境变化而丢失。
- 新增并维护本次 Issue 的运行记录 `openspec/_ops/task_runs/ISSUE-509.md`。

## Impact
- Affected specs: none
- Affected code: none (data-only + run log)
- Breaking change: NO
- User benefit: 数据持久化；问题复现与排查更可靠
