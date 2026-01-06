# TM10_matched_cc — 配对病例对照

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM10 |
| **Slug** | matched_cc |
| **名称(中文)** | 配对病例对照 |
| **Name(EN)** | Matched Case Control |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Matched case-control study analysis

## 使用场景

- 关键词：matched, case_control, mcnemar, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__CASE__` | string | 是 | Case indicator |
| `__EXPOSURE__` | string | 是 | Exposure |
| `__MATCH_ID__` | string | 是 | Match ID |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TM10_mcc.csv | table | Matched CC results |
| data_TM10_mcc.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mcc command |

## 示例

```stata
* Template: TM10_matched_cc
* Script: tasks/do/TM10_matched_cc.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

