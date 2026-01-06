# TD02_high_dim_fe — 高维固定效应

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD02 |
| **Slug** | high_dim_fe |
| **名称(中文)** | 高维固定效应 |
| **Name(EN)** | High Dim FE |
| **家族** | linear_regression |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

High-dimensional fixed effects regression

## 使用场景

- 关键词：fixed-effects, high-dimensional, reghdfe

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__ABSORB_VARS__` | string | 是 | Absorb variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TD02_hdfe.csv | table | HDFE results |
| data_TD02_hdfe.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| reghdfe | ssc | high-dimensional fixed effects |
| estout | ssc | table export |

## 示例

```stata
* Template: TD02_high_dim_fe
* Script: tasks/do/TD02_high_dim_fe.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

