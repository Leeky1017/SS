# SS Roadmap — Index

目标：把“主脑形态”拆成可交付的纵切任务，每个任务都能独立验收并保持仓库可维护性。

## Roadmap 总览

- 主 Issue：#9（master brain 初版）
- 当前开发路线（Epics）：
  - #10：Job 模型 + job.json v1 + 状态机
  - #11：API 扩展（status/artifacts/run trigger）
  - #12：LLM Brain（PlanService + artifacts）
  - #13：Worker/Queue（claim + retry + run attempts）
  - #14：Stata Runner（do-file + 执行 + 产物）+ Do 模板库
  - #15：Observability & Security 基线

## 子 Issue（已创建）

- Epic #10：#16、#17
- Epic #11：#18、#19
- Epic #12：#20、#21
- Epic #13：#22、#23
- Epic #14：#24、#25、#36
- Epic #15：#26、#27

## Task cards（Issue 蓝图）

task card 用于把每个子 Issue 写成 agent 更好消费的“蓝图卡片”，但不替代：
- GitHub Issue（并发/交付入口）
- Rulebook task（执行清单）

存放规则（按 spec 分散）：
- `openspec/specs/<spec-id>/task_cards/*.md`

索引与执行顺序：
- `openspec/specs/ss-roadmap/task_cards_index.md`
- `openspec/specs/ss-roadmap/execution_plan.md`

## 哪些 spec 需要“做任务”

面向代码交付的主责 specs（直接对应 roadmap 子 Issue）：
- `openspec/specs/ss-job-contract/`（#16）
- `openspec/specs/ss-state-machine/`（#17）
- `openspec/specs/ss-api-surface/`（#18, #19）
- `openspec/specs/ss-llm-brain/`（#20, #21）
- `openspec/specs/ss-worker-queue/`（#22, #23）
- `openspec/specs/ss-stata-runner/`（#24, #25）
- `openspec/specs/ss-do-template-library/`（#36）
- `openspec/specs/ss-observability/`（#26）
- `openspec/specs/ss-security/`（#27）

流程/标准/参考 specs（不是 roadmap 的代码交付任务本体）：
- `openspec/specs/ss-constitution/`（总纲与硬约束）
- `openspec/specs/ss-delivery-workflow/`（交付流程门禁）
- `openspec/specs/openspec-writing-standard/`（写作规范）
- `openspec/specs/openspec-officialize/`（工具化对齐）
- `openspec/specs/stata-service-legacy-analysis/`（legacy 仅作语义/边界输入）
