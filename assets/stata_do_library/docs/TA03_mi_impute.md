# TA03_mi_impute — 缺失值多重插补

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA03 |
| **Slug** | mi_impute |
| **名称(中文)** | 缺失值多重插补 |
| **Name(EN)** | MI Impute |
| **家族** | data_management |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Multiple imputation for missing data using chained equations (MICE)

## 使用场景

- 关键词：imputation, missing_data, mice, multiple_imputation

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__IMPUTE_VARS__` | string | 是 | Variables to impute |
| `__PREDICTOR_VARS__` | string | 否 | Predictor variables |
| `__N_IMPUTATIONS__` | integer | 否 | Number of imputations |
| `__METHOD__` | string | 否 | Imputation method |
| `__ID_VAR__` | string | 否 | ID variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA03_missing_pattern.csv | table | Missing pattern |
| table_TA03_impute_diag.csv | table | Imputation diagnostics |
| data_TA03_imputed.dta | data | Imputed data (MI format) |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mi module |

## 示例

```stata
* Template: TA03_mi_impute
* Script: tasks/do/TA03_mi_impute.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

