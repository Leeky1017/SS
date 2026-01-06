# TD05_robust_reg — 稳健回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD05 |
| **Slug** | robust_reg |
| **名称(中文)** | 稳健回归 |
| **Name(EN)** | Robust Reg |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Robust regression resistant to outliers

## 使用场景

- 关键词：robust, regression, outliers

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
| table_TD05_rreg.csv | table | Robust regression results |
| data_TD05_rreg.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | rreg command |

## 示例

```stata
* Template: TD05_robust_reg
* Script: tasks/do/TD05_robust_reg.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

