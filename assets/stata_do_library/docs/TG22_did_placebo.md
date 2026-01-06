# TG22_did_placebo — DID安慰剂检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG22 |
| **Slug** | did_placebo |
| **名称(中文)** | DID安慰剂检验 |
| **Name(EN)** | DID Placebo |
| **家族** | causal_inference |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Placebo tests for DID

## 使用场景

- 关键词：did, placebo, inference, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__TREAT_VAR__` | string | 是 | Treatment indicator |
| `__POST_VAR__` | string | 是 | Post indicator |
| `__TIME_VAR__` | string | 否 | Time variable |
| `__PLACEBO_TYPE__` | string | 否 | Placebo type |
| `__N_PERMUTATIONS__` | number | 否 | Permutations |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG22_placebo_results.csv | table | Placebo results |
| fig_TG22_placebo_dist.png | figure | Placebo distribution |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TG22_did_placebo
* Script: tasks/do/TG22_did_placebo.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

