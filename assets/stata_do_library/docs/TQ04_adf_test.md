# TQ04_adf_test — ADF单位根检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ04 |
| **Slug** | adf_test |
| **名称(中文)** | ADF单位根检验 |
| **Name(EN)** | ADF Test |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Augmented Dickey-Fuller unit root test

## 使用场景

- 关键词：adf, unit_root, stationarity, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to test |
| `__LAGS__` | integer | 否 | Number of lags |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TQ04_adf.dta | data | Output data |
| result.log | log | Execution log |
| table_TQ04_adf_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | dfuller command |

## 示例

```stata
* Template: TQ04_adf_test
* Script: tasks/do/TQ04_adf_test.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

