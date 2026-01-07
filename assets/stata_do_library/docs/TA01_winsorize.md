# TA01_winsorize — 缩尾处理

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA01 |
| **Slug** | winsorize |
| **名称(中文)** | 缩尾处理 |
| **Name(EN)** | Winsorize |
| **家族** | data_management |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Winsorize numeric variables to replace extreme values with specified percentile values

## 使用场景

- 关键词：winsorize, outliers, data_cleaning, percentile

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__WINSOR_VARS__` | string | 是 | Variables to winsorize |
| `__LOWER_PCTL__` | integer | 否 | Lower percentile (default 1) |
| `__UPPER_PCTL__` | integer | 否 | Upper percentile (default 99) |
| `__TRIM_OR_WINSOR__` | string | 否 | Method: trim or winsor |
| `__BY_VAR__` | string | 否 | Grouping variable (optional) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA01_winsor_summary.csv | table | Winsorize summary |
| data_TA01_winsorized.dta | data | Winsorized data |
| data_TA01_winsorized.csv | data | Winsorized data CSV |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| winsor2 | ssc | Winsorize command |

## 示例

```stata
* Template: TA01_winsorize
* Script: assets/stata_do_library/do/TA01_winsorize.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

