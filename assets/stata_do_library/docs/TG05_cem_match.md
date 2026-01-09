# TG05_cem_match — 粗化精确匹配

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG05 |
| **Slug** | cem_match |
| **名称(中文)** | 粗化精确匹配 |
| **Name(EN)** | CEM Match |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.1.0 |

## 功能描述

Coarsened exact matching for causal inference

## 使用场景

- 关键词：cem, matching, satt, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TREATMENT_VAR__` | string | 是 | Treatment variable |
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__MATCH_VARS__` | string | 是 | Matching variables |
| `__CUTPOINTS__` | string | 否 | Coarsening method |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG05_cem_result.csv | table | CEM results |
| table_TG05_cem_balance.csv | table | CEM balance |
| data_TG05_cem_matched.dta | data | CEM matched data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| cem | ssc | Coarsened exact matching |
## 示例

```stata
* Template: TG05_cem_match
* Script: assets/stata_do_library/do/TG05_cem_match.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

