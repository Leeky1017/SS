# TG01_pscore_estimate — 倾向得分估计

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG01 |
| **Slug** | pscore_estimate |
| **名称(中文)** | 倾向得分估计 |
| **Name(EN)** | Pscore Estimate |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.1.0 |

## 功能描述

Propensity score estimation using Logit/Probit

## 使用场景

- 关键词：psm, propensity-score, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TREATMENT_VAR__` | string | 是 | Treatment variable |
| `__COVARIATES__` | string | 是 | Covariates |
| `__MODEL__` | string | 否 | Model type |
| `__COMMON_SUPPORT__` | string | 否 | Common support |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG01_pscore_model.csv | table | Pscore model results |
| table_TG01_balance_before.csv | table | Balance before matching |
| fig_TG01_pscore_dist.png | figure | Pscore distribution |
| data_TG01_with_pscore.dta | data | Data with pscore |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | logit/probit + predict |
## 示例

```stata
* Template: TG01_pscore_estimate
* Script: assets/stata_do_library/do/TG01_pscore_estimate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

