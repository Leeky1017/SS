# TL03_kothari — Kothari模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL03 |
| **Slug** | kothari |
| **名称(中文)** | Kothari模型 |
| **Name(EN)** | Kothari Model |
| **家族** | accounting |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Performance-matched discretionary accruals (Kothari)

## 使用场景

- 关键词：kothari, performance_matched, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TA_VAR__` | string | 是 | Total accruals |
| `__ROA_VAR__` | string | 是 | ROA |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL03_kothari.csv | table | Kothari results |
| data_TL03_kothari.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TL03_kothari
* Script: assets/stata_do_library/do/TL03_kothari.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

