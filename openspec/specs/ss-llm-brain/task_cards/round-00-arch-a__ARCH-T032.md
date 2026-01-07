# [ROUND-00-ARCH-A] ARCH-T032: LLM 调用 artifacts（prompt/response/元数据/脱敏）

## Metadata

- Issue: #21 https://github.com/Leeky1017/SS/issues/21
- Epic: #12 https://github.com/Leeky1017/SS/issues/12
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Goal

所有 LLM 调用必须可追溯、可复现：把 prompt/response 与元数据落到 artifacts，并提供脱敏策略。

## In scope

- LLM artifacts 目录结构与文件格式定义（jsonl 或 json + text）
- 记录：model、temperature、seed、耗时、token 估计、错误信息（失败时）
- 脱敏策略：对输入数据路径、用户隐私字段的最小暴露；日志不泄露

## Dependencies & parallelism

- Hard dependencies: #16（artifacts index 合同）
- Parallelizable with: #18 / #24 / #20（实现层面会被 PlanService/DraftService 复用）
- Security coupling: 与 #27 强相关（脱敏与敏感字段治理）

## Acceptance checklist

- [x] 成功/失败两条路径均落盘 artifacts
- [x] job.json artifacts 索引更新
- [x] 脱敏策略覆盖敏感字段与 secrets（日志与 artifacts）
- [x] `openspec/_ops/task_runs/ISSUE-21.md` 记录关键命令与输出

## Completion

- Status: Done
- PR: https://github.com/Leeky1017/SS/pull/50
- Run log: `openspec/_ops/task_runs/ISSUE-21.md`
- Summary: persist LLM prompt/response artifacts + metadata, with redaction guarantees
