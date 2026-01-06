# [ROUND-00-ARCH-A] ARCH-T052: DoFileGenerator（从 plan 生成 do-file）

## Metadata

- Issue: #25 https://github.com/Leeky1017/SS/issues/25
- Epic: #14 https://github.com/Leeky1017/SS/issues/14
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-llm-brain/spec.md`

## Goal

从 LLMPlan 生成可执行 do-file（最小子集），为后续丰富分析能力铺路。

## In scope

- DoFileGenerator 输入为 plan + inputs manifest，输出 do-file 文本与预期产物列表
- 最小支持：载入数据、describe/summarize、导出基础表格到 artifacts
- 生成结果可复现：同 plan 产出同 do-file（排序/格式稳定）

## Dependencies & parallelism

- Hard dependencies: #20（输入是 plan）+ #16（inputs/artifacts 合同）
- Parallelizable with: #22 / #24 / #36

## Acceptance checklist

- [ ] do-file 生成确定性（同输入 → 同输出）
- [ ] 最小能力可跑通并产生基础 artifacts（表格/日志）
- [ ] 单元测试覆盖：稳定性与边界输入
- [ ] `openspec/_ops/task_runs/ISSUE-25.md` 记录关键命令与输出
