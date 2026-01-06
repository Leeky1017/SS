# TL10_fscore — Piotroski F分数

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL10 |
| **Slug** | fscore |
| **名称(中文)** | Piotroski F分数 |
| **Name(EN)** | Piotroski F-Score |
| **家族** | accounting |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Piotroski F-Score for financial strength

## 使用场景

- 关键词：piotroski, fscore, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__ROA__` | string | 是 | ROA |
| `__CFO__` | string | 是 | CFO |
| `__LEVERAGE__` | string | 是 | Leverage |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL10_fscore.csv | table | F-Score results |
| data_TL10_fscore.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TL10_fscore
* Script: tasks/do/TL10_fscore.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

