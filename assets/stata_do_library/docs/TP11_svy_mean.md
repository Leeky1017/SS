# TP11_svy_mean — 调查均值

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP11 |
| **Slug** | svy_mean |
| **名称(中文)** | 调查均值 |
| **Name(EN)** | Survey Mean |
| **家族** | survey |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Survey-weighted mean estimation

## 使用场景

- 关键词：survey, mean, weighted

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | list[string] | 是 | Variables |
| `__WEIGHT__` | string | 是 | Survey weight |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TP11_svy.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TP11_svymean.csv | table | Survey mean results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | svy mean command |

## 示例

```stata
* Template: TP11_svy_mean
* Script: assets/stata_do_library/do/TP11_svy_mean.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

