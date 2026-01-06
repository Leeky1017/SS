# TM03_kappa — Kappa一致性

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM03 |
| **Slug** | kappa |
| **名称(中文)** | Kappa一致性 |
| **Name(EN)** | Kappa Agreement |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Cohen's Kappa for inter-rater agreement

## 使用场景

- 关键词：kappa, agreement, reliability, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RATER1__` | string | 是 | Rater 1 |
| `__RATER2__` | string | 是 | Rater 2 |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TM03_kappa.csv | table | Kappa results |
| data_TM03_kappa.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | kap command |

## 示例

```stata
* Template: TM03_kappa
* Script: tasks/do/TM03_kappa.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

