# TA07_string_process — 字符串变量处理

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA07 |
| **Slug** | string_process |
| **名称(中文)** | 字符串变量处理 |
| **Name(EN)** | String Process |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Clean and transform string variables with trim, case conversion, regex operations

## 使用场景

- 关键词：string, text, clean, regex, trim

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__STRING_VARS__` | string | 是 | String variables to process |
| `__OPERATION__` | string | 否 | Operation type |
| `__PATTERN__` | string | 否 | Regex pattern |
| `__REPLACEMENT__` | string | 否 | Replacement string |
| `__NEW_SUFFIX__` | string | 否 | New variable suffix |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA07_string_summary.csv | table | String processing summary |
| data_TA07_processed.dta | data | Processed data |
| data_TA07_processed.csv | data | Processed CSV |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | String functions |

## 示例

```stata
* Template: TA07_string_process
* Script: assets/stata_do_library/do/TA07_string_process.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

