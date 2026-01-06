# TG23_did_twfe — TWFE问题与替代

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG23 |
| **Slug** | did_twfe |
| **名称(中文)** | TWFE问题与替代 |
| **Name(EN)** | DID TWFE |
| **家族** | causal_inference |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

TWFE diagnostics and robust alternatives

## 使用场景

- 关键词：did, twfe, robust, causal

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
| `__TREAT_VAR__` | string | 是 | Treatment variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG23_twfe_comparison.csv | table | TWFE comparison |
| fig_TG23_comparison.png | figure | Comparison plot |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| reghdfe | ssc | HDFE regression |
| did_multiplegt | ssc | Robust DID |

## 示例

```stata
* Template: TG23_did_twfe
* Script: tasks/do/TG23_did_twfe.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

