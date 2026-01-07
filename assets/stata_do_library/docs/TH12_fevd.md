# TH12_fevd — 方差分解

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH12 |
| **Slug** | fevd |
| **名称(中文)** | 方差分解 |
| **Name(EN)** | FEVD Analysis |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Forecast error variance decomposition

## 使用场景

- 关键词：fevd, var, variance_decomposition

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | string | 是 | Variables |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__LAGS__` | number | 是 | Lag order |
| `__STEPS__` | number | 是 | Forecast steps |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TH12_fevd.png | figure | FEVD plot |
| table_TH12_fevd.csv | table | FEVD results |
| data_TH12_fevd.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH12_fevd
* Script: assets/stata_do_library/do/TH12_fevd.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

