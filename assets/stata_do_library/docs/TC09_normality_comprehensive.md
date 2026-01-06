# TC09_normality_comprehensive — 正态性综合检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TC09 |
| **Slug** | normality_comprehensive |
| **名称(中文)** | 正态性综合检验 |
| **Name(EN)** | Normality Comprehensive |
| **家族** | hypothesis_testing |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Comprehensive normality tests (Shapiro-Wilk, Shapiro-Francia)

## 使用场景

- 关键词：normality, shapiro-wilk, shapiro-francia

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | string | 是 | Variables to test |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TC09_norm.csv | table | Normality test results |
| data_TC09_norm.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | swilk sfrancia |

## 示例

```stata
* Template: TC09_normality_comprehensive
* Script: tasks/do/TC09_normality_comprehensive.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

