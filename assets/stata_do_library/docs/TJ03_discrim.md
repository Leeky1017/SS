# TJ03_discrim — 判别分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TJ03 |
| **Slug** | discrim |
| **名称(中文)** | 判别分析 |
| **Name(EN)** | Discriminant Analysis |
| **家族** | multivariate |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Linear Discriminant Analysis

## 使用场景

- 关键词：discriminant, lda, classification

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__GROUPVAR__` | string | 是 | Group variable |
| `__VARS__` | list[string] | 是 | Predictor variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TJ03_discrim.csv | table | LDA results |
| data_TJ03_discrim.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | discrim lda command |

## 示例

```stata
* Template: TJ03_discrim
* Script: tasks/do/TJ03_discrim.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

