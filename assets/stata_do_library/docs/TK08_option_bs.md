# TK08_option_bs — Black-Scholes期权定价

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK08 |
| **Slug** | option_bs |
| **名称(中文)** | Black-Scholes期权定价 |
| **Name(EN)** | Black-Scholes |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Black-Scholes option pricing model

## 使用场景

- 关键词：option, black_scholes, derivatives, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__SPOT__` | number | 是 | Spot price |
| `__STRIKE__` | number | 是 | Strike price |
| `__VOLATILITY__` | number | 是 | Volatility |
| `__RF_RATE__` | number | 是 | Risk-free rate |
| `__TIME__` | number | 是 | Time to expiry |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TK08_payoff.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK08_greeks.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK08_option_price.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | normal calculations |

## 示例

```stata
* Template: TK08_option_bs
* Script: tasks/do/TK08_option_bs.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

