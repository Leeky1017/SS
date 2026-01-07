# TR06_bayes_regress — 贝叶斯回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TR06 |
| **Slug** | bayes_regress |
| **名称(中文)** | 贝叶斯回归 |
| **Name(EN)** | Bayesian Regression |
| **家族** | bayesian |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Bayesian linear regression

## 使用场景

- 关键词：bayesian, regression, mcmc

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TR06_bayes.dta | data | Output data |
| result.log | log | Execution log |
| table_TR06_bayes.csv | table | Bayesian results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | bayes regress |

## 示例

```stata
* Template: TR06_bayes_regress
* Script: assets/stata_do_library/do/TR06_bayes_regress.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

