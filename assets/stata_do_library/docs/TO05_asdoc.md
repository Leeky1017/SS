# TO05_asdoc — Asdoc文档

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TO05 |
| **Slug** | asdoc |
| **名称(中文)** | Asdoc文档 |
| **Name(EN)** | Asdoc |
| **家族** | output |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Export results using asdoc package

## 使用场景

- 关键词：asdoc, word, export, output

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TITLE__` | string | 否 | Table title |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TO05_export.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TO05_asdoc.doc | report | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| asdoc | ssc | Word export |

## 示例

```stata
* Template: TO05_asdoc
* Script: assets/stata_do_library/do/TO05_asdoc.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

