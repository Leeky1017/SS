# TO07_graph_export — 图形导出

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TO07 |
| **Slug** | graph_export |
| **名称(中文)** | 图形导出 |
| **Name(EN)** | Graph Export |
| **家族** | output |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Export graphs to various formats

## 使用场景

- 关键词：graph, export, png, pdf, output

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__FORMAT__` | string | 否 | Export format: png/pdf/eps |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TO07_export.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| fig_TO07_scatter.pdf | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| fig_TO07_scatter.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | graph export |

## 示例

```stata
* Template: TO07_graph_export
* Script: assets/stata_do_library/do/TO07_graph_export.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

