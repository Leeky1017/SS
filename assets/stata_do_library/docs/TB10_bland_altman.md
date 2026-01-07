# TB10_bland_altman — Bland-Altman一致性图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TB10 |
| **Slug** | bland_altman |
| **名称(中文)** | Bland-Altman一致性图 |
| **Name(EN)** | Bland Altman |
| **家族** | descriptive_statistics |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Draw Bland-Altman plot to assess measurement agreement

## 使用场景

- 关键词：bland-altman, agreement, reliability

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR1__` | string | 是 | Method 1 variable |
| `__VAR2__` | string | 是 | Method 2 variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TB10_ba.png | figure | Bland-Altman plot |
| table_TB10_ba.csv | table | BA statistics |
| data_TB10_ba.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | scatter and summarize |

## 示例

```stata
* Template: TB10_bland_altman
* Script: assets/stata_do_library/do/TB10_bland_altman.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

