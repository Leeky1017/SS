# TG25_mte_estimate — MTE估计

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG25 |
| **Slug** | mte_estimate |
| **名称(中文)** | MTE估计 |
| **Name(EN)** | MTE Estimate |
| **家族** | causal_inference |
| **等级** | L3 |
| **版本** | 2.1.0 |

## 功能描述

Marginal treatment effect estimation

## 使用场景

- 关键词：mte, heterogeneity, policy, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__TREATMENT_VAR__` | string | 是 | Treatment variable |
| `__INSTRUMENT__` | string | 是 | Instrument |
| `__COVARIATES__` | string | 否 | Covariates |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG25_mte_result.csv | table | MTE results |
| table_TG25_policy_params.csv | table | Policy params |
| fig_TG25_mte_curve.png | figure | MTE curve |
| data_TG25_mte.dta | data | MTE data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| mtefe | ssc | MTE estimation |
## 示例

```stata
* Template: TG25_mte_estimate
* Script: assets/stata_do_library/do/TG25_mte_estimate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

