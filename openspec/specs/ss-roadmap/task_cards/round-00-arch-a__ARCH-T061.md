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

## Acceptance checklist

- [ ] 事件码规范（SS_XXX_YYY）与必带字段（job_id/run_id/step）明确
- [ ] main/worker 初始化结构化日志配置，log_level 来自 `src/config.py`
- [ ] 单元测试/静态检查确保不出现吞异常与无上下文日志
- [ ] `openspec/_ops/task_runs/ISSUE-26.md` 记录关键命令与输出

