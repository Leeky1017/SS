# TL05_roychowdhury — Roychowdhury真实盈余管理

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL05 |
| **Slug** | roychowdhury |
| **名称(中文)** | Roychowdhury真实盈余管理 |
| **Name(EN)** | Roychowdhury REM |
| **家族** | accounting |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Real earnings management (Roychowdhury 2006)

## 使用场景

- 关键词：roychowdhury, rem, real_earnings, accounting

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__CFO_VAR__` | string | 是 | CFO |
| `__PROD_VAR__` | string | 是 | Production costs |
| `__DISEXP_VAR__` | string | 是 | Discretionary expenses |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL05_rem.csv | table | REM results |
| data_TL05_rem.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TL05_roychowdhury
* Script: tasks/do/TL05_roychowdhury.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

