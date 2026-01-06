# TQ02_var_model — VAR模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ02 |
| **Slug** | var_model |
| **名称(中文)** | VAR模型 |
| **Name(EN)** | VAR Model |
| **家族** | time_series |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Vector Autoregression model

## 使用场景

- 关键词：var, time_series, irf

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | list[string] | 是 | Endogenous variables |
| `__LAGS__` | integer | 否 | Number of lags |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TQ02_var.dta | data | Output data |
| fig_TQ02_irf.png | graph | IRF plot |
| result.log | log | Execution log |
| table_TQ02_granger.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TQ02_var_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | var command |

## 示例

```stata
* Template: TQ02_var_model
* Script: tasks/do/TQ02_var_model.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

