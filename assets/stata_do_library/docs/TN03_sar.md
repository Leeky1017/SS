# TN03_sar — 空间自回归模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TN03 |
| **Slug** | sar |
| **名称(中文)** | 空间自回归模型 |
| **Name(EN)** | SAR Model |
| **家族** | spatial |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Spatial Autoregressive model

## 使用场景

- 关键词：sar, spatial_lag, spatial

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TN03_sar.csv | table | SAR results |
| data_TN03_sar.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| spregress | stata | Spatial regression |

## 示例

```stata
* Template: TN03_sar
* Script: assets/stata_do_library/do/TN03_sar.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

