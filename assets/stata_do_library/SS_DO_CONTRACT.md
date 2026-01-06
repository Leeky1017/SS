# SS_DO_CONTRACT — Stata Do Library 硬契约（v1.1）

> **版本**: 1.1  
> **状态**: ENFORCED（强制执行）  
> **适用范围**: `tasks/do/**/*.do` 下全部 `.do` 文件（不分新旧、不分模块）  
> **硬门槛**: TaskD 的 `domain/log_analyzer.py` 必须能稳定解析 `SS_*` 锚点  
> **更新日期**: 2024-12-13

---

## 1. 标准怎么定（结论先行）

- **统一硬契约（必须）**：所有 `.do` 一刀切满足本合同 §3（0 例外）。
- **分级增强（受控）**：`L0/L1/L2` 只决定"额外能力"，不改变硬契约；**不以行数作为质量指标**。
- **数量服从质量**：发现重复就合并/降级为 alias；发现缺口就补齐；但必须覆盖 `DO_LIBRARY_EXPANSION_PLAN.md` 需求面。

---

## 2. 真实输入（唯一依据）

| 文件 | 用途 |
|------|------|
| `tasks/DO_LIBRARY_EXPANSION_PLAN.md` | 需求规划（模块清单/覆盖面/新增方向） |
| `stata_dependencies.txt` | 依赖白名单（官方 + 社区命令） |
| `tasks/DO_AUDIT_REPORT.md` | 现状审计 |
| `tasks/DO_LIBRARY_INDEX.json` | 机器可读索引 |
| `tasks/DO_LINT_RULES.py` | 可执行门禁 |
| `domain/log_analyzer.py` | SS 系统解析约束（锚点可解析性是硬门槛） |

---

## 3. 硬契约（所有 .do 必须满足，0 例外）

### 3.1 SS_* 锚点协议（必须输出到 log 的 `di` 行）

**通用要求**

- 每条锚点 **必须独占一行**，且以 `SS_` 开头。
- 只允许 **ASCII 可打印字符**（`0x20-0x7E`）；若模板标题/描述为中文，锚点里必须用 ASCII 的 `slug`/转写版本。
- 单行不超过 **200 字符**（必要时拆分为多行 `SS_SUMMARY`）。
- 格式采用 **管道分隔键值对**：`SS_EVENT|key1=value1|key2=value2`

#### 3.1.1 任务边界（必需）

```
SS_TASK_BEGIN|id=<Txxx>|level=<L0|L1|L2>|title=<ascii_title>
SS_TASK_END|id=<Txxx>|status=<ok|warn|fail>|elapsed_sec=<int>
```

兼容：允许同时输出旧版 `SS_TASK_START:<...>`，但 **不得替代** `SS_TASK_BEGIN|...`。

#### 3.1.2 步骤边界（必需；每个关键步骤至少 3 个）

至少包含 3 个关键 step：`load` / `analysis` / `export`（可更多）。

```
SS_STEP_BEGIN|step=<S01_xxx>
SS_STEP_END|step=<S01_xxx>|status=<ok|warn|fail>|elapsed_sec=<int>
```

#### 3.1.3 依赖检查（必需）

```
SS_DEP_CHECK|pkg=<name>|source=<ssc|net|built-in>|status=<ok|missing>
```

缺依赖必须：
- `SS_DEP_MISSING|pkg=<name>`
- `SS_RC|code=199|cmd=which <name>|msg=dependency_missing|severity=fail`
- `SS_TASK_END|id=<Txxx>|status=fail|elapsed_sec=<int>` 并 `exit 199`

#### 3.1.4 输出声明（必需；每个产物必须声明）

```
SS_OUTPUT_FILE|file=<relative_path>|type=<log|table|graph|model|report|data>|desc=<ascii_desc>
```

#### 3.1.5 指标（必需；任务末尾输出，至少 4 个）

```
SS_METRIC|name=n_obs|value=<int>
SS_METRIC|name=n_missing|value=<int>
SS_METRIC|name=task_success|value=<0|1>
SS_METRIC|name=elapsed_sec|value=<int>
```

凡涉及随机性（抽样/匹配/交叉验证等），必须额外输出：

```
SS_METRIC|name=seed|value=<int>
```

#### 3.1.6 结果摘要（必需；最少 3 条，给 LLM/报告用）

```
SS_SUMMARY|key=<ascii_key>|value=<ascii_value>
```

建议覆盖：样本量、核心结论（系数/效应方向/显著性）、关键诊断结论。

#### 3.1.7 错误记录（必需；严禁沉默失败）

```
SS_RC|code=<_rc>|cmd=<short_cmd>|msg=<short_msg>|severity=<warn|fail>
```

**任何 `capture` 后必须检查 `_rc`**，否则直接判定为 FAIL。

---

### 3.2 do 文件顶部"头部声明区"（必须为可静态解析的注释块）

必须包含四段（按顺序），且字段名/枚举值固定：

```stata
* ==============================================================================
* SS_TEMPLATE: id=Txxx  level=L0  module=A  title="..."
* INPUTS:
*   - <name>  role=<main_dataset|merge_table|lookup|appendix|other>  required=<yes|no>
* OUTPUTS:
*   - <relative_path> type=<log|table|graph|model|report|data> desc="..."
* DEPENDENCIES:
*   - <pkg> source=<built-in|ssc|net>  purpose="..."
* ==============================================================================
```

**role 枚举值**：`main_dataset` | `merge_table` | `lookup` | `appendix` | `other`  
**type 枚举值**：`log` | `table` | `graph` | `model` | `report` | `data`  
**source 枚举值**：`built-in` | `ssc` | `net`

---

### 3.3 安全与可运行性约束（必须）

| 约束 | 说明 |
|------|------|
| 禁止硬编码绝对路径 | Windows 盘符、`/home/...`、`/Users/...` 等均不允许；只允许相对路径或 SS 注入变量 |
| 禁止交互式停顿 | `pause` / `sleep` / `_request()` / 等待用户输入 |
| 禁止吞错 | `capture` 允许使用，但必须 `_rc` 分支处理并输出 `SS_RC` |
| 社区命令受控 | **必须**在 `stata_dependencies.txt` 白名单内；否则模板不得落库 |

---

## 4. 分级标准（L0/L1/L2：只加能力，不加废话）

先把"硬契约"做齐，再谈分级。

### L0（基础可出货）

- 满足硬契约
- 产出至少 1 个可下载文件（`table/graph/report/data/model` 任一；不含仅 `log`）
- 最少 3 个 `SS_SUMMARY` 摘要行
- 不要求额外诊断，但必须可审计、可复跑、可解析

### L1（业务可用）

- L0 + **稳健性块**：缺变量/缺样本/异常分布 → `warn` 或 `fail`（必须输出 `SS_RC/SS_METRIC`）
- L0 + **更完整交付**：至少 1 张表 + 1 段 summary 文本或 report

### L2（专业增强）

- L1 + **诊断/质量控制**（按模板类型选择：共线性/残差/拟合优度/敏感性/稳健标准误等）
- L1 + **报告化输出**（可直接交付，不要求用户再加工）

---

## 5. do 本体内容升级规范（必须执行）

### 5.1 标准骨架（每个模板必须具备）

**运行前置**
- `version` 固定
- `set more off`
- `capture log close _all`
- 统一 timer：`timer clear 1` / `timer on 1` / `timer off 1`
- 涉及随机性必须 `set seed <固定值>` 并输出 `SS_METRIC|name=seed|value=...`

**输入验证（必须可解释失败原因）**
- `confirm file` / `confirm variable` / `isid` / `duplicates report`
- 缺失、重复、键不唯一、样本过小：必须输出 `SS_RC`，并决定 `warn/fail`
- 关键变量缺失率：`SS_METRIC|name=missing_rate_<var>|value=<float>`

**数据准备（可追溯）**
- 最小画像：`describe` / `summarize` / `tabulate`（按需）
- 任何 `drop/keep/merge/reshape`：必须有 step 锚点 + 变更前后样本量

**核心分析（模板主题的最小正确实现）**
- 必须包含该模板主题的最小正确实现
- 必须处理常见失败（共线性/完全预测/收敛失败/样本不足），并输出 `SS_RC`

**导出交付（用户可直接用）**
- 至少 1 份表（csv/xlsx/tex 任一）
- 若有图：导出 png/pdf
- 所有导出必须配 `SS_OUTPUT_FILE|...`

**结果摘要（给 LLM/报告用）**
- 最少 3 条 `SS_SUMMARY|key=...|value=...`（必须 ASCII）

### 5.2 按模块的内容升级最小集

| 模块 | 最小正确性要求 |
|------|----------------|
| 清洗/合并/整形（A/B/C） | 键校验 + merge 结果分布 + 冲突策略 + 输出清洗后数据/对账表 |
| 描述统计/可视化（D/T） | 分组统计 + 缺失/异常值报告 + 至少 1 图 + 表导出 |
| 回归类（E/F/H/J） | 稳健标准误策略（明确）+ 缺失处理 + 回归表导出 + 关键系数摘要 |
| 面板/双向固定效应（P/Q） | xtset 校验 + FE/聚类策略（明确）+ 诊断（至少：被省略变量计数） |
| DID/事件研究（G） | 平行趋势可视化或检验（至少一种）+ 事件窗口定义 + 主结果表 |
| IV（I） | 弱工具诊断（至少：first-stage 核心统计量）+ 主结果表 |
| PSM/加权（K/L） | 平衡性检验（至少一种）+ 匹配质量指标 + 主结果 |
| RD（M） | 带宽策略（至少一种）+ 操纵/密度检验（依赖允许则做）+ 主结果 |
| 时间序列（N） | 平稳性/滞后选择（至少一种）+ 预测/拟合输出 |
| 医学/生存（R） | 模型假设检验或关键诊断（至少一种）+ 生存曲线/表输出 |

---

## 6. 索引与元数据（系统可选模板 + 填参数 + 审计）

### 6.1 文件结构

```
tasks/do/Txxx_slug.do
tasks/do/Txxx_slug.md
tasks/do/meta/Txxx_slug.meta.json
```

### 6.2 meta.json 必须字段

```json
{
  "id": "T004",
  "slug": "merge_datasets",
  "title": "...",
  "module": "B",
  "level": "L1",
  "roles": ["main_dataset", "merge_table"],
  "parameters": [
    {"name": "key_vars", "type": "list[string]", "required": true},
    {"name": "keep_policy", "type": "enum", "values": ["match", "master", "using", "all"], "required": true}
  ],
  "dependencies": [{"pkg": "reghdfe", "source": "ssc"}],
  "outputs": [{"type": "table", "desc": "..."}],
  "tags": ["merge", "panel"]
}
```

### 6.3 索引文件

- `tasks/DO_LIBRARY_INDEX.json`（汇总所有 meta，供系统读取）
- `tasks/DO_LIBRARY_INDEX.sha256`（防篡改与发布一致性）

---

## 7. 执行步骤（不得跳）

### 7.1 先把标准定死（文件级门禁）

必须先完成（并纳入 CI）：

- `tasks/SS_DO_CONTRACT.md`（本文件）
- `tasks/DO_POLICY.md`（社区命令允许 + 白名单机制）
- `tasks/DO_QUALITY_UPGRADE_TASK.md`（L0/L1/L2 能力门槛，无行数门槛）
- `tasks/DO_LINT_RULES.py`（可执行门禁）
- `tests/test_do_contract.py`（CI 必杀：0 CRITICAL）

### 7.2 再做全量升级（旧模板全改：壳 + 内容本体）

执行顺序：

1. **先做硬契约注入**（头部声明 + 锚点协议 + `_rc` 处理）
2. **再按 §5 对 do 本体内容做升级**（输入验证 → 核心分析 → 导出 → 摘要）
3. **最后更新 md**（适用条件/参数/输出/解释口径/失败判据）

**强制要求**：
- 每个模板至少新增/补齐：**1 个可交付表** + **3 条 `SS_SUMMARY`** + **完整失败判据**
- 模板若属于 L1/L2：必须补齐对应的稳健性/诊断最小集（见 §5.2）
- 任何"跑通但不导出交付物"的模板一律判 FAIL

### 7.3 最后做扩张（新增模板）

- 按 `tasks/DO_LIBRARY_EXPANSION_PLAN.md` 模块补齐缺口
- 每新增 1 个模板：必须同时提供 `.do + .md + meta.json`，并进入 index
- 重复模板合并：同一任务目的只保留 1 个"主模板"，其余标记为 alias

---

## 8. 输出口径（供系统/审计）

模板输出必须满足：

- **锚点齐全且可解析**：TaskD 的 `domain/log_analyzer.py` 不得解析崩溃
- **产物可追踪**：每个输出文件对应 1 条 `SS_OUTPUT_FILE|...`
- **指标可量化**：至少 4 个 `SS_METRIC`（n_obs/n_missing/task_success/elapsed_sec）
- **摘要可拼装**：至少 3 条 `SS_SUMMARY`

---

## 9. 完成标准（DoD）

| 检查项 | 要求 |
|--------|------|
| 硬契约合规 | `tasks/do/` 下所有 `.do`：100% 合规 |
| Linter | 0 CRITICAL、0 HIGH |
| 索引完整 | `DO_LIBRARY_INDEX.json` 包含所有模板、无重复 id、alias 指向合法 |
| 依赖合规 | 模板声明的依赖 100% 在 `stata_dependencies.txt` 内 |
| 覆盖面 | 至少覆盖 `DO_LIBRARY_EXPANSION_PLAN.md` 的模块面 |
| CI 绿灯 | `python -m pytest -q` 全绿（不得只跑子集） |
