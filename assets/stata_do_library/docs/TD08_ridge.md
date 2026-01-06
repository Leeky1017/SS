# TD08_ridge — 岭回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD08 |
| **Slug** | ridge |
| **名称(中文)** | 岭回归 |
| **Name(EN)** | Ridge |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Ridge regression with L2 regularization

## 使用场景

- 关键词：ridge, regularization, shrinkage

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
| table_TD08_ridge.csv | table | Ridge results |
| data_TD08_ridge.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | elasticnet command |

## 示例

```stata
* Template: TD08_ridge
* Script: tasks/do/TD08_ridge.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

