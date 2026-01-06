# TG04_psm_strata — 倾向得分分层

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG04 |
| **Slug** | psm_strata |
| **名称(中文)** | 倾向得分分层 |
| **Name(EN)** | PSM Strata |
| **家族** | causal_inference |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Propensity score stratification estimation

## 使用场景

- 关键词：psm, stratification, ate, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TREATMENT_VAR__` | string | 是 | Treatment variable |
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__COVARIATES__` | string | 是 | Covariates |
| `__N_STRATA__` | number | 否 | Number of strata |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG04_strata_effects.csv | table | Strata effects |
| table_TG04_strata_balance.csv | table | Strata balance |
| fig_TG04_strata_effects.png | figure | Strata effects plot |
| data_TG04_with_strata.dta | data | Data with strata |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | logit command |

## 示例

```stata
* Template: TG04_psm_strata
* Script: tasks/do/TG04_psm_strata.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

