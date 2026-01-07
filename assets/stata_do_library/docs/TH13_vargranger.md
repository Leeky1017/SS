# TH13_vargranger — Granger因果检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH13 |
| **Slug** | vargranger |
| **名称(中文)** | Granger因果检验 |
| **Name(EN)** | Granger Test |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Granger causality test

## 使用场景

- 关键词：granger, causality, var

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

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TH13_granger.csv | table | Granger results |
| data_TH13_granger.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH13_vargranger
* Script: assets/stata_do_library/do/TH13_vargranger.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

