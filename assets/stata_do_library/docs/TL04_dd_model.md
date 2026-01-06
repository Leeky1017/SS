# TL04_dd_model — DD模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL04 |
| **Slug** | dd_model |
| **名称(中文)** | DD模型 |
| **Name(EN)** | DD Model |
| **家族** | accounting |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Dechow-Dichev accruals quality model

## 使用场景

- 关键词：dechow_dichev, accruals_quality, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__WC_VAR__` | string | 是 | Working capital accruals |
| `__CFO_VAR__` | string | 是 | Cash flow from operations |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL04_dd.csv | table | DD model results |
| data_TL04_dd.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TL04_dd_model
* Script: tasks/do/TL04_dd_model.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

