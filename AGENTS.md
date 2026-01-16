# SS — Agent Instructions

本仓库目标：构建一个以 **LLM 为“大脑”** 的 Stata 实证分析自动化系统（可维护性优先）。

## 文档权威（必须遵守）

- 项目权威文档（开发圣旨）在 `openspec/specs/`，尤其是 `openspec/specs/ss-constitution/spec.md`。
- `docs/` 仅保留指针/入口，避免形成第二套文档体系。

## API 契约优先（强制护栏）

- `frontend/src/api/types.ts` 与 `frontend/src/features/admin/adminApiTypes.ts` 为**自动生成**文件，禁止手动编辑。
- 任何 API 变更必须遵循顺序：**后端 schema/route 先改 → 生成前端 types → 再改前端调用/页面**。
- 禁止反向流程：**前端先改 types、后端再跟**（会造成漂移；CI 会失败）。
- 本地生成与校验：
  - 生成：`scripts/contract_sync.sh generate`
  - 校验：`scripts/contract_sync.sh check`

## 代码原则（硬约束）

- YAGNI：不需要的不写；先把最小链路跑通再扩展。
- 尺寸上限：
  - 每个函数 `< 50` 行
  - 每个文件 `< 300` 行（超过必须拆分）
- 显式优于隐式：
  - 依赖必须显式注入（FastAPI `Depends` / 构造函数参数）
  - 配置从 `src/config.py` 加载，不要到处读环境变量
- 禁止动态代理/隐式转发：
  - 禁止 `__getattr__` 代理/ModuleAttrProxy
  - 禁止用“延迟 import 模块”绕循环依赖；要重组依赖或做依赖注入

## 异常与防御性编程（硬约束）

- 禁止 `except Exception: pass` 或 `except: pass`。
- 只捕获**具体异常类型**，并记录结构化日志（事件码 + 上下文）。
- 默认值必须显式：`data.get("key", "")`；不要用 `or ""` 破坏 `0/False/[]` 语义。

## 后端/通用规范补充（P2a）

- 错误响应：API 失败必须返回 `{"error_code":"...","message":"..."}`；禁止向用户暴露堆栈/内部异常信息（见 `openspec/specs/ss-api-surface/spec.md`）。
- 错误码：统一大写下划线 + 领域前缀（如 `INPUT_*`/`JOB_*`/`LLM_*`/`STATA_*`）；新增/变更必须同步 `ERROR_CODES.md`（内部索引）。
- 日志：统一结构化 JSON（`event=SS_...` + `extra` 上下文）；必须覆盖 API 请求、状态变更、LLM 调用、Stata 执行（见 `openspec/specs/ss-observability/README.md`）。
- 状态机：Job 状态流转必须走 domain 状态机；变更需校验前置条件；并发写用 job `version` 乐观锁（见 `openspec/specs/ss-state-machine/spec.md` 与 `openspec/specs/ss-job-store/spec.md`）。
- 测试（边界/E2E）：新增边界行为优先补 `tests/e2e/`，断言稳定 `error_code`/状态流转（见 `openspec/specs/ss-testing-strategy/README.md`）。

## 分层边界（保持链路最短）

- `src/api/`：HTTP 薄层（参数校验/响应组装），不要写业务。
- `src/domain/`：业务逻辑（纯业务 + 显式依赖），不要依赖 FastAPI。
- `src/infra/`：持久化/外部系统适配（job store、LLM provider、Stata runner 等）。
- `src/utils/`：极少量通用工具（避免工具泛滥）。

## 交付流程（必须遵守）

本仓库沿用 `$openspec-rulebook-github-delivery`：

- GitHub 是并发与交付唯一入口：**Issue → Branch → PR → Checks → Auto-merge**。
- Issue 号 `N` 是任务唯一 ID：
  - 分支名：`task/<N>-<slug>`
  - 每个 commit message 必须包含 `(#N)`
  - PR body 必须包含 `Closes #N`
  - 必须新增/更新：`openspec/_ops/task_runs/ISSUE-N.md`
- 每个 Issue 必须使用 worktree 隔离开发（控制面 `main` + 工作面 worktree）：
  - 在控制面执行：`scripts/agent_controlplane_sync.sh`
  - 创建 worktree：`scripts/agent_worktree_setup.sh "$N" "$SLUG"`
  - 进入工作面：`cd ".worktrees/issue-${N}-${SLUG}"`
- 当 PR **已合并** 且控制面 `main` **已同步到** `origin/main` 后，必须清理 worktree（不遗留）：
  - 在控制面执行：`scripts/agent_worktree_cleanup.sh "$N" "$SLUG"`
- PR 需要通过 required checks：`ci` / `openspec-log-guard` / `merge-serial`。
- PR 前（或启用 auto-merge 前）必须运行：`scripts/agent_pr_preflight.sh`（roadmap 依赖 + open PR 文件重叠预警）。
- Auto-merge 必须“验证已合并”：即使 checks 全绿也要确认 PR 状态为 `MERGED`（`mergedAt != null`）；若被 `reviewDecision=REVIEW_REQUIRED` 阻断，agent 必须尝试 `gh pr merge --admin`（要求仓库允许 admin bypass）以保持全流程无人值守，并把 blocker+处置写入 run log，禁止不了了之。
- Task card 收口（强制，禁止“做完就不管”）：
  - 如果该 Issue 有对应 task card（例如 `openspec/specs/**/task_cards/*.md` 中引用了 `Issue: #N`），PR 合并后必须回填：
    - Acceptance checklist 全部打勾（`[x]`）
    - 增加 `## Completion`：PR 链接 + 2-5 条精要完成情况 + `openspec/_ops/task_runs/ISSUE-N.md`
  - 同步把 PR 链接回填到 run log：`openspec/_ops/task_runs/ISSUE-N.md` 的 `PR:` 字段

## 本地验证

- `ruff check .`
- `pytest -q`

## 测试编写原则

### 测试的三个目标

1. **保护回归**：改了 A，测试告诉你 B 是否受影响
2. **文档化行为**：测试是可执行的规格说明书
3. **设计反馈**：测试难写 = 代码设计有问题

### 命名规范

`test_<被测函数><场景><期望结果>`

示例：

- `test_load_fingerprint_with_valid_dict_returns_fingerprint()`
- `test_load_fingerprint_with_invalid_input_returns_none()`
- `test_draft_service_when_llm_fails_raises_draft_generation_error()`

### 测试结构（AAA 模式）

```python
def test_example():
    # Arrange（准备）
    input_data = {"key": "value"}
    service = DraftService(llm_client=mock_llm)

    # Act（执行）
    result = service.generate_draft(input_data)

    # Assert（断言）
    assert result.status == "success"
    assert result.draft_id is not None
```

### 什么该测 / 什么不该测

| ✅ 该测 | ❌ 不该测 |
| --- | --- |
| 业务逻辑分支 | 第三方库的内部行为 |
| 边界条件（空、None、极值） | 简单的 getter/setter |
| 错误处理路径 | FastAPI 框架本身 |
| 状态转换（状态机） | 纯粹的类型转换 |

### Mock 原则

- 只 mock 边界：外部服务（LLM、数据库、文件系统），不 mock 内部模块
- mock 最少层级：如果测 Service，mock 它直接依赖的 Client，不要 mock Client 内部的 httpx
- 优先用 fake 而不是 mock：

```python
# ❌ 过度 mock
mock_llm.generate.return_value = {"draft": "..."}

# ✅ 用 fake 实现
class FakeLLMClient:
    def generate(self, prompt: str) -> dict:
        return {"draft": "fake draft for: " + prompt[:20]}
```

### 测试覆盖率指导

- 目标：核心业务逻辑 > 80%，整体 > 60%
- 不追求 100%：覆盖率超过 80% 后收益递减
- 关注分支覆盖：不只是行覆盖，要确保 if/else 都走过

### 测试是设计反馈

如果遇到以下情况，先重构代码再写测试：

| 测试难写的症状 | 代码问题 | 解决方案 |
| --- | --- | --- |
| 要 mock 5+ 个依赖 | 函数职责过多 | 拆分函数 |
| 无法构造输入 | 函数依赖全局状态 | 用依赖注入 |
| 只能写集成测试 | 模块边界不清 | 抽出接口层 |
| 改一行业务，改 10 个测试 | 测试和实现耦合 | 测试行为，不测实现 |

### 测试文件组织

```text
tests/
├── conftest.py              # 共享 fixtures
├── unit/                    # 单元测试（不依赖外部）
│   ├── test_draft_service.py
│   └── test_job_service.py
├── integration/             # 集成测试（需要真实依赖或 fake）
│   ├── test_api_draft.py
│   └── test_api_jobs.py
└── fixtures/                # 测试数据
    └── sample_job.json
```

### 运行测试

```bash
# 运行所有测试
pytest
# 运行单元测试
pytest tests/unit/
# 运行并显示覆盖率
pytest --cov=src --cov-report=html
# 只运行失败的测试
pytest --lf
```
