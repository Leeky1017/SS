# TE05_twopm — 双栏模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TE05 |
| **Slug** | twopm |
| **名称(中文)** | 双栏模型 |
| **Name(EN)** | Two-Part |
| **家族** | limited_dependent |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Two-part model for semi-continuous data

## 使用场景

- 关键词：two-part, semi-continuous, hurdle

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TE05_twopm.csv | table | Two-Part results |
| data_TE05_twopm.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| twopm | ssc | two-part model |

## 示例

```stata
* Template: TE05_twopm
* Script: tasks/do/TE05_twopm.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

