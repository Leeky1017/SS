# TG03_ipw_weight — 逆概率加权

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG03 |
| **Slug** | ipw_weight |
| **名称(中文)** | 逆概率加权 |
| **Name(EN)** | IPW Weight |
| **家族** | causal_inference |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Inverse probability weighting for ATE/ATT estimation

## 使用场景

- 关键词：ipw, weighting, ate, causal

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
| `__ESTIMAND__` | string | 否 | Estimand type |
| `__TRIM_PCTL__` | number | 否 | Trim percentile |
| `__STABILIZE__` | string | 否 | Stabilize weights |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG03_ipw_result.csv | table | IPW results |
| table_TG03_weight_summary.csv | table | Weight summary |
| table_TG03_balance_weighted.csv | table | Balance weighted |
| data_TG03_with_weights.dta | data | Data with weights |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | logit command |

## 示例

```stata
* Template: TG03_ipw_weight
* Script: assets/stata_do_library/do/TG03_ipw_weight.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

