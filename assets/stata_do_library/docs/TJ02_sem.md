# TJ02_sem — 结构方程模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TJ02 |
| **Slug** | sem |
| **名称(中文)** | 结构方程模型 |
| **Name(EN)** | SEM Analysis |
| **家族** | latent_variable |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Structural Equation Modeling

## 使用场景

- 关键词：sem, structural_equation, latent

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__MODEL__` | string | 是 | SEM model specification |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TJ02_sem.csv | table | SEM results |
| data_TJ02_sem.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | sem command |

## 示例

```stata
* Template: TJ02_sem
* Script: tasks/do/TJ02_sem.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

