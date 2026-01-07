# TD07_lasso — LASSO回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD07 |
| **Slug** | lasso |
| **名称(中文)** | LASSO回归 |
| **Name(EN)** | LASSO |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

LASSO regression with L1 regularization

## 使用场景

- 关键词：lasso, regularization, variable-selection

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TD07_lasso.csv | table | LASSO results |
| data_TD07_lasso.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | lasso command |

## 示例

```stata
* Template: TD07_lasso
* Script: assets/stata_do_library/do/TD07_lasso.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

