# TM08_case_control — 病例对照研究

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM08 |
| **Slug** | case_control |
| **名称(中文)** | 病例对照研究 |
| **Name(EN)** | Case Control |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Case-control study odds ratio analysis

## 使用场景

- 关键词：case_control, odds_ratio, epidemiology, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__CASE__` | string | 是 | Case indicator |
| `__EXPOSURE__` | string | 是 | Exposure |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TM08_or.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TM08_or.csv | table | OR results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | cc command |

## 示例

```stata
* Template: TM08_case_control
* Script: tasks/do/TM08_case_control.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

