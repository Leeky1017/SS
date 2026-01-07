# TL11_altman_zscore — Altman Z分数

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL11 |
| **Slug** | altman_zscore |
| **名称(中文)** | Altman Z分数 |
| **Name(EN)** | Altman Z-Score |
| **家族** | accounting |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Altman Z-Score for bankruptcy prediction

## 使用场景

- 关键词：altman, zscore, bankruptcy, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__WC_TA__` | string | 是 | Working capital/Total assets |
| `__RE_TA__` | string | 是 | Retained earnings/Total assets |
| `__EBIT_TA__` | string | 是 | EBIT/Total assets |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL11_zscore.csv | table | Z-Score results |
| data_TL11_zscore.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TL11_altman_zscore
* Script: assets/stata_do_library/do/TL11_altman_zscore.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

