# TA08_datetime_process — 日期时间变量处理

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA08 |
| **Slug** | datetime_process |
| **名称(中文)** | 日期时间变量处理 |
| **Name(EN)** | Datetime Process |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Parse and transform date/time variables, extract components, calculate differences

## 使用场景

- 关键词：date, time, datetime, extract, parse

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DATE_VARS__` | string | 是 | Date variables |
| `__INPUT_FORMAT__` | string | 否 | Input format |
| `__OPERATIONS__` | string | 否 | Operations |
| `__REFERENCE_DATE__` | string | 否 | Reference date |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA08_datetime_summary.csv | table | Datetime summary |
| data_TA08_processed.dta | data | Processed data |
| data_TA08_processed.csv | data | Processed CSV |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | Date functions |

## 示例

```stata
* Template: TA08_datetime_process
* Script: assets/stata_do_library/do/TA08_datetime_process.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

