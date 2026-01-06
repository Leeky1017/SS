# [ROUND-00-ARCH-A] ARCH-T062: 安全红线落地（路径/注入/敏感信息）

## Metadata

- Issue: #27 https://github.com/Leeky1017/SS/issues/27
- Epic: #15 https://github.com/Leeky1017/SS/issues/15
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`

## Goal

在早期就固化安全边界：路径遍历、命令注入、敏感信息泄露等，避免后续返工。

## Acceptance checklist

- [ ] artifacts 下载与路径解析防 `..` 与符号链接逃逸
- [ ] LLM artifacts 与日志脱敏（不落盘 key/token/隐私字段）
- [ ] do-file 生成与 runner 执行限制工作目录与可写范围
- [ ] 测试覆盖：典型攻击输入被拒绝
- [ ] `openspec/_ops/task_runs/ISSUE-27.md` 记录关键命令与输出

