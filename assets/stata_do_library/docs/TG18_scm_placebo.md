# TG18_scm_placebo — SCM安慰剂检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG18 |
| **Slug** | scm_placebo |
| **名称(中文)** | SCM安慰剂检验 |
| **Name(EN)** | SCM Placebo |
| **家族** | causal_inference |
| **等级** | L2 |
| **版本** | 2.1.0 |

## 功能描述

Placebo tests for SCM

## 使用场景

- 关键词：scm, placebo, inference, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__TREATED_UNIT__` | number | 是 | Treated unit ID |
| `__TREATMENT_TIME__` | number | 是 | Treatment time |
| `__ID_VAR__` | string | 是 | Unit ID |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__PLACEBO_TYPE__` | string | 否 | Placebo type: unit/time |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG18_placebo_results.csv | table | Placebo results |
| fig_TG18_placebo_plot.png | figure | Placebo plot |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| synth | ssc | Synthetic control |
## 示例

```stata
* Template: TG18_scm_placebo
* Script: assets/stata_do_library/do/TG18_scm_placebo.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

