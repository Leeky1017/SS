# [ROUND-00-ARCH-A] ARCH-T051: StataRunner port + LocalStataRunner subprocess

## Metadata

- Issue: #24 https://github.com/Leeky1017/SS/issues/24
- Epic: #14 https://github.com/Leeky1017/SS/issues/14
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Goal

把 Stata 执行封装为单一端口，支持本地 subprocess 执行，并产出可追溯 artifacts。

## In scope

- domain 定义 StataRunner 接口与 RunResult
- infra 实现 LocalStataRunner（subprocess），工作目录限制在 runs/<run_id>/
- 超时/非 0 退出码映射为结构化错误并写入 artifacts

## Dependencies & parallelism

- Hard dependencies: #16（run attempt/workspace 合同）
- Parallelizable with: #18 / #21 / #17（在 #16 之后）
- Security coupling: 与 #27 强相关（隔离与路径边界）

## Acceptance checklist

- [ ] domain/intra 分层正确（port 在 domain，subprocess 在 infra）
- [ ] 执行 cwd 固定在 run attempt 工作目录，禁止越界写入
- [ ] 测试不依赖真实 Stata（用 fake runner）；可选加本地集成测试
- [ ] `openspec/_ops/task_runs/ISSUE-24.md` 记录关键命令与输出
