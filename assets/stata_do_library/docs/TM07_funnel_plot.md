# TM07_funnel_plot — 漏斗图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM07 |
| **Slug** | funnel_plot |
| **名称(中文)** | 漏斗图 |
| **Name(EN)** | Funnel Plot |
| **家族** | medical |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Funnel plot for publication bias assessment

## 使用场景

- 关键词：funnel, publication_bias, meta, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__EFFECT__` | string | 是 | Effect size |
| `__SE__` | string | 是 | Standard error |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TM07_bias.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| fig_TM07_funnel.png | graph | Funnel plot |
| result.log | log | Execution log |
| table_TM07_bias.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| metafunnel | ssc | Funnel plots |

## 示例

```stata
* Template: TM07_funnel_plot
* Script: tasks/do/TM07_funnel_plot.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

