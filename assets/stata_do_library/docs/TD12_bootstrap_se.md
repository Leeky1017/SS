# TD12_bootstrap_se — Bootstrap标准误

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD12 |
| **Slug** | bootstrap_se |
| **名称(中文)** | Bootstrap标准误 |
| **Name(EN)** | Bootstrap SE |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Regression with bootstrap standard errors

## 使用场景

- 关键词：bootstrap, standard-error, regression

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__REPS__` | integer | 是 | Bootstrap replications (50-1000) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TD12_boot.csv | table | Bootstrap results |
| data_TD12_boot.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | bootstrap vce |

## 示例

```stata
* Template: TD12_bootstrap_se
* Script: assets/stata_do_library/do/TD12_bootstrap_se.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

