# TD11_spline — 分段回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD11 |
| **Slug** | spline |
| **名称(中文)** | 分段回归 |
| **Name(EN)** | Spline |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Piecewise linear spline regression

## 使用场景

- 关键词：spline, piecewise, regression

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVAR__` | string | 是 | Independent variable |
| `__KNOT__` | number | 是 | Knot point |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TD11_spline.csv | table | Spline results |
| data_TD11_spline.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mkspline command |

## 示例

```stata
* Template: TD11_spline
* Script: assets/stata_do_library/do/TD11_spline.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

