# TG19_did_basic — 双重差分法

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG19 |
| **Slug** | did_basic |
| **名称(中文)** | 双重差分法 |
| **Name(EN)** | DID Basic |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Basic difference-in-differences

## 使用场景

- 关键词：did, causal, policy, treatment

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__TREAT_VAR__` | string | 是 | Treatment indicator |
| `__POST_VAR__` | string | 是 | Post-treatment indicator |
| `__TIME_VAR__` | string | 否 | Time variable |
| `__CONTROLS__` | string | 否 | Control variables |
| `__CLUSTER_VAR__` | string | 否 | Cluster variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG19_did_result.csv | table | DID results |
| table_TG19_parallel_test.csv | table | Parallel test |
| fig_TG19_parallel_trend.png | figure | Parallel trend |
| data_TG19_did.dta | data | DID data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TG19_did_basic
* Script: tasks/do/TG19_did_basic.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

