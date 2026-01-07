# [ROUND-00-ARCH-A] ARCH-T061: 结构化日志规范 + 配置化 log_level

## Metadata

- Issue: #26 https://github.com/Leeky1017/SS/issues/26
- Epic: #15 https://github.com/Leeky1017/SS/issues/15
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-constitution/01-principles.md`
  - `openspec/specs/ss-delivery-workflow/spec.md`

## Goal

统一日志事件码与字段，并把 log_level 等从 Config 注入，不到处读环境变量。

## Dependencies & parallelism

- Hard dependencies: 无（跨切任务）
- Recommended timing: 在 worker 入口（#23）落地前后都可做，但会触及 main/worker 初始化，容易与并行 PR 冲突

## Acceptance checklist

- [x] 事件码规范（SS_XXX_YYY）与必带字段（job_id/run_id/step）明确
- [x] main/worker 初始化结构化日志配置，log_level 来自 `src/config.py`
- [x] 单元测试/静态检查确保不出现吞异常与无上下文日志
- [x] `openspec/_ops/task_runs/ISSUE-26.md` 记录关键命令与输出

## Completion

- Status: Done
- PR: https://github.com/Leeky1017/SS/pull/63
- Run log: `openspec/_ops/task_runs/ISSUE-26.md`
- Summary: structured JSON logging contract + shared config + unit tests
