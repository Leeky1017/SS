# TG15_iv_overid — 过度识别检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG15 |
| **Slug** | iv_overid |
| **名称(中文)** | 过度识别检验 |
| **Name(EN)** | IV Overid |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Overidentification tests for IV

## 使用场景

- 关键词：iv, sargan, hansen, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__ENDOG_VAR__` | string | 是 | Endogenous variable |
| `__INSTRUMENTS__` | string | 是 | Instruments |
| `__EXOG_VARS__` | string | 否 | Exogenous controls |
| `__CLUSTER_VAR__` | string | 否 | Cluster variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG15_overid_tests.csv | table | Overid tests |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| ivreg2 | ssc | IV regression |

## 示例

```stata
* Template: TG15_iv_overid
* Script: assets/stata_do_library/do/TG15_iv_overid.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

