# issue-1-ss-infra-bootstrap — Proposal

## Summary

为 SS 仓库引入 OpenSpec + Rulebook + GitHub 的基础设施与硬门禁：
- 新增 AGENTS 规则与贡献流程文档
- 新增 GitHub checks（`ci`/`openspec-log-guard`/`merge-serial`）
- 新增 OpenSpec 操作日志落盘目录与模板
- 新增 Rulebook 任务目录骨架

## Impact

- 开发/交付流程标准化：Issue → Branch → PR → Checks → Auto-merge。
- 未来所有功能迭代都可追溯（spec + run log）。

