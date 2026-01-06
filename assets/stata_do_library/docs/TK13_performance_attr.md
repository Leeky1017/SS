# TK13_performance_attr — 业绩归因

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK13 |
| **Slug** | performance_attr |
| **名称(中文)** | 业绩归因 |
| **Name(EN)** | Performance Attribution |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Portfolio performance attribution analysis

## 使用场景

- 关键词：attribution, performance, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__PORTFOLIO_RET__` | string | 是 | Portfolio return |
| `__BENCHMARK_RET__` | string | 是 | Benchmark return |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK13_perf.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| fig_TK13_attribution.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK13_attribution.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TK13_performance_attr
* Script: tasks/do/TK13_performance_attr.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

