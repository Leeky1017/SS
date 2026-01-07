# TH06_egarch — EGARCH非对称波动

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH06 |
| **Slug** | egarch |
| **名称(中文)** | EGARCH非对称波动 |
| **Name(EN)** | EGARCH Model |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

EGARCH asymmetric volatility model

## 使用场景

- 关键词：egarch, volatility, asymmetric, time_series

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
| table_TH06_egarch.csv | table | EGARCH results |
| data_TH06_egarch.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH06_egarch
* Script: assets/stata_do_library/do/TH06_egarch.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

