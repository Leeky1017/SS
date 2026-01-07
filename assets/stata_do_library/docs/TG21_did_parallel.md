# TG21_did_parallel — 平行趋势检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG21 |
| **Slug** | did_parallel |
| **名称(中文)** | 平行趋势检验 |
| **Name(EN)** | DID Parallel |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Parallel trends test for DID

## 使用场景

- 关键词：did, parallel, pretrend, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__TREAT_VAR__` | string | 是 | Treatment indicator |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__TREATMENT_TIME__` | number | 是 | Treatment time |
| `__ID_VAR__` | string | 否 | Unit ID |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG21_parallel_test.csv | table | Parallel test |
| table_TG21_pretrend_coefs.csv | table | Pretrend coefs |
| fig_TG21_trends.png | figure | Trends |
| fig_TG21_pretrend_test.png | figure | Pretrend test |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TG21_did_parallel
* Script: assets/stata_do_library/do/TG21_did_parallel.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

