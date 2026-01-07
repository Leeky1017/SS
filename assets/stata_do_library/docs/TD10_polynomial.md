# TD10_polynomial — 多项式回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD10 |
| **Slug** | polynomial |
| **名称(中文)** | 多项式回归 |
| **Name(EN)** | Polynomial |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Polynomial regression for nonlinear relationships

## 使用场景

- 关键词：polynomial, nonlinear, regression

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVAR__` | string | 是 | Independent variable |
| `__DEGREE__` | integer | 是 | Polynomial degree (2-5) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TD10_poly.csv | table | Polynomial results |
| fig_TD10_poly.png | figure | Polynomial plot |
| data_TD10_poly.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TD10_polynomial
* Script: assets/stata_do_library/do/TD10_polynomial.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

