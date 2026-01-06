# TK17_size_factor — 规模因子

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK17 |
| **Slug** | size_factor |
| **名称(中文)** | 规模因子 |
| **Name(EN)** | Size Factor |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Size factor construction (market cap)

## 使用场景

- 关键词：size, factor, smb, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__MKTCAP_VAR__` | string | 是 | Market cap variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK17_size.dta | data | Output data |
| fig_TK17_size.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK17_factor.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK17_size.csv | table | Size factor results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TK17_size_factor
* Script: tasks/do/TK17_size_factor.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

