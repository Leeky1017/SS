# TO04_putexcel — Excel导出

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TO04 |
| **Slug** | putexcel |
| **名称(中文)** | Excel导出 |
| **Name(EN)** | Putexcel |
| **家族** | output |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Export results to Excel using putexcel

## 使用场景

- 关键词：putexcel, excel, export, output

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__SHEET__` | string | 否 | Sheet name |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TO04_export.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TO04_results.xlsx | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | putexcel command |

## 示例

```stata
* Template: TO04_putexcel
* Script: assets/stata_do_library/do/TO04_putexcel.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

