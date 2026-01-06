# TU02_scatter — 散点图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TU02 |
| **Slug** | scatter |
| **名称(中文)** | 散点图 |
| **Name(EN)** | Scatter Plot |
| **家族** | visualization |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Plot scatter diagram with optional fit lines and grouping

## 使用场景

- 关键词：visualization, scatter, correlation

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__XVAR__` | string | 是 | X variable |
| `__YVAR__` | string | 是 | Y variable |
| `__FITLINE__` | string | 否 | Fit line: none/linear/lowess |
| `__GROUP_VAR__` | string | 否 | Grouping variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TU02_scatter.png | graph | Scatter plot |
| data_TU02_scatter.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | twoway command |

## 示例

```stata
* Template: TU02_scatter
* Script: tasks/do/TU02_scatter.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

