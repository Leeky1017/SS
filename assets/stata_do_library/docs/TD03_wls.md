# TD03_wls — 加权最小二乘

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD03 |
| **Slug** | wls |
| **名称(中文)** | 加权最小二乘 |
| **Name(EN)** | WLS |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Weighted least squares regression

## 使用场景

- 关键词：wls, weighted, regression

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__WEIGHT_VAR__` | string | 是 | Weight variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TD03_wls.csv | table | WLS results |
| data_TD03_wls.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress with weights |

## 示例

```stata
* Template: TD03_wls
* Script: tasks/do/TD03_wls.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

