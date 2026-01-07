# TP13_svy_logit — 调查Logit

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP13 |
| **Slug** | svy_logit |
| **名称(中文)** | 调查Logit |
| **Name(EN)** | Survey Logit |
| **家族** | survey |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Survey-weighted logistic regression

## 使用场景

- 关键词：survey, logit, weighted

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__WEIGHT__` | string | 是 | Survey weight |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TP13_svy.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TP13_svylogit.csv | table | Survey logit results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | svy logit command |

## 示例

```stata
* Template: TP13_svy_logit
* Script: assets/stata_do_library/do/TP13_svy_logit.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

