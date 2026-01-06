# TC05_wilcoxon_signed — Wilcoxon符号秩检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TC05 |
| **Slug** | wilcoxon_signed |
| **名称(中文)** | Wilcoxon符号秩检验 |
| **Name(EN)** | Wilcoxon Signed |
| **家族** | hypothesis_testing |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Wilcoxon signed-rank test for paired data

## 使用场景

- 关键词：nonparametric, wilcoxon, paired

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR1__` | string | 是 | Variable 1 |
| `__VAR2__` | string | 是 | Variable 2 |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TC05_wilcox.csv | table | Wilcoxon test results |
| data_TC05_wilcox.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | signrank command |

## 示例

```stata
* Template: TC05_wilcoxon_signed
* Script: tasks/do/TC05_wilcoxon_signed.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

