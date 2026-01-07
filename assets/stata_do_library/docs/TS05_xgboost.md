# TS05_xgboost — 梯度提升

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS05 |
| **Slug** | xgboost |
| **名称(中文)** | 梯度提升 |
| **Name(EN)** | XGBoost |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Gradient Boosting (XGBoost) for prediction with variable importance

## 使用场景

- 关键词：xgboost, gradient_boosting, machine_learning

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__N_ROUNDS__` | integer | 否 | Number of rounds |
| `__MAX_DEPTH__` | integer | 否 | Max tree depth |
| `__LEARNING_RATE__` | number | 否 | Learning rate |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TS05_xgb.dta | data | Output data |
| result.log | log | Execution log |
| table_TS05_xgb_importance.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TS05_xgb_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | boost command |

## 示例

```stata
* Template: TS05_xgboost
* Script: assets/stata_do_library/do/TS05_xgboost.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

