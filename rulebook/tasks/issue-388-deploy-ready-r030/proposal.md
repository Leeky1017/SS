# Proposal: issue-388-deploy-ready-r030

## Why
DEPLOY-READY-R001 审计确认 do-template 库具备 wide/long/panel 的关键路径能力，但 meta 层对数据形态的 machine-readable 标注严重不足（wide/long 仅由少数模板声明），且面板模板的 ID 参数命名存在 `__ID_VAR__`/`__PANELVAR__` 分裂，增加自动化填参与误用风险。

## What Changes
- 为形态敏感模板补齐 meta `tags`（wide/long/panel）以支撑可审计能力矩阵与回归。
- 渲染阶段将 `__ID_VAR__` 与 `__PANELVAR__` 视为别名，降低调用侧耦合。
- 增加最小可复现的 audit/pytest 证据与能力矩阵更新。

## Impact
- Affected specs: `openspec/specs/ss-deployment-docker-readiness/spec.md`, `openspec/specs/ss-do-template-library/spec.md`
- Affected code: `assets/stata_do_library/do/meta/*.meta.json`, `src/domain/do_template_rendering.py`, `tests/*`
- Breaking change: NO
- User benefit: wide/long/panel 形态能力更可审计，面板类模板参数名更稳健（减少错填/漏填）。
