# TG08_psm_sensitivity — 敏感性分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG08 |
| **Slug** | psm_sensitivity |
| **名称(中文)** | 敏感性分析 |
| **Name(EN)** | PSM Sensitivity |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Rosenbaum sensitivity analysis for PSM

## 使用场景

- 关键词：psm, sensitivity, rosenbaum, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TREATMENT_VAR__` | string | 是 | Treatment variable |
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__GAMMA_MAX__` | number | 否 | Max gamma value |
| `__GAMMA_STEP__` | number | 否 | Gamma step |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG08_sensitivity.csv | table | Sensitivity results |
| fig_TG08_gamma_bounds.png | figure | Gamma bounds |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| rbounds | ssc | Rosenbaum bounds |

## 示例

```stata
* Template: TG08_psm_sensitivity
* Script: tasks/do/TG08_psm_sensitivity.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

