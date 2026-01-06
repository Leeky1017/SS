# TB01_group_desc_table — 分组描述统计

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TB01 |
| **Slug** | group_desc_table |
| **名称(中文)** | 分组描述统计 |
| **Name(EN)** | Group Desc Table |
| **家族** | descriptive_statistics |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Generate grouped descriptive statistics table in paper Table 1 format

## 使用场景

- 关键词：descriptive, group, table1, summary

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | string | 是 | Numeric variables |
| `__BY_VAR__` | string | 是 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TB01_group_desc.csv | table | Group descriptive table |
| data_TB01_group.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | Summarize command |

## 示例

```stata
* Template: TB01_group_desc_table
* Script: tasks/do/TB01_group_desc_table.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

