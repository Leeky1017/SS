# TS09_logit_classify — Logistic分类

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS09 |
| **Slug** | logit_classify |
| **名称(中文)** | Logistic分类 |
| **Name(EN)** | Logistic Classification |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Logistic regression for binary classification with confusion matrix and ROC curve

## 使用场景

- 关键词：logit, classification, roc, machine_learning

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable (0/1) |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__THRESHOLD__` | number | 否 | Classification threshold |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TS09_logit_result.csv | table | Logit results |
| table_TS09_confusion.csv | table | Confusion matrix |
| fig_TS09_roc.png | graph | ROC curve |
| data_TS09_logit.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | logit command |

## 示例

```stata
* Template: TS09_logit_classify
* Script: assets/stata_do_library/do/TS09_logit_classify.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

