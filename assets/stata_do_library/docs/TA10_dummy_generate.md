# TA10_dummy_generate — 虚拟变量批量生成

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA10 |
| **Slug** | dummy_generate |
| **名称(中文)** | 虚拟变量批量生成 |
| **Name(EN)** | Dummy Generate |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Generate dummy variables for categorical variables with base group selection

## 使用场景

- 关键词：dummy, indicator, categorical, one-hot

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__CAT_VARS__` | string | 是 | Categorical variables |
| `__BASE_CATEGORY__` | string | 否 | Base category |
| `__PREFIX__` | string | 否 | Dummy prefix |
| `__DROP_FIRST__` | string | 否 | Drop first dummy |
| `__INTERACTION__` | string | 否 | Interaction terms |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA10_dummy_codebook.csv | table | Dummy codebook |
| data_TA10_with_dummies.dta | data | Data with dummies |
| data_TA10_with_dummies.csv | data | Data CSV with dummies |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | tabulate command |

## 示例

```stata
* Template: TA10_dummy_generate
* Script: tasks/do/TA10_dummy_generate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

