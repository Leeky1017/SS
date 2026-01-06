# TU07_pie_chart — 饼图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TU07 |
| **Slug** | pie_chart |
| **名称(中文)** | 饼图 |
| **Name(EN)** | Pie Chart |
| **家族** | visualization |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Plot pie chart showing proportional distribution of categorical data

## 使用场景

- 关键词：visualization, pie, proportion

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__CAT_VAR__` | string | 是 | Category variable |
| `__VALUE_VAR__` | string | 否 | Value variable (default count) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TU07_pie.png | graph | Pie chart |
| table_TU07_pie_data.csv | table | Proportion data |
| data_TU07_pie.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | graph pie command |

## 示例

```stata
* Template: TU07_pie_chart
* Script: tasks/do/TU07_pie_chart.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

