# TG02_psm_match — 倾向得分匹配

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG02 |
| **Slug** | psm_match |
| **名称(中文)** | 倾向得分匹配 |
| **Name(EN)** | PSM Match |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.1.0 |

## 功能描述

Propensity score matching (1:1/1:N)

## 使用场景

- 关键词：psm, matching, att, causal

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
| `__N_NEIGHBORS__` | number | 否 | Number of neighbors |
| `__CALIPER__` | number | 否 | Caliper width |
| `__WITH_REPLACE__` | string | 否 | With replacement |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG02_att_result.csv | table | ATT results |
| table_TG02_balance_after.csv | table | Balance after matching |
| fig_TG02_balance_compare.png | figure | Balance comparison |
| data_TG02_matched.dta | data | Matched data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | teffects psmatch + tebalance |
## 示例

```stata
* Template: TG02_psm_match
* Script: assets/stata_do_library/do/TG02_psm_match.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

