# TH11_irf — 脉冲响应分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH11 |
| **Slug** | irf |
| **名称(中文)** | 脉冲响应分析 |
| **Name(EN)** | IRF Analysis |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Impulse response function analysis

## 使用场景

- 关键词：irf, var, impulse_response

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | string | 是 | Variables |
| `__TIMEVAR__` | string | 是 | Time variable |
| `__LAGS__` | number | 是 | Lag order |
| `__STEPS__` | number | 是 | Forecast steps |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TH11_irf.png | figure | IRF plot |
| data_TH11_irf.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH11_irf
* Script: tasks/do/TH11_irf.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

