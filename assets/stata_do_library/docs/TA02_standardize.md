# TA02_standardize — 标准化与归一化

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA02 |
| **Slug** | standardize |
| **名称(中文)** | 标准化与归一化 |
| **Name(EN)** | Standardize |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Standardize (Z-score) or normalize (Min-Max) numeric variables

## 使用场景

- 关键词：standardize, normalize, zscore, minmax

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TRANSFORM_VARS__` | string | 是 | Variables to transform |
| `__METHOD__` | string | 否 | Method: zscore/minmax/rank |
| `__BY_VAR__` | string | 否 | Grouping variable |
| `__SUFFIX__` | string | 否 | New variable suffix |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA02_transform_summary.csv | table | Transform summary |
| data_TA02_standardized.dta | data | Standardized data |
| data_TA02_standardized.csv | data | Standardized CSV |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | egen command |

## 示例

```stata
* Template: TA02_standardize
* Script: tasks/do/TA02_standardize.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

