# TD06_stepwise — 逐步回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD06 |
| **Slug** | stepwise |
| **名称(中文)** | 逐步回归 |
| **Name(EN)** | Stepwise |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Stepwise regression for variable selection

## 使用场景

- 关键词：stepwise, variable-selection, regression

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
| table_TD06_step.csv | table | Stepwise results |
| data_TD06_step.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | stepwise command |

## 示例

```stata
* Template: TD06_stepwise
* Script: tasks/do/TD06_stepwise.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

