# TR08_bayes_mixed — 贝叶斯混合模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TR08 |
| **Slug** | bayes_mixed |
| **名称(中文)** | 贝叶斯混合模型 |
| **Name(EN)** | Bayesian Mixed |
| **家族** | bayesian |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Bayesian multilevel/mixed model

## 使用场景

- 关键词：bayesian, mixed, multilevel, mcmc

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__GROUPVAR__` | string | 是 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TR08_bmixed.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TR08_bmixed.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | bayes mixed |

## 示例

```stata
* Template: TR08_bayes_mixed
* Script: tasks/do/TR08_bayes_mixed.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

