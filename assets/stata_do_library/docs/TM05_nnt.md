# TM05_nnt — 需治数

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM05 |
| **Slug** | nnt |
| **名称(中文)** | 需治数 |
| **Name(EN)** | NNT |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Number Needed to Treat calculation

## 使用场景

- 关键词：nnt, treatment_effect, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME__` | string | 是 | Outcome variable |
| `__TREATMENT__` | string | 是 | Treatment variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TM05_nnt.csv | table | NNT results |
| data_TM05_nnt.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | cs command |

## 示例

```stata
* Template: TM05_nnt
* Script: tasks/do/TM05_nnt.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

