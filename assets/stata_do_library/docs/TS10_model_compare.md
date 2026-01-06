# TS10_model_compare — 模型比较

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS10 |
| **Slug** | model_compare |
| **名称(中文)** | 模型比较 |
| **Name(EN)** | Model Comparison |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Compare multiple models using AIC, BIC, and RMSE criteria

## 使用场景

- 关键词：model_comparison, aic, bic, machine_learning

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TS10_comparison.csv | table | Model comparison |
| fig_TS10_comparison.png | graph | Comparison plot |
| data_TS10_compare.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regression commands |

## 示例

```stata
* Template: TS10_model_compare
* Script: tasks/do/TS10_model_compare.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

