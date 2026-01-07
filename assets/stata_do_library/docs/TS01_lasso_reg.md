# TS01_lasso_reg — LASSO回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS01 |
| **Slug** | lasso_reg |
| **名称(中文)** | LASSO回归 |
| **Name(EN)** | LASSO Regression |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

LASSO regression with cross-validation for variable selection and regularization

## 使用场景

- 关键词：lasso, regularization, variable_selection, machine_learning

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
| `__SELECTION__` | string | 否 | Selection type: cv/adaptive |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TS01_lasso.dta | data | Output data |
| fig_TS01_cv_path.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TS01_cv_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TS01_lasso_coef.csv | table | LASSO coefficients |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | lasso command |

## 示例

```stata
* Template: TS01_lasso_reg
* Script: assets/stata_do_library/do/TS01_lasso_reg.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

