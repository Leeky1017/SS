# TS04_random_forest — 随机森林

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS04 |
| **Slug** | random_forest |
| **名称(中文)** | 随机森林 |
| **Name(EN)** | Random Forest |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Random Forest for classification or regression with variable importance

## 使用场景

- 关键词：random_forest, ensemble, machine_learning

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__N_TREES__` | integer | 否 | Number of trees |
| `__TYPE__` | string | 否 | Type: classify/regress |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TS04_rf.dta | data | Output data |
| result.log | log | Execution log |
| table_TS04_rf_importance.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TS04_rf_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | rforest command |

## 示例

```stata
* Template: TS04_random_forest
* Script: tasks/do/TS04_random_forest.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

