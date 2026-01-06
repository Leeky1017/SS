# TK05_var_calculate — VaR计算

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK05 |
| **Slug** | var_calculate |
| **名称(中文)** | VaR计算 |
| **Name(EN)** | VaR Calculate |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Value at Risk calculation

## 使用场景

- 关键词：var, risk, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VAR__` | string | 是 | Return variable |
| `__CONF_LEVEL__` | number | 否 | Confidence level |
| `__METHOD__` | string | 否 | Method: historical/parametric |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK05_var.dta | data | Output data |
| fig_TK05_var_plot.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK05_backtest.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK05_var_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | percentile command |

## 示例

```stata
* Template: TK05_var_calculate
* Script: tasks/do/TK05_var_calculate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

