# TG07_psm_balance — PSM平衡性检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG07 |
| **Slug** | psm_balance |
| **名称(中文)** | PSM平衡性检验 |
| **Name(EN)** | PSM Balance |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Comprehensive PSM balance diagnostics

## 使用场景

- 关键词：psm, balance, diagnostics, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TREATMENT_VAR__` | string | 是 | Treatment variable |
| `__COVARIATES__` | string | 是 | Covariates |
| `__PSCORE_VAR__` | string | 否 | Pscore variable |
| `__WEIGHT_VAR__` | string | 否 | Weight variable |
| `__THRESHOLD__` | number | 否 | Balance threshold |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG07_balance_stats.csv | table | Balance stats |
| table_TG07_balance_detail.csv | table | Balance detail |
| fig_TG07_love_plot.png | figure | Love plot |
| fig_TG07_ps_overlap.png | figure | PS overlap |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| psmatch2 | ssc | PSM balance |

## 示例

```stata
* Template: TG07_psm_balance
* Script: assets/stata_do_library/do/TG07_psm_balance.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

