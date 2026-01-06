# TM13_log_binomial — 对数二项回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM13 |
| **Slug** | log_binomial |
| **名称(中文)** | 对数二项回归 |
| **Name(EN)** | Log Binomial |
| **家族** | medical |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Log-binomial regression for risk ratios

## 使用场景

- 关键词：log_binomial, risk_ratio, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME__` | string | 是 | Binary outcome |
| `__INDEPVARS__` | list[string] | 是 | Predictors |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TM13_pr.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TM13_pr.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | glm command |

## 示例

```stata
* Template: TM13_log_binomial
* Script: tasks/do/TM13_log_binomial.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

