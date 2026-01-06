# TR10_bayes_factor — 贝叶斯因子模型比较

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TR10 |
| **Slug** | bayes_factor |
| **名称(中文)** | 贝叶斯因子模型比较 |
| **Name(EN)** | Bayes Factor Model Comparison |
| **家族** | bayesian |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Compute Bayes factors for model comparison using MCMC sampling to evaluate relative evidence between competing models

## 使用场景

- 关键词：bayesian, model-comparison, bayes-factor, mcmc

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | varname | 是 | Dependent variable |
| `__INDEPVARS1__` | varlist | 是 | Independent variables for model 1 |
| `__INDEPVARS2__` | varlist | 是 | Independent variables for model 2 |
| `__MCMC__` | integer | 否 | MCMC iterations |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TR10_bf.csv | table | Bayes factor comparison results |
| data_TR10_bf.dta | data | Output dataset with Bayes factors |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TR10_bayes_factor
* Script: tasks/do/TR10_bayes_factor.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

