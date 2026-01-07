# TQ05_seasonal_decomp — 季节分解

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ05 |
| **Slug** | seasonal_decomp |
| **名称(中文)** | 季节分解 |
| **Name(EN)** | Seasonal Decomposition |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Seasonal decomposition of time series

## 使用场景

- 关键词：seasonal, decomposition, trend, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Time series variable |
| `__PERIOD__` | integer | 否 | Seasonal period |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TQ05_decomp.csv | table | Decomposition results |
| fig_TQ05_decomp.png | graph | Decomposition plot |
| data_TQ05_decomp.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| tssmooth | stata | Smoothing |

## 示例

```stata
* Template: TQ05_seasonal_decomp
* Script: assets/stata_do_library/do/TQ05_seasonal_decomp.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

