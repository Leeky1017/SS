# TH02_kpss — KPSS平稳性检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH02 |
| **Slug** | kpss |
| **名称(中文)** | KPSS平稳性检验 |
| **Name(EN)** | KPSS Test |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

KPSS stationarity test

## 使用场景

- 关键词：stationarity, kpss, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to test |
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TH02_kpss.csv | table | KPSS results |
| data_TH02_kpss.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| kpss | ssc | KPSS test |

## 示例

```stata
* Template: TH02_kpss
* Script: assets/stata_do_library/do/TH02_kpss.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

