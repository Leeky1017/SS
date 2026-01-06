# TU01_histogram — 直方图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TU01 |
| **Slug** | histogram |
| **名称(中文)** | 直方图 |
| **Name(EN)** | Histogram |
| **家族** | visualization |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Plot histogram with optional normal distribution overlay

## 使用场景

- 关键词：visualization, histogram, distribution

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to plot |
| `__BINS__` | integer | 否 | Number of bins (default auto) |
| `__NORMAL__` | string | 否 | Overlay normal curve: yes/no |
| `__TITLE__` | string | 否 | Chart title |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TU01_histogram.png | graph | Histogram |
| table_TU01_hist_stats.csv | table | Distribution statistics |
| data_TU01_hist.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | histogram command |

## 示例

```stata
* Template: TU01_histogram
* Script: tasks/do/TU01_histogram.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

