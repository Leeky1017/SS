# TA14_data_quality — 数据质量诊断报告

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA14 |
| **Slug** | data_quality |
| **名称(中文)** | 数据质量诊断报告 |
| **Name(EN)** | Data Quality |
| **家族** | data_management |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Comprehensive data quality assessment with missing values, outliers, and consistency checks

## 使用场景

- 关键词：quality, diagnostic, missing, validation

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__CHECK_VARS__` | string | 否 | Variables to check |
| `__ID_VAR__` | string | 否 | ID variable |
| `__QUALITY_THRESHOLD__` | number | 否 | Quality threshold |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA14_quality_summary.csv | table | Quality summary |
| table_TA14_var_diagnostics.csv | table | Variable diagnostics |
| table_TA14_issues.csv | table | Issues list |
| fig_TA14_quality_heatmap.png | figure | Quality heatmap |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| mdesc | ssc | Missing data description |

## 示例

```stata
* Template: TA14_data_quality
* Script: assets/stata_do_library/do/TA14_data_quality.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

