# TK04_garch_model — GARCH模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK04 |
| **Slug** | garch_model |
| **名称(中文)** | GARCH模型 |
| **Name(EN)** | GARCH Model |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

GARCH volatility modeling

## 使用场景

- 关键词：garch, volatility, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VAR__` | string | 是 | Return variable |
| `__ARCH__` | integer | 否 | ARCH order |
| `__GARCH__` | integer | 否 | GARCH order |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK04_garch.dta | data | Output data |
| fig_TK04_volatility.png | graph | Volatility plot |
| result.log | log | Execution log |
| table_TK04_garch_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK04_volatility.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | arch command |

## 示例

```stata
* Template: TK04_garch_model
* Script: tasks/do/TK04_garch_model.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

