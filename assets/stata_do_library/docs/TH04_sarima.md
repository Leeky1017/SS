# TH04_sarima — 季节性ARIMA

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH04 |
| **Slug** | sarima |
| **名称(中文)** | 季节性ARIMA |
| **Name(EN)** | SARIMA Model |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Seasonal ARIMA model estimation

## 使用场景

- 关键词：arima, sarima, forecast, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__P__` | number | 是 | AR order |
| `__D__` | number | 是 | Differencing order |
| `__Q__` | number | 是 | MA order |
| `__SP__` | number | 是 | Seasonal AR |
| `__SD__` | number | 是 | Seasonal diff |
| `__SQ__` | number | 是 | Seasonal MA |
| `__SEASON__` | number | 是 | Season length |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TH04_sarima.csv | table | SARIMA results |
| fig_TH04_forecast.png | figure | Forecast plot |
| data_TH04_sarima.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH04_sarima
* Script: assets/stata_do_library/do/TH04_sarima.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

