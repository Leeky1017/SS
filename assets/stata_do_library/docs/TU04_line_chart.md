# TU04_line_chart — 折线图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TU04 |
| **Slug** | line_chart |
| **名称(中文)** | 折线图 |
| **Name(EN)** | Line Chart |
| **家族** | visualization |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Plot time series or trend line charts with optional multi-series

## 使用场景

- 关键词：visualization, line, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__YVAR__` | string | 是 | Y variable |
| `__XVAR__` | string | 是 | X variable (time) |
| `__BY_VAR__` | string | 否 | Grouping variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TU04_line.png | graph | Line chart |
| data_TU04_line.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | twoway line command |

## 示例

```stata
* Template: TU04_line_chart
* Script: assets/stata_do_library/do/TU04_line_chart.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

