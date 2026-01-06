# TJ06_ca — 对应分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TJ06 |
| **Slug** | ca |
| **名称(中文)** | 对应分析 |
| **Name(EN)** | Correspondence Analysis |
| **家族** | multivariate |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Correspondence Analysis for categorical data

## 使用场景

- 关键词：correspondence, categorical, multivariate

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__ROWVAR__` | string | 是 | Row variable |
| `__COLVAR__` | string | 是 | Column variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TJ06_ca.csv | table | CA results |
| fig_TJ06_ca.png | graph | CA biplot |
| data_TJ06_ca.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | ca command |

## 示例

```stata
* Template: TJ06_ca
* Script: tasks/do/TJ06_ca.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

