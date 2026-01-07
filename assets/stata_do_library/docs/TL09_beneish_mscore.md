# TL09_beneish_mscore — Beneish M分数

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL09 |
| **Slug** | beneish_mscore |
| **名称(中文)** | Beneish M分数 |
| **Name(EN)** | Beneish M-Score |
| **家族** | accounting |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Beneish M-Score for fraud detection

## 使用场景

- 关键词：beneish, mscore, fraud, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DSRI__` | string | 是 | Days Sales Receivables Index |
| `__GMI__` | string | 是 | Gross Margin Index |
| `__AQI__` | string | 是 | Asset Quality Index |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL09_mscore.csv | table | M-Score results |
| data_TL09_mscore.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TL09_beneish_mscore
* Script: assets/stata_do_library/do/TL09_beneish_mscore.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

