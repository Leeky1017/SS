# TA09_quantile_groups — 分组变量生成

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA09 |
| **Slug** | quantile_groups |
| **名称(中文)** | 分组变量生成 |
| **Name(EN)** | Quantile Groups |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Generate group variables based on quantiles, equal intervals, or custom cutpoints

## 使用场景

- 关键词：quantile, group, categorize, xtile

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__SOURCE_VAR__` | string | 是 | Source variable |
| `__N_GROUPS__` | integer | 否 | Number of groups |
| `__METHOD__` | string | 否 | Method |
| `__CUTPOINTS__` | string | 否 | Custom cutpoints |
| `__BY_VAR__` | string | 否 | By variable |
| `__NEW_VAR__` | string | 否 | New variable name |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA09_group_summary.csv | table | Group summary |
| data_TA09_grouped.dta | data | Grouped data |
| data_TA09_grouped.csv | data | Grouped CSV |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xtile command |

## 示例

```stata
* Template: TA09_quantile_groups
* Script: tasks/do/TA09_quantile_groups.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

