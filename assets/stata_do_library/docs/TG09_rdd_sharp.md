# TG09_rdd_sharp — 断点回归(Sharp)

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG09 |
| **Slug** | rdd_sharp |
| **名称(中文)** | 断点回归(Sharp) |
| **Name(EN)** | RDD Sharp |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Sharp regression discontinuity design

## 使用场景

- 关键词：rdd, sharp, late, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__RUNNING_VAR__` | string | 是 | Running variable |
| `__CUTOFF__` | number | 是 | Cutoff value |
| `__BANDWIDTH__` | number | 否 | Bandwidth |
| `__KERNEL__` | string | 否 | Kernel function |
| `__POLY_ORDER__` | number | 否 | Polynomial order |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG09_rdd_result.csv | table | RDD results |
| table_TG09_bandwidth.csv | table | Bandwidth selection |
| fig_TG09_rdd_plot.png | figure | RDD plot |
| data_TG09_rdd.dta | data | RDD data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| rdrobust | ssc | RDD estimation |

## 示例

```stata
* Template: TG09_rdd_sharp
* Script: tasks/do/TG09_rdd_sharp.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

