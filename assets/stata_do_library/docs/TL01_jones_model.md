# TL01_jones_model — Jones模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL01 |
| **Slug** | jones_model |
| **名称(中文)** | Jones模型 |
| **Name(EN)** | Jones Model |
| **家族** | accounting |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Jones accruals model for earnings management detection

## 使用场景

- 关键词：jones, accruals, earnings_management, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TA_VAR__` | string | 是 | Total accruals |
| `__REV_VAR__` | string | 是 | Revenue change |
| `__PPE_VAR__` | string | 是 | PPE |
| `__ASSETS_VAR__` | string | 是 | Total assets |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL01_jones.csv | table | Jones model results |
| data_TL01_jones.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TL01_jones_model
* Script: tasks/do/TL01_jones_model.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

