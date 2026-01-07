# TL12_ohlson_oscore — Ohlson O分数

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL12 |
| **Slug** | ohlson_oscore |
| **名称(中文)** | Ohlson O分数 |
| **Name(EN)** | Ohlson O-Score |
| **家族** | accounting |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Ohlson O-Score for bankruptcy prediction

## 使用场景

- 关键词：ohlson, oscore, bankruptcy, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__SIZE__` | string | 是 | Size |
| `__LEVERAGE__` | string | 是 | Leverage |
| `__NI__` | string | 是 | Net income |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL12_oscore.csv | table | O-Score results |
| data_TL12_oscore.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TL12_ohlson_oscore
* Script: assets/stata_do_library/do/TL12_ohlson_oscore.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

