# TG06_mahal_match — 马氏距离匹配

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG06 |
| **Slug** | mahal_match |
| **名称(中文)** | 马氏距离匹配 |
| **Name(EN)** | Mahal Match |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.1.0 |

## 功能描述

Mahalanobis distance matching

## 使用场景

- 关键词：mahalanobis, matching, att, causal

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
| `__EXACT_VARS__` | string | 否 | Exact matching variables |
| `__N_NEIGHBORS__` | number | 否 | Number of neighbors |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG06_mahal_result.csv | table | Mahal match results |
| table_TG06_balance.csv | table | Balance after matching |
| data_TG06_mahal_matched.dta | data | Matched data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | teffects nnmatch + tebalance |
## 示例

```stata
* Template: TG06_mahal_match
* Script: assets/stata_do_library/do/TG06_mahal_match.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

