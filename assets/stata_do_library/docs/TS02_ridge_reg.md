# TS02_ridge_reg — 岭回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS02 |
| **Slug** | ridge_reg |
| **名称(中文)** | 岭回归 |
| **Name(EN)** | Ridge Regression |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Ridge regression with cross-validation for regularization

## 使用场景

- 关键词：ridge, regularization, machine_learning

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__CV_FOLDS__` | integer | 否 | CV folds (default 10) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TS02_ridge.dta | data | Output data |
| result.log | log | Execution log |
| table_TS02_cv_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TS02_ridge_coef.csv | table | Ridge coefficients |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | elasticnet command |

## 示例

```stata
* Template: TS02_ridge_reg
* Script: assets/stata_do_library/do/TS02_ridge_reg.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

