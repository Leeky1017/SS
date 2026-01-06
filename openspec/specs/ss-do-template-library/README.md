# SS Do Template Library — Index

SS 的核心价值是“可复现的实证分析流水线”。仅靠 LLM 即兴生成 do-file 很难保证可维护性与可审计性，因此 **do 模板库是长期必需资产**。

本目录回答：如何复用 legacy `stata_service` 根目录下的 `tasks/`（300+ do 模板 + meta.json + index），并避免把它误当成 OpenSpec/Rulebook 的“任务系统”。

## 定位：数据资产，不是任务系统

- legacy `stata_service/tasks/` 在 SS 中的角色：**Do 模板库（capability library）**。
- 它不是：
  - `openspec/tasks/`（OpenSpec 兼容占位，禁止写任务正文）
  - `rulebook/tasks/`（执行清单）
- SS 对模板库的期望：提供“可选择的分析能力单元”，并能在 runner 中被可靠执行与归档。

## 推荐落盘方式（避免命名冲突）

为避免与 `openspec/tasks` / `rulebook/tasks` 混淆，SS 内建议使用以下之一：

- `assets/stata_do_library/`（推荐：明确是静态资产）
- `vendor/stata_do_library/`（如果强调 vendored 依赖）
- 以配置方式引用外部路径（推荐用于本地开发/快速迭代）

不建议在 SS 根目录继续叫 `tasks/`。

## 当前实现（Issue #36）

- Vendored 模板库路径：`assets/stata_do_library/`（从 legacy `stata_service/tasks/` 全量复制）
- 默认配置：
  - `SS_DO_TEMPLATE_LIBRARY_DIR=./assets/stata_do_library`
- MVP 执行链路（CLI）：
  - `python3 -m src.cli run-template --template-id <Txx> --param <NAME=VALUE> ...`

### WSL + Windows Stata（重要）

若通过 WSL 调用 Windows 的 `StataMP-64.exe`，建议把 `SS_JOBS_DIR` 放到 `/mnt/c/...` 下，避免 Windows 进程无法访问 WSL 的 Linux 文件系统路径。

示例：

```bash
SS_JOBS_DIR=/mnt/c/ss_jobs \
python3 -m src.cli run-template \
  --template-id T01 \
  --param __NUMERIC_VARS__="y x1" \
  --param __ID_VAR__=id \
  --param __TIME_VAR__=time \
  --sample-data
```

## 接入策略：MVP 子集 → 全量库（分阶段）

- MVP（先跑通最小链路）：
  - 只接入 3–5 个模板（低依赖、可稳定跑通）
  - 支持：选模板 → 填参 → 生成 do-file → Runner 执行 → artifacts 落盘
  - 为模板库写“加载与替换”的单元测试（不依赖真实 Stata）
- 扩展阶段：
  - 再逐步接入更多模板与更高阶统计能力（空间计量/稳健性等）
  - 引入更严格的模板库校验（meta schema、输出声明、依赖声明一致性）

对应实现任务：#36（ARCH-T053）。

## 模板契约（SS 侧需要明确的最小合同）

SS 侧应把模板当成“可版本化的外部输入”，并强制最小合同：

- 文件组成（推荐沿用 legacy 习惯）：
  - `do/<template>.do`
  - `do/meta/<template>.meta.json`
  - `DO_LIBRARY_INDEX.json`（或 SS 侧生成的 index）
- 稳定标识：
  - `template_id`（如 `TR02`）作为选择与追溯主键
  - `version` 用于审计与回放（落盘到 artifacts）
- 参数与占位符：
  - 模板使用占位符（如 `__DEPVAR__`）声明可替换参数
  - SS 负责做 **确定性** 替换（同输入 → 同 do-file 文本）
  - 禁止在替换阶段引入隐式执行（例如把参数拼接成可执行表达式）
- 输入与输出：
  - `meta.json` 必须声明 inputs/outputs（最少包含 log 输出）
  - Runner 必须在 job/run 工作目录内执行，并把 outputs 归档到 artifacts

## 安全与审计边界（必须）

- do-file 执行工作目录：限制在 `jobs/<job_id>/runs/<run_id>/`
- 路径规则：
  - 输入使用相对路径（指向 job inputs）
  - 禁止跨目录写入（`..`、绝对路径、符号链接逃逸）
- 运行证据：
  - do-file 原文、meta.json、替换后的参数表、stdout/stderr、log 都必须归档

## 复用 legacy 的边界（允许 / 禁止）

允许：
- 复用 do 模板与 meta/index 作为“能力库”
- 抽取它们的契约/边界条件，转写为 SS 的 OpenSpec 与测试向量

禁止：
- 直接复用 legacy 的应用架构、路由组织、隐式依赖与动态代理手法
- 把模板库当作 SS 的“任务调度/任务系统”
