# TG14_iv_weak_test — 弱工具变量检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG14 |
| **Slug** | iv_weak_test |
| **名称(中文)** | 弱工具变量检验 |
| **Name(EN)** | IV Weak Test |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Weak instrument tests for IV

## 使用场景

- 关键词：iv, weak, stockyogo, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEP_VAR__` | string | 是 | Dependent variable |
| `__ENDOG_VAR__` | string | 是 | Endogenous variable |
| `__INSTRUMENTS__` | string | 是 | Instruments |
| `__EXOG_VARS__` | string | 否 | Exogenous controls |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG14_weak_iv_tests.csv | table | Weak IV tests |
| table_TG14_critical_values.csv | table | Critical values |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| ivreg2 | ssc | IV regression |
| ranktest | ssc | Rank test |

## 示例

```stata
* Template: TG14_iv_weak_test
* Script: assets/stata_do_library/do/TG14_iv_weak_test.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

