# TA04_outlier_detect — 异常值检测与处理

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA04 |
| **Slug** | outlier_detect |
| **名称(中文)** | 异常值检测与处理 |
| **Name(EN)** | Outlier Detect |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Detect outliers using IQR, Z-score or MAD methods, with flag/drop/replace options

## 使用场景

- 关键词：outlier, detection, data_cleaning, iqr, zscore

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__CHECK_VARS__` | string | 是 | Variables to check |
| `__METHOD__` | string | 否 | Detection method: iqr/zscore/mad |
| `__THRESHOLD__` | number | 否 | Threshold value |
| `__ACTION__` | string | 否 | Action: flag/drop/replace |
| `__ID_VAR__` | string | 否 | ID variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA04_outlier_summary.csv | table | Outlier summary |
| table_TA04_outlier_details.csv | table | Outlier details |
| data_TA04_cleaned.dta | data | Cleaned data |
| data_TA04_cleaned.csv | data | Cleaned CSV |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | Analysis commands |

## 示例

```stata
* Template: TA04_outlier_detect
* Script: assets/stata_do_library/do/TA04_outlier_detect.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

