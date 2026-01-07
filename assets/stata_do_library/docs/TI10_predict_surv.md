# TI10_predict_surv — 生存预测

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TI10 |
| **Slug** | predict_surv |
| **名称(中文)** | 生存预测 |
| **Name(EN)** | Survival Prediction |
| **家族** | survival |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Predict survival probabilities from fitted model

## 使用场景

- 关键词：survival, prediction, curves

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TIMEVAR__` | string | 是 | Time variable |
| `__FAILVAR__` | string | 是 | Failure indicator |
| `__INDEPVARS__` | list[string] | 否 | Covariates |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TI10_predict.dta | data | Output data |
| result.log | log | Execution log |
| table_TI10_predict.csv | table | Predictions |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | stcurve command |

## 示例

```stata
* Template: TI10_predict_surv
* Script: assets/stata_do_library/do/TI10_predict_surv.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

