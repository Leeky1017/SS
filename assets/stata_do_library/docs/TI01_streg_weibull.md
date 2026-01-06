# TI01_streg_weibull — Weibull生存分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TI01 |
| **Slug** | streg_weibull |
| **名称(中文)** | Weibull生存分析 |
| **Name(EN)** | Weibull Survival |
| **家族** | survival |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Weibull parametric survival regression model

## 使用场景

- 关键词：survival, weibull, parametric

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TIMEVAR__` | string | 是 | Time variable |
| `__FAILVAR__` | string | 是 | Failure indicator |
| `__INDEPVARS__` | list[string] | 否 | Covariates |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TI01_weibull.csv | table | Weibull results |
| data_TI01_weibull.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | streg command |

## 示例

```stata
* Template: TI01_streg_weibull
* Script: tasks/do/TI01_streg_weibull.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

