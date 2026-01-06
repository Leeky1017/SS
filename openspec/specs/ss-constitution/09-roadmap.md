# 09 — 路线图（Epics & Sub-Issues）

目标：把“主脑形态”拆成可交付的纵切任务，每个任务都能独立验收并保持仓库可维护性。

## Roadmap 总览

- 主 Issue：#9（已交付 master brain 初版）
- 当前开发路线（Epics）：
  - #10：Job 模型 + job.json v1 + 状态机
  - #11：API 扩展（status/artifacts/run trigger）
  - #12：LLM Brain（PlanService + artifacts）
  - #13：Worker/Queue（claim + retry + run attempts）
  - #14：Stata Runner（do-file + 执行 + 产物）
  - #15：Observability & Security 基线

## 子 Issue（已创建）

- Epic #10：#16、#17
- Epic #11：#18、#19
- Epic #12：#20、#21
- Epic #13：#22、#23
- Epic #14：#24、#25
- Epic #15：#26、#27

## DoD（每个 Issue 的 Definition of Done）

- 有对应的 spec（OpenSpec）与 tasks（Rulebook）
- `ruff check .` + `pytest -q` 全绿
- run log `openspec/_ops/task_runs/ISSUE-N.md` 记录关键命令与输出

