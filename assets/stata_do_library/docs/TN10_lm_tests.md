# TN10_lm_tests — 空间LM检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TN10 |
| **Slug** | lm_tests |
| **名称(中文)** | 空间LM检验 |
| **Name(EN)** | Spatial LM Tests |
| **家族** | spatial |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Lagrange Multiplier tests for spatial dependence

## 使用场景

- 关键词：lm_test, spatial_dependence, diagnostics, spatial

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
| data_TN10_lm.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TN10_lm.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| spatdiag | ssc | Spatial diagnostics |

## 示例

```stata
* Template: TN10_lm_tests
* Script: tasks/do/TN10_lm_tests.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

