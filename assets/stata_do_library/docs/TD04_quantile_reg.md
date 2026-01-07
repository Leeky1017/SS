# TD04_quantile_reg — 分位数回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD04 |
| **Slug** | quantile_reg |
| **名称(中文)** | 分位数回归 |
| **Name(EN)** | Quantile Reg |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Quantile regression at multiple quantiles

## 使用场景

- 关键词：quantile, regression, percentile

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
| table_TD04_qreg.csv | table | Quantile regression results |
| fig_TD04_qreg.png | figure | Quantile regression plot |
| data_TD04_qreg.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | sqreg command |

## 示例

```stata
* Template: TD04_quantile_reg
* Script: assets/stata_do_library/do/TD04_quantile_reg.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

