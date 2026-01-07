# TD01_twoway_fe — 双向固定效应

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD01 |
| **Slug** | twoway_fe |
| **名称(中文)** | 双向固定效应 |
| **Name(EN)** | Twoway FE |
| **家族** | linear_regression |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Two-way fixed effects regression (individual and time)

## 使用场景

- 关键词：fixed-effects, twoway, panel, reghdfe

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__PANELVAR__` | string | 是 | Panel variable |
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TD01_twfe.csv | table | TWFE results |
| data_TD01_twfe.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| reghdfe | ssc | high-dimensional fixed effects |

## 示例

```stata
* Template: TD01_twoway_fe
* Script: assets/stata_do_library/do/TD01_twoway_fe.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

