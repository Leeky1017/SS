# TE08_mixlogit — 混合Logit

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TE08 |
| **Slug** | mixlogit |
| **名称(中文)** | 混合Logit |
| **Name(EN)** | Mixed Logit |
| **家族** | limited_dependent |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Mixed logit for discrete choice data

## 使用场景

- 关键词：mixlogit, mixed, discrete-choice

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__GROUP_VAR__` | string | 是 | Group variable |
| `__RAND_VARS__` | string | 是 | Random coefficient variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TE08_mixlogit.csv | table | Mixed Logit results |
| data_TE08_mixlogit.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| mixlogit | ssc | mixed logit model |

## 示例

```stata
* Template: TE08_mixlogit
* Script: tasks/do/TE08_mixlogit.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

