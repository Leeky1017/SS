# TK18_liquidity_factor — 流动性因子

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK18 |
| **Slug** | liquidity_factor |
| **名称(中文)** | 流动性因子 |
| **Name(EN)** | Liquidity Factor |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Liquidity factor construction (Amihud, turnover)

## 使用场景

- 关键词：liquidity, factor, amihud, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VAR__` | string | 是 | Return variable |
| `__VOLUME_VAR__` | string | 是 | Volume variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK18_liq.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| fig_TK18_liquidity.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK18_factor.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK18_liquidity.csv | table | Liquidity results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TK18_liquidity_factor
* Script: tasks/do/TK18_liquidity_factor.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

