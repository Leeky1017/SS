# TS03_elastic_net — 弹性网络回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS03 |
| **Slug** | elastic_net |
| **名称(中文)** | 弹性网络回归 |
| **Name(EN)** | Elastic Net Regression |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Elastic Net regression combining LASSO and Ridge penalties

## 使用场景

- 关键词：elastic_net, regularization, machine_learning

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__ALPHA__` | number | 否 | Mixing parameter (0-1) |
| `__CV_FOLDS__` | integer | 否 | CV folds (default 10) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TS03_enet.dta | data | Output data |
| result.log | log | Execution log |
| table_TS03_cv_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TS03_enet_coef.csv | table | Elastic Net coefficients |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | elasticnet command |

## 示例

```stata
* Template: TS03_elastic_net
* Script: tasks/do/TS03_elastic_net.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

