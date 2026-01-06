# TG20_did_staggered — 交错DID

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG20 |
| **Slug** | did_staggered |
| **名称(中文)** | 交错DID |
| **Name(EN)** | DID Staggered |
| **家族** | causal_inference |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Staggered DID with Callaway-Sant'Anna

## 使用场景

- 关键词：did, staggered, csdid, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__ID_VAR__` | string | 是 | Unit ID |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__TREAT_TIME_VAR__` | string | 是 | First treatment time |
| `__CONTROLS__` | string | 否 | Control variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG20_staggered_result.csv | table | Staggered DID |
| table_TG20_group_effects.csv | table | Group effects |
| fig_TG20_event_study.png | figure | Event study |
| data_TG20_staggered.dta | data | Staggered data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| csdid | ssc | Staggered DID |
| drdid | ssc | DR DID |

## 示例

```stata
* Template: TG20_did_staggered
* Script: tasks/do/TG20_did_staggered.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

