# TG17_scm_synth — 合成控制法

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG17 |
| **Slug** | scm_synth |
| **名称(中文)** | 合成控制法 |
| **Name(EN)** | SCM Synth |
| **家族** | causal_inference |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Synthetic control method

## 使用场景

- 关键词：scm, synth, policy, causal

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
| `__PREDICTORS__` | string | 否 | Predictors |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG17_synth_path.csv | table | Synth path |
| fig_TG17_synth_path.png | figure | Synth path plot |
| data_TG17_synth.dta | data | Synth data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| synth | ssc | Synthetic control |

## 示例

```stata
* Template: TG17_scm_synth
* Script: assets/stata_do_library/do/TG17_scm_synth.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

