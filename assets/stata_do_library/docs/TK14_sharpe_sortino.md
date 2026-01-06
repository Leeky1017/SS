# TK14_sharpe_sortino — 夏普和索提诺比率

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK14 |
| **Slug** | sharpe_sortino |
| **名称(中文)** | 夏普和索提诺比率 |
| **Name(EN)** | Sharpe Sortino |
| **家族** | finance |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Calculate Sharpe ratio and Sortino ratio

## 使用场景

- 关键词：sharpe, sortino, risk_adjusted, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VAR__` | string | 是 | Return variable |
| `__RF_VAR__` | string | 否 | Risk-free rate |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK14_risk.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| fig_TK14_drawdown.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK14_metrics.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TK14_sharpe_sortino
* Script: tasks/do/TK14_sharpe_sortino.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

