# DEPLOY-READY-R030 — do-template 数据形态能力矩阵（更新版）

## Baseline

- 上一版（R001 审计产物）：`rulebook/tasks/archive/2026-01-12-issue-372-deploy-ready-r001/evidence/do_template_data_shape_audit.md`

## 本次更新（R030）

- 补齐 shape-sensitive 模板的 meta `tags`：
  - `T14`：新增 `wide`
  - `T30` / `T31`：新增 `long`（仍保留 `panel`）
- 渲染阶段支持 `__ID_VAR__` / `__PANELVAR__` 作为别名（降低面板模板调用侧耦合）：
  - 代码：`src/domain/do_template_rendering.py`
  - 回归：`tests/test_do_template_run_service.py`

## Meta 覆盖信号（基于 tags）

- `wide`：2（`T06`, `T14`）
- `long`：3（`T06`, `T30`, `T31`）
- `panel`：39（维持 R001 结论）

说明：`tags` 仅表达“形态敏感/关键前置”的 machine-readable 信号；并不意味着未打标的模板在该形态下不可运行。

## 宽 / 长 / 面板能力矩阵（结论 + 证据指针）

| 数据形态 | 结论 | 关键路径覆盖（模板） | 证据指针 |
|---|---|---|---|
| **Wide（宽表）** | **MUST（形态敏感模板显式打标）** | `T14`（paired before/after → wide-only）；`T06`（可将 long↔wide） | `assets/stata_do_library/do/meta/T14_ttest_paired.meta.json`；`assets/stata_do_library/do/meta/T06_reshape_wide_long.meta.json` |
| **Long（长表）** | **MUST（转换链路 + 面板关键路径）** | `T06`（wide↔long 转换）；`T30`（xtset 前置检查）；`T31`（xtreg FE） | `assets/stata_do_library/do/meta/T06_reshape_wide_long.meta.json`；`assets/stata_do_library/do/meta/T30_panel_setup_check.meta.json`；`assets/stata_do_library/do/meta/T31_panel_fe_basic.meta.json` |
| **Panel（面板）** | **MUST（覆盖良好）** | 面板预检/设置/估计器等（R001 详表）；本次仅补齐 `long` 打标 + 参数别名鲁棒性 | R001：`rulebook/tasks/archive/2026-01-12-issue-372-deploy-ready-r001/evidence/do_template_data_shape_audit.md`；示例：`T30` / `T31` |

## 回归钩子（用于后续审计自动化）

- tags 覆盖回归：`tests/test_do_template_data_shape_tags.py`
- 渲染别名回归：`tests/test_do_template_run_service.py`

