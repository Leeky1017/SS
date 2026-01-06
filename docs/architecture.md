# SS 新架构（骨架）— Architecture Decisions

目标：以 **可维护性优先** 的方式重建最小核心链路，保持“从 HTTP 到 LLM 到响应”的最短路径，同时通过明确分层避免旧仓库的全局耦合与动态代理。

---

## 分层与边界

- `src/api/`（HTTP 层，薄层）
  - 只做：参数解析/校验 → 调用 service → 返回响应模型
  - 不做：文件 IO、业务状态机、LLM 调用细节
- `src/domain/`（业务逻辑层）
  - 只依赖：domain models + 显式注入的依赖（store/llm/scheduler）
  - 产出：明确的领域对象（`Job`/`Draft`）
- `src/infra/`（基础设施层）
  - 负责：job.json 的原子读写、统一异常类型
  - 不向上泄漏实现细节（例如临时文件、路径组织）
- `src/utils/`（通用工具）
  - 仅保留 `utc_now()` 等极少量公共能力，避免工具泛滥

---

## 关键设计决策

### 1) 取消动态代理与隐式全局

旧仓库为绕循环导入引入 `_ap()`/`__getattr__` 代理，导致签名不可知、依赖不透明、测试必须 monkeypatch 全局对象。

新架构：依赖显式注入（FastAPI `Depends` + `src/api/deps.py`），对象边界清晰，可替换、可测试。

### 2) 单一持久化入口：JobStore

`src/infra/job_store.py` 统一 `job.json` 的读写，并使用 `os.replace` 做原子写入，避免散落的“到处 open/write”。

### 3) LLM 单入口：LLMClient

`src/domain/llm_client.py` 定义明确接口，当前用 `StubLLMClient` 保证链路可跑；后续替换为真实 provider 不影响上层业务代码。

### 4) 错误处理：结构化 + 可观测

所有可预期失败通过 `src/infra/exceptions.py` 的 `SSError` 派生类表达（`error_code`/`status_code`/`message`），由 FastAPI 统一 handler 转换为 JSON 响应。

---

## 最小链路（Phase 2）

- Create Job：`POST /jobs` → 生成 `job_id` → 写入 `jobs/<job_id>/job.json`
- Draft Preview：`GET /jobs/{id}/draft/preview` → 读取 job → 调用 `LLMClient` → 写回草案 → 返回草案
- Confirm Job：`POST /jobs/{id}/confirm` → 更新状态为 `queued` → 记录 `scheduled_at`（预留 scheduler 接口）

---

## 主脑规划（Master Brain）

更详细的总体规划与路线图见：`docs/brain/README.md`。
