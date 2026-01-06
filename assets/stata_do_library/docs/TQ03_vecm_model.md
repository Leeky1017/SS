# TQ03_vecm_model — VECM模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ03 |
| **Slug** | vecm_model |
| **名称(中文)** | VECM模型 |
| **Name(EN)** | VECM Model |
| **家族** | time_series |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Vector Error Correction Model

## 使用场景

- 关键词：vecm, cointegration, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | list[string] | 是 | Endogenous variables |
| `__RANK__` | integer | 否 | Cointegration rank |
| `__LAGS__` | integer | 否 | Number of lags |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TQ03_vecm.dta | data | Output data |
| result.log | log | Execution log |
| table_TQ03_johansen.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TQ03_vecm_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | vec command |

## 示例

```stata
* Template: TQ03_vecm_model
* Script: tasks/do/TQ03_vecm_model.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

