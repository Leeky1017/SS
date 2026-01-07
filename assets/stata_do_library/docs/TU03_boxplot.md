# TU03_boxplot — 箱线图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TU03 |
| **Slug** | boxplot |
| **名称(中文)** | 箱线图 |
| **Name(EN)** | Box Plot |
| **家族** | visualization |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Plot box plots showing distribution and outliers with optional grouping

## 使用场景

- 关键词：visualization, boxplot, outliers

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to plot |
| `__BY_VAR__` | string | 否 | Grouping variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TU03_boxplot.png | graph | Box plot |
| table_TU03_box_stats.csv | table | Box statistics |
| data_TU03_box.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | graph box command |

## 示例

```stata
* Template: TU03_boxplot
* Script: assets/stata_do_library/do/TU03_boxplot.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

