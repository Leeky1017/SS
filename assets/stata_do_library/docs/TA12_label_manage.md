# TA12_label_manage — 变量标签批量管理

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA12 |
| **Slug** | label_manage |
| **名称(中文)** | 变量标签批量管理 |
| **Name(EN)** | Label Manage |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Batch manage variable labels and value labels with import/export/clean/auto

## 使用场景

- 关键词：label, variable, metadata, codebook

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |
| label_dict.csv | config | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OPERATION__` | string | 否 | Operation type |
| `__DICT_FILE__` | string | 否 | Label dictionary file |
| `__TARGET_VARS__` | string | 否 | Target variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TA12_labeled.dta | data | Labeled data |
| label_dict_template.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TA12_label_export.csv | table | Label export |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | Label commands |

## 示例

```stata
* Template: TA12_label_manage
* Script: assets/stata_do_library/do/TA12_label_manage.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

