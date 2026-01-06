# TP15_svy_tabulate — 调查列联表

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP15 |
| **Slug** | svy_tabulate |
| **名称(中文)** | 调查列联表 |
| **Name(EN)** | Survey Tabulate |
| **家族** | survey |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Survey-weighted tabulation

## 使用场景

- 关键词：survey, tabulate, weighted

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__ROWVAR__` | string | 是 | Row variable |
| `__COLVAR__` | string | 否 | Column variable |
| `__WEIGHT__` | string | 是 | Survey weight |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TP15_svy.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TP15_svytab.csv | table | Survey tabulation results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | svy tabulate command |

## 示例

```stata
* Template: TP15_svy_tabulate
* Script: tasks/do/TP15_svy_tabulate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

