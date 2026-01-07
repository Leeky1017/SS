# TH05_garch — GARCH波动率模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH05 |
| **Slug** | garch |
| **名称(中文)** | GARCH波动率模型 |
| **Name(EN)** | GARCH Model |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

GARCH(1,1) volatility model

## 使用场景

- 关键词：garch, volatility, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable |
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TH05_garch.csv | table | GARCH results |
| fig_TH05_vol.png | figure | Volatility plot |
| data_TH05_garch.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH05_garch
* Script: assets/stata_do_library/do/TH05_garch.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

