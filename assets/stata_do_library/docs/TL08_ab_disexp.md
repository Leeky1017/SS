# TL08_ab_disexp — 异常酌情费用

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL08 |
| **Slug** | ab_disexp |
| **名称(中文)** | 异常酌情费用 |
| **Name(EN)** | Abnormal Discretionary Expense |
| **家族** | accounting |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Abnormal discretionary expenses

## 使用场景

- 关键词：abnormal_disexp, rem, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DISEXP_VAR__` | string | 是 | Discretionary expenses |
| `__SALES_VAR__` | string | 是 | Sales |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TL08_abdis.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TL08_abdis.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TL08_ab_disexp
* Script: assets/stata_do_library/do/TL08_ab_disexp.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

