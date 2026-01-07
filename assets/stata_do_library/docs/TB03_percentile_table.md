# TB03_percentile_table — 百分位数表

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TB03 |
| **Slug** | percentile_table |
| **名称(中文)** | 百分位数表 |
| **Name(EN)** | Percentile Table |
| **家族** | descriptive_statistics |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Calculate percentiles and quantiles table for numeric variables

## 使用场景

- 关键词：percentile, quantile, distribution

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | string | 是 | Numeric variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TB03_percentiles.csv | table | Percentile table |
| data_TB03_pct.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | summarize detail |

## 示例

```stata
* Template: TB03_percentile_table
* Script: assets/stata_do_library/do/TB03_percentile_table.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

