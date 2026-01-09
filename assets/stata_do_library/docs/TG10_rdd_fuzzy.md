# TG10_rdd_fuzzy — 模糊断点回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG10 |
| **Slug** | rdd_fuzzy |
| **名称(中文)** | 模糊断点回归 |
| **Name(EN)** | RDD Fuzzy |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.1.0 |

## 功能描述

Fuzzy regression discontinuity design

## 使用场景

- 关键词：rdd, fuzzy, late, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__TREATMENT_VAR__` | string | 是 | Treatment variable |
| `__RUNNING_VAR__` | string | 是 | Running variable |
| `__CUTOFF__` | number | 是 | Cutoff value |
| `__BANDWIDTH__` | number | 否 | Bandwidth |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG10_fuzzy_result.csv | table | Fuzzy RDD results |
| table_TG10_first_stage.csv | table | First stage results |
| fig_TG10_fuzzy_plot.png | figure | Fuzzy RDD plot |
| data_TG10_fuzzy.dta | data | Fuzzy data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| rdrobust | ssc | RDD estimation |
## 示例

```stata
* Template: TG10_rdd_fuzzy
* Script: assets/stata_do_library/do/TG10_rdd_fuzzy.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

