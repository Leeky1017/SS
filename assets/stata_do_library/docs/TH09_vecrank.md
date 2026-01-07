# TH09_vecrank — Johansen协整检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH09 |
| **Slug** | vecrank |
| **名称(中文)** | Johansen协整检验 |
| **Name(EN)** | Johansen Test |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Johansen cointegration rank test

## 使用场景

- 关键词：cointegration, johansen, vecm, time_series

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

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TH09_vecrank.csv | table | Vecrank results |
| data_TH09_vecrank.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH09_vecrank
* Script: assets/stata_do_library/do/TH09_vecrank.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

