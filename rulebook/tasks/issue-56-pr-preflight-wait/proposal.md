# Proposal: ISSUE-56 PR preflight（冲突预警 + roadmap 依赖等待）

## Summary
- ADDED: `scripts/agent_pr_preflight.sh` + `scripts/agent_pr_preflight.py`（deps + overlap 检测）
- ADDED: `src/utils/roadmap_dependencies.py`（从 roadmap execution plan 解析 hard deps）
- MODIFIED: `scripts/agent_pr_automerge_and_sync.sh`（默认预检；阻塞时创建 draft 并等待）
- MODIFIED: `AGENTS.md` / `openspec/specs/ss-delivery-workflow/spec.md` / `openspec/specs/ss-delivery-workflow/README.md`

## Rationale
多 agent 并行开发时，提前在 PR 前预警“同文件重叠”与“hard dependency 未完成”，避免把冲突/返工推迟到合并态。

