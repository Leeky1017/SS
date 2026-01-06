# TM01_roc_analysis — ROC分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM01 |
| **Slug** | roc_analysis |
| **名称(中文)** | ROC分析 |
| **Name(EN)** | ROC Analysis |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

ROC curve analysis for diagnostic test evaluation

## 使用场景

- 关键词：roc, auc, diagnostic, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME__` | string | 是 | Binary outcome |
| `__TEST_VAR__` | string | 是 | Test variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TM01_roc.csv | table | ROC results |
| fig_TM01_roc.png | graph | ROC curve |
| data_TM01_roc.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | roctab command |

## 示例

```stata
* Template: TM01_roc_analysis
* Script: tasks/do/TM01_roc_analysis.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

