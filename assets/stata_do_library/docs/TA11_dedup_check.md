# TA11_dedup_check — 数据去重与唯一性检查

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA11 |
| **Slug** | dedup_check |
| **名称(中文)** | 数据去重与唯一性检查 |
| **Name(EN)** | Dedup Check |
| **家族** | data_management |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Check for duplicates and perform deduplication based on key variables

## 使用场景

- 关键词：duplicate, dedup, unique, distinct

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__KEY_VARS__` | string | 是 | Key variables |
| `__ACTION__` | string | 否 | Action type |
| `__SORT_VAR__` | string | 否 | Sort variable |
| `__SORT_ORDER__` | string | 否 | Sort order |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA11_dup_summary.csv | table | Duplicate summary |
| table_TA11_dup_details.csv | table | Duplicate details |
| data_TA11_deduped.dta | data | Deduplicated data |
| data_TA11_deduped.csv | data | Deduplicated CSV |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| distinct | ssc | Count distinct values |

## 示例

```stata
* Template: TA11_dedup_check
* Script: tasks/do/TA11_dedup_check.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

