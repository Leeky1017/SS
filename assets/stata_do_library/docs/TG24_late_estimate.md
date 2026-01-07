# TG24_late_estimate — LATE估计

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG24 |
| **Slug** | late_estimate |
| **名称(中文)** | LATE估计 |
| **Name(EN)** | LATE Estimate |
| **家族** | causal_inference |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Local average treatment effect estimation

## 使用场景

- 关键词：late, iv, complier, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__TREATMENT_VAR__` | string | 是 | Treatment variable |
| `__INSTRUMENT__` | string | 是 | Instrument |
| `__COVARIATES__` | string | 否 | Covariates |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG24_late_result.csv | table | LATE results |
| table_TG24_complier_chars.csv | table | Complier chars |
| data_TG24_late.dta | data | LATE data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| ivreg2 | ssc | IV regression |

## 示例

```stata
* Template: TG24_late_estimate
* Script: assets/stata_do_library/do/TG24_late_estimate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

