# TR07_bayes_logit — 贝叶斯Logit

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TR07 |
| **Slug** | bayes_logit |
| **名称(中文)** | 贝叶斯Logit |
| **Name(EN)** | Bayesian Logit |
| **家族** | bayesian |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Bayesian logistic regression

## 使用场景

- 关键词：bayesian, logit, mcmc

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Binary dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TR07_blogit.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TR07_blogit.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | bayes logit |

## 示例

```stata
* Template: TR07_bayes_logit
* Script: assets/stata_do_library/do/TR07_bayes_logit.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

