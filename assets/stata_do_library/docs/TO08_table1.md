# TO08_table1 — 描述性统计表

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TO08 |
| **Slug** | table1 |
| **名称(中文)** | 描述性统计表 |
| **Name(EN)** | Table 1 |
| **家族** | output |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Create publication-ready Table 1 with descriptive statistics

## 使用场景

- 关键词：table1, descriptive, publication, output

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | list[string] | 是 | Variables |
| `__BY_VAR__` | string | 否 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TO08_export.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TO08_table1.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TO08_table1.doc | report | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| table1_mc | ssc | Table 1 creation |

## 示例

```stata
* Template: TO08_table1
* Script: tasks/do/TO08_table1.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

