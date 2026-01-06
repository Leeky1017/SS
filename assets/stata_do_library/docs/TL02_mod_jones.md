# TL02_mod_jones — 修正Jones模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL02 |
| **Slug** | mod_jones |
| **名称(中文)** | 修正Jones模型 |
| **Name(EN)** | Modified Jones |
| **家族** | accounting |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Modified Jones model for discretionary accruals

## 使用场景

- 关键词：modified_jones, accruals, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TA_VAR__` | string | 是 | Total accruals |
| `__REV_VAR__` | string | 是 | Revenue change |
| `__REC_VAR__` | string | 是 | Receivables change |
| `__PPE_VAR__` | string | 是 | PPE |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL02_modjones.csv | table | Modified Jones results |
| data_TL02_modjones.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TL02_mod_jones
* Script: tasks/do/TL02_mod_jones.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

