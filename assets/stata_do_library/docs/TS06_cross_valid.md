# TS06_cross_valid — 交叉验证

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS06 |
| **Slug** | cross_valid |
| **名称(中文)** | 交叉验证 |
| **Name(EN)** | Cross Validation |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

K-fold cross-validation for model evaluation

## 使用场景

- 关键词：cross_validation, model_evaluation, machine_learning

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__K_FOLDS__` | integer | 否 | Number of folds |
| `__MODEL_TYPE__` | string | 否 | Model type: ols/logit |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TS06_cv_folds.csv | table | Fold results |
| table_TS06_cv_summary.csv | table | CV summary |
| data_TS06_cv.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | crossfold command |

## 示例

```stata
* Template: TS06_cross_valid
* Script: tasks/do/TS06_cross_valid.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

