# TQ01_arima_model — ARIMA模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ01 |
| **Slug** | arima_model |
| **名称(中文)** | ARIMA模型 |
| **Name(EN)** | ARIMA Model |
| **家族** | time_series |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

ARIMA time series model

## 使用场景

- 关键词：arima, time_series, forecast

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Time series variable |
| `__P__` | integer | 否 | AR order |
| `__D__` | integer | 否 | Differencing |
| `__Q__` | integer | 否 | MA order |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TQ01_arima.dta | data | Output data |
| fig_TQ01_forecast.png | graph | Forecast plot |
| result.log | log | Execution log |
| table_TQ01_arima_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TQ01_forecast.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | arima command |

## 示例

```stata
* Template: TQ01_arima_model
* Script: assets/stata_do_library/do/TQ01_arima_model.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

