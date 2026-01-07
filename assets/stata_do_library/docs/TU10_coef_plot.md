# TU10_coef_plot — 系数图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TU10 |
| **Slug** | coef_plot |
| **名称(中文)** | 系数图 |
| **Name(EN)** | Coefficient Plot |
| **家族** | visualization |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Plot regression coefficient estimates with confidence intervals

## 使用场景

- 关键词：visualization, coefficient, regression

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__CI_LEVEL__` | integer | 否 | Confidence level (default 95) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TU10_coef.png | graph | Coefficient plot |
| table_TU10_coef.csv | table | Coefficient table |
| data_TU10_coef.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TU10_coef_plot
* Script: assets/stata_do_library/do/TU10_coef_plot.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

