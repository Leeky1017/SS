# TK10_credit_risk — 信用风险

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK10 |
| **Slug** | credit_risk |
| **名称(中文)** | 信用风险 |
| **Name(EN)** | Credit Risk |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Credit risk modeling and default probability

## 使用场景

- 关键词：credit_risk, default, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEFAULT_VAR__` | string | 是 | Default indicator |
| `__INDEPVARS__` | list[string] | 是 | Risk factors |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK10_credit.dta | data | Output data |
| fig_TK10_roc.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK10_model_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK10_performance.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | logit command |

## 示例

```stata
* Template: TK10_credit_risk
* Script: assets/stata_do_library/do/TK10_credit_risk.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

