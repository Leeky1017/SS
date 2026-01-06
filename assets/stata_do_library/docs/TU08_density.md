# TU08_density — 核密度图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TU08 |
| **Slug** | density |
| **名称(中文)** | 核密度图 |
| **Name(EN)** | Kernel Density |
| **家族** | visualization |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Plot kernel density estimate with optional group comparison

## 使用场景

- 关键词：visualization, density, distribution

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to plot |
| `__BY_VAR__` | string | 否 | Grouping variable |
| `__BANDWIDTH__` | number | 否 | Bandwidth (default auto) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TU08_density.png | graph | Density plot |
| data_TU08_density.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | kdensity command |

## 示例

```stata
* Template: TU08_density
* Script: tasks/do/TU08_density.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

