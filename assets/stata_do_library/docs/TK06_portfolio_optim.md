# TK06_portfolio_optim — 组合优化

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK06 |
| **Slug** | portfolio_optim |
| **名称(中文)** | 组合优化 |
| **Name(EN)** | Portfolio Optimization |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Mean-variance portfolio optimization

## 使用场景

- 关键词：portfolio, optimization, markowitz, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VARS__` | list[string] | 是 | Asset returns |
| `__TARGET_RETURN__` | number | 否 | Target return |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK06_portfolio.dta | data | Output data |
| fig_TK06_frontier.png | graph | Efficient frontier |
| result.log | log | Execution log |
| table_TK06_frontier.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK06_weights.csv | table | Optimal weights |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | matrix operations |

## 示例

```stata
* Template: TK06_portfolio_optim
* Script: tasks/do/TK06_portfolio_optim.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

