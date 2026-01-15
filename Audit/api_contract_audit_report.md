# SS API 契约审计报告
**审计日期**: 2026-01-15  
**审计范围**: 前后端 API 契约一致性（`/v1` + `/api/admin` + ops endpoints）

## 审计方法（对应任务 Step 1）
- OpenAPI 导出：本环境缺少 `fastapi` / `pydantic`，无法启动 `src/main.py` 并导出 `/openapi.json`（`ModuleNotFoundError`）。因此改为静态扫描：
  - 后端：`src/api/schemas.py`、`src/api/admin/schemas.py` + `src/api/**/*.py` 路由装饰器与 `response_model`/参数定义
  - 前端：`frontend/src/api/types.ts`、`frontend/src/api/client.ts`、`frontend/src/features/**` 实际使用

## 摘要
- 检查端点数量: 38
- 发现不一致数量: 5
- 严重级别分布: 🔴 高 1 个 / 🟡 中 2 个 / 🟢 低 2 个
---

## 不一致列表

### 1. [FreezePlanRequest 缺失 answers] `POST /v1/jobs/{job_id}/plan/freeze`
**严重级别**: 🟡 中  
**问题描述**: 后端支持并消费 `answers`；前端类型缺失该字段，无法按 `stage1_questions` 提交答案。  
**后端定义** (`src/api/schemas.py:52`):
```python
class FreezePlanRequest(BaseModel):
    notes: str | None = None
    answers: dict[str, JsonValue] = Field(default_factory=dict)
```
**前端定义** (`frontend/src/api/types.ts:50`):
```typescript
export type FreezePlanRequest = { notes: string | null }
```
**代码引用**: `src/api/jobs.py:177`、`src/domain/plan_freeze_gate.py:22`、`frontend/src/api/client.ts:153`  
**修复方案**:
- `frontend/src/api/types.ts:50` → `export type FreezePlanRequest = { notes?: string | null; answers?: Record<string, JsonValue> }`

---

### 2. [DraftPreview 联合判别依赖 status，但后端未固化值域] `GET /v1/jobs/{job_id}/draft/preview`
**严重级别**: 🟡 中  
**问题描述**: 前端用 `status === 'pending'` 判别 pending；后端 pending 的 `status` 类型为 `str`（默认值而非 Literal），ready 分支的 `status` 也未在 schema 层限制值域。  
**后端定义** (`src/api/schemas.py:183`):
```python
class DraftPreviewPendingResponse(BaseModel):
    status: str = "pending"
```
**前端定义** (`frontend/src/api/types.ts:116`、`frontend/src/features/step3/model.ts:4`):
```typescript
export type DraftPreviewPendingResponse = { status: 'pending'; /* ... */ }
return (resp as DraftPreviewPendingResponse).status === 'pending'
```
**代码引用**: `src/api/draft.py:22`、`src/api/draft.py:73`  
**修复方案**:
- 后端：将 pending/ready 的 `status` 收紧为 `Literal[...]` 并引入 discriminator；前端同步收敛 ready 的 status 值域

---

### 3. [GetJobResponse 后端字段前端缺失：selected_template_id] `GET /v1/jobs/{job_id}`
**严重级别**: 🟢 低  
**问题描述**: 后端返回 `selected_template_id`，前端 `GetJobResponse` 类型缺失。  
**后端定义** (`src/api/schemas.py:91`):
```python
class GetJobResponse(BaseModel):
    selected_template_id: str | None = None
```
**前端定义** (`frontend/src/api/types.ts:69`):
```typescript
export type GetJobResponse = { /* ... */ } // missing selected_template_id
```
**修复方案**: `frontend/src/api/types.ts:69` 增加 `selected_template_id: string | null`

---

### 4. [PlanStepResponse.params：JsonValue vs unknown] `GET /v1/jobs/{job_id}/plan`
**严重级别**: 🟢 低  
**问题描述**: 后端 `params` 为 JSON 值；前端使用 `unknown` 过宽，不利于契约同步与回归保护。  
**后端定义** (`src/api/schemas.py:37`):
```python
params: dict[str, JsonValue] = Field(default_factory=dict)
```
**前端定义** (`frontend/src/api/types.ts:35`):
```typescript
params: Record<string, unknown>
```
**修复方案**: `frontend/src/api/types.ts:35` 改为 `params: Record<string, JsonValue>`

---

### 5. [DraftPreviewResponse 透传 list(...) 缺少类型守卫，可能触发 500] `GET /v1/jobs/{job_id}/draft/preview`
**严重级别**: 🔴 高  
**问题描述**: `draft_dump.get(...)` 若返回非 list，`list(value)` 会产生错误形态并触发校验失败 → 500。  
**涉及代码** (`src/api/draft.py:78`):
```python
data_quality_warnings=list(draft_dump.get("data_quality_warnings", [])),
stage1_questions=list(draft_dump.get("stage1_questions", [])),
open_unknowns=list(draft_dump.get("open_unknowns", [])),
```
**修复方案**: `src/api/draft.py:67` 增加 `isinstance(value, list)` 守卫并记录结构化日志；或复用 `src/domain/draft_v1_contract.py:97` 的 `list_of_dicts()`

## 端点检查清单（全量，逐端点结论）

### Ops endpoints（不在 OpenAPI：`ops_router` 在 `src/main.py` 中 `include_in_schema=False`）

| ID | 方法 | 路径 | 后端实现 | 请求 | 响应 | 前端定义 | 结论 |
|---|---|---|---|---|---|---|---|
| OPS-01 | GET | `/health/live` | `src/api/health.py:16` | - | `HealthResponse` (`src/api/schemas.py:15`) | 无 | ✅ OK（前端未使用） |
| OPS-02 | GET | `/health/ready` | `src/api/health.py:25` | - | `HealthResponse` (`src/api/schemas.py:15`) / 503 同模型 | 无 | ✅ OK（前端未使用） |
| OPS-03 | GET | `/metrics` | `src/api/metrics.py:11` | - | `text/plain`（Prometheus） | 无 | ✅ OK（前端未使用） |

### Public `/v1` API（前端 `ApiClient` 默认 `baseUrl='/v1'`：`frontend/src/api/utils.ts`）

| ID | 方法 | 路径 | 后端实现 | 请求 | 响应 | 前端定义 | 结论 |
|---|---|---|---|---|---|---|---|
| V1-01 | POST | `/v1/task-codes/redeem` | `src/api/task_codes.py:12` | `TaskCodeRedeemRequest` (`src/api/schemas.py:209`) | `TaskCodeRedeemResponse` (`src/api/schemas.py:214`) | `ApiClient.redeemTaskCode` (`frontend/src/api/client.ts:50`) + `RedeemTaskCode*` (`frontend/src/api/types.ts:6`) | ✅ OK |
| V1-02 | POST | `/v1/jobs/{job_id}/inputs/upload` | `src/api/jobs.py:53` | `multipart/form-data`：`file`(repeat)+`role`(repeat?)+`filename`(repeat?) | `InputsUploadResponse` (`src/api/schemas.py:120`) | `ApiClient.uploadInputs` (`frontend/src/api/client.ts:60`) + `InputsUploadResponse` (`frontend/src/api/types.ts:88`) | ✅ OK |
| V1-03 | GET | `/v1/jobs/{job_id}/inputs/preview` | `src/api/jobs.py:93` | query：`rows`/`columns` | `InputsPreviewResponse` (`src/api/schemas.py:199`) | `ApiClient.previewInputsWithOptions` (`frontend/src/api/client.ts:91`) + `InputsPreviewResponse` (`frontend/src/api/types.ts:96`) | ✅ OK |
| V1-04 | POST | `/v1/jobs/{job_id}/inputs/primary/sheet` | `src/api/inputs_primary_sheet.py:20` | query：`sheet_name`(必填)+`rows`/`columns` | `InputsPreviewResponse` (`src/api/schemas.py:199`) | `ApiClient.selectPrimaryExcelSheet` (`frontend/src/api/client.ts:103`) | ✅ OK |
| V1-05 | GET | `/v1/jobs/{job_id}/draft/preview` | `src/api/draft.py:22` | query：`main_data_source_id`(可选) | `DraftPreviewResponse` 或 `DraftPreviewPendingResponse` (`src/api/schemas.py:164`/`:183`) | `ApiClient.previewDraft` (`frontend/src/api/client.ts:119`) + `DraftPreviewResponse` (`frontend/src/api/types.ts:171`) | ⚠️ 有不一致（见问题 2/5） |
| V1-06 | POST | `/v1/jobs/{job_id}/draft/patch` | `src/api/draft.py:98` | `DraftPatchRequest` (`src/api/schemas.py:189`) | `DraftPatchResponse` (`src/api/schemas.py:192`) | `ApiClient.patchDraft` (`frontend/src/api/client.ts:123`) + `DraftPatch*` (`frontend/src/api/types.ts:173`) | ✅ OK |
| V1-07 | POST | `/v1/jobs/{job_id}/confirm` | `src/api/jobs.py:148` | `ConfirmJobRequest` (`src/api/schemas.py:20`) | `ConfirmJobResponse` (`src/api/schemas.py:30`) | `ApiClient.confirmJob` (`frontend/src/api/client.ts:127`) + `ConfirmJob*` (`frontend/src/api/types.ts:18`) | ✅ OK |
| V1-08 | GET | `/v1/jobs/{job_id}` | `src/api/jobs.py:44` | - | `GetJobResponse` (`src/api/schemas.py:91`) | `ApiClient.getJob` (`frontend/src/api/client.ts:131`) + `GetJobResponse` (`frontend/src/api/types.ts:69`) | ⚠️ 有不一致（见问题 3） |
| V1-09 | GET | `/v1/jobs/{job_id}/artifacts` | `src/api/jobs.py:110` | - | `ArtifactsIndexResponse` (`src/api/schemas.py:109`) | `ApiClient.listArtifacts` (`frontend/src/api/client.ts:135`) + `ArtifactsIndexResponse` (`frontend/src/api/types.ts:86`) | ✅ OK |
| V1-10 | GET | `/v1/jobs/{job_id}/artifacts/{artifact_id:path}` | `src/api/jobs.py:121` | - | `application/octet-stream` | `ApiClient.downloadArtifact` (`frontend/src/api/client.ts:139`) | ✅ OK |
| V1-11 | POST | `/v1/jobs/{job_id}/run` | `src/api/jobs.py:137` | query：`output_formats`(可选) | `RunJobResponse` (`src/api/schemas.py:114`) | `ApiClient.runJob` (`frontend/src/api/client.ts:149`) | ✅ OK（前端未暴露 output_formats） |
| V1-12 | POST | `/v1/jobs/{job_id}/plan/freeze` | `src/api/jobs.py:177` | `FreezePlanRequest` (`src/api/schemas.py:52`) | `FreezePlanResponse` (`src/api/schemas.py:57`) | `ApiClient.freezePlan` (`frontend/src/api/client.ts:153`) + `FreezePlanRequest` (`frontend/src/api/types.ts:50`) | ⚠️ 有不一致（见问题 1） |
| V1-13 | GET | `/v1/jobs/{job_id}/plan` | `src/api/jobs.py:198` | - | `GetPlanResponse` (`src/api/schemas.py:62`) | `ApiClient.getPlan` (`frontend/src/api/client.ts:157`) | ⚠️ 有不一致（见问题 4） |
| V1-14 | POST | `/v1/jobs/{job_id}/inputs/bundle` | `src/api/inputs_bundle.py:30` | `CreateBundleRequest` (`src/api/schemas.py:228`) | `BundleResponse` (`src/api/schemas.py:236`) | 无 | ✅ OK（前端未实现/未使用） |
| V1-15 | GET | `/v1/jobs/{job_id}/inputs/bundle` | `src/api/inputs_bundle.py:53` | - | `BundleResponse` (`src/api/schemas.py:236`) | 无 | ✅ OK（前端未实现/未使用） |
| V1-16 | POST | `/v1/jobs/{job_id}/inputs/upload-sessions` | `src/api/inputs_upload_sessions.py:22` | `CreateUploadSessionRequest` (`src/api/schemas.py:242`) | `UploadSessionResponse` (`src/api/schemas.py:252`) | 无 | ✅ OK（前端未实现/未使用） |
| V1-17 | POST | `/v1/upload-sessions/{upload_session_id}/refresh-urls` | `src/api/inputs_upload_sessions.py:38` | `RefreshUploadUrlsRequest` (`src/api/schemas.py:262`) | `RefreshUploadUrlsResponse` (`src/api/schemas.py:265`) | 无 | ✅ OK（前端未实现/未使用） |
| V1-18 | POST | `/v1/upload-sessions/{upload_session_id}/finalize` | `src/api/inputs_upload_sessions.py:57` | `FinalizeUploadRequest` (`src/api/schemas.py:276`) | `FinalizeUploadResponse`（判别字段 `success`：`src/api/schemas.py:296`） | 无 | ✅ OK（前端未实现/未使用） |

### Admin `/api/admin` API（前端 `AdminApiClient` 默认 `baseUrl='/api/admin'`）

| ID | 方法 | 路径 | 后端实现 | 请求 | 响应 | 前端定义 | 结论 |
|---|---|---|---|---|---|---|---|
| ADM-01 | POST | `/api/admin/auth/login` | `src/api/admin/auth.py:22` | `AdminLoginRequest` (`src/api/admin/schemas.py:6`) | `AdminLoginResponse` (`src/api/admin/schemas.py:11`) | `AdminApiClient.login` (`frontend/src/features/admin/adminApi.ts:40`) + `adminApiTypes.ts:1` | ✅ OK |
| ADM-02 | POST | `/api/admin/auth/logout` | `src/api/admin/auth.py:35` | - | `AdminLogoutResponse` (`src/api/admin/schemas.py:16`) | `AdminApiClient.logout` (`frontend/src/features/admin/adminApi.ts:44`) | ✅ OK |
| ADM-03 | GET | `/api/admin/tenants` | `src/api/admin/tenants.py:13` | - | `AdminTenantListResponse` (`src/api/admin/schemas.py:89`) | `AdminApiClient.listTenants` (`frontend/src/features/admin/adminApi.ts:48`) | ✅ OK |
| ADM-04 | GET | `/api/admin/system/status` | `src/api/admin/system.py:30` | - | `AdminSystemStatusResponse` (`src/api/admin/schemas.py:118`) | `AdminApiClient.getSystemStatus` (`frontend/src/features/admin/adminApi.ts:52`) | ✅ OK |
| ADM-05 | GET | `/api/admin/tokens` | `src/api/admin/tokens.py:18` | - | `AdminTokenListResponse` (`src/api/admin/schemas.py:34`) | `AdminApiClient.listTokens` (`frontend/src/features/admin/adminApi.ts:56`) | ✅ OK |
| ADM-06 | POST | `/api/admin/tokens` | `src/api/admin/tokens.py:35` | `AdminTokenCreateRequest` (`src/api/admin/schemas.py:38`) | `AdminTokenCreateResponse` (`src/api/admin/schemas.py:42`) | `AdminApiClient.createToken` (`frontend/src/features/admin/adminApi.ts:60`) | ✅ OK |
| ADM-07 | POST | `/api/admin/tokens/{token_id}/revoke` | `src/api/admin/tokens.py:48` | - | `AdminTokenItem` (`src/api/admin/schemas.py:22`) | `AdminApiClient.revokeToken` (`frontend/src/features/admin/adminApi.ts:64`) | ✅ OK |
| ADM-08 | DELETE | `/api/admin/tokens/{token_id}` | `src/api/admin/tokens.py:63` | - | 204 | `AdminApiClient.deleteToken` (`frontend/src/features/admin/adminApi.ts:68`) | ✅ OK |
| ADM-09 | POST | `/api/admin/task-codes` | `src/api/admin/task_codes.py:19` | `AdminTaskCodeCreateRequest` (`src/api/admin/schemas.py:45`) | `AdminTaskCodeListResponse` (`src/api/admin/schemas.py:51`) | `AdminApiClient.createTaskCodes` (`frontend/src/features/admin/adminApi.ts:78`) | ✅ OK |
| ADM-10 | GET | `/api/admin/task-codes` | `src/api/admin/task_codes.py:35` | query：`tenant_id`/`status` | `AdminTaskCodeListResponse` | `AdminApiClient.listTaskCodes` (`frontend/src/features/admin/adminApi.ts:82`) | ✅ OK |
| ADM-11 | POST | `/api/admin/task-codes/{code_id}/revoke` | `src/api/admin/task_codes.py:51` | - | `AdminTaskCodeItem` (`src/api/admin/schemas.py:55`) | `AdminApiClient.revokeTaskCode` (`frontend/src/features/admin/adminApi.ts:95`) | ✅ OK |
| ADM-12 | DELETE | `/api/admin/task-codes/{code_id}` | `src/api/admin/task_codes.py:61` | - | 204 | `AdminApiClient.deleteTaskCode` (`frontend/src/features/admin/adminApi.ts:99`) | ✅ OK |
| ADM-13 | GET | `/api/admin/jobs` | `src/api/admin/jobs.py:30` | query：`tenant_id`/`status` | `AdminJobListResponse` (`src/api/admin/schemas.py:69`) | `AdminApiClient.listJobs` (`frontend/src/features/admin/adminApi.ts:109`) | ✅ OK |
| ADM-14 | GET | `/api/admin/jobs/{job_id}` | `src/api/admin/jobs.py:51` | header：`X-SS-Tenant-ID` | `AdminJobDetailResponse` (`src/api/admin/schemas.py:92`) | `AdminApiClient.getJobDetail` (`frontend/src/features/admin/adminApi.ts:120`) | ✅ OK |
| ADM-15 | POST | `/api/admin/jobs/{job_id}/retry` | `src/api/admin/jobs.py:93` | header：`X-SS-Tenant-ID` | `AdminJobRetryResponse` (`src/api/admin/schemas.py:112`) | `AdminApiClient.retryJob` (`frontend/src/features/admin/adminApi.ts:124`) | ✅ OK |
| ADM-16 | GET | `/api/admin/jobs/{job_id}/artifacts` | `src/api/admin/jobs.py:108` | header：`X-SS-Tenant-ID` | `AdminArtifactItem[]` (`src/api/admin/schemas.py:73`) | 无（前端通过 job detail 的 `artifacts` 列表展示） | ✅ OK（前端未直连） |
| ADM-17 | GET | `/api/admin/jobs/{job_id}/artifacts/{artifact_id:path}` | `src/api/admin/jobs.py:120` | header：`X-SS-Tenant-ID` | `application/octet-stream` | `AdminApiClient.downloadJobArtifact` (`frontend/src/features/admin/adminApi.ts:128`) | ✅ OK |

---

## 隐式契约风险

### 1. stage1_questions / open_unknowns 结构来自 v1_contract_fields（domain extra fields），长期存在漂移风险
**问题描述**:
- `Draft` 领域模型是 `extra="allow"`（`src/domain/models.py:130`），`stage1_questions`/`open_unknowns` 并非显式字段，而是通过 `DraftService._enrich_draft` 将 `v1_contract_fields()` 的 dict 合并进去。
- 这使得“API 返回结构”与“领域模型字段”之间缺少编译期约束，未来若扩展 stage1 问题或 unknowns 字段，容易出现“domain 变了但 API schema / 前端 types 没同步”的漂移。

**现状对齐结论（Step 3 要求）**:
- 当前 `v1_contract_fields()` 填充的 `stage1_questions` 结构与 API schema 一致：
  - `src/domain/draft_v1_contract.py:59`
  ```python
  stage1_questions = [{
      "question_id": "analysis_goal",
      "question_text": "What is your analysis goal?",
      "question_type": "single_choice",
      "options": [{"option_id": "descriptive", "label": "Descriptive", "value": "descriptive"}],
      "priority": 1,
  }]
  ```
  - `src/api/schemas.py:144`
  ```python
  class DraftStage1Option(BaseModel):
      option_id: str
      label: str
      value: JsonScalar

  class DraftStage1Question(BaseModel):
      question_id: str
      question_text: str
      question_type: str
      options: list[DraftStage1Option] = Field(default_factory=list)
      priority: int = 0
  ```

**涉及文件**:
- `src/domain/draft_v1_contract.py:59`（构造 stage1_questions 与 open_unknowns）
- `src/api/schemas.py:149`（`DraftStage1Question`/`DraftOpenUnknown` 期望结构）
- `frontend/src/features/step3/model.ts:26`（前端会依赖 `question_id` 与 `field` 进行阻塞判断）

**修复方案**:
1. 将 `stage1_questions`/`open_unknowns` 从 Draft 的 extra dict 提升为显式 Pydantic 字段（domain 层），并在生成/持久化时做 schema 校验。
2. 或至少在 API 层（`src/api/draft.py`）对透传数据做类型守卫 + 结构化日志（见问题 5）。

---

## 未使用字段清单（Step 4）

| 后端字段 | 所属 Schema | 前端是否存在 | 处理建议 |
|---|---|---|---|
| `selected_template_id` | `GetJobResponse` (`src/api/schemas.py:91`) | ❌ `frontend/src/api/types.ts:69` | 前端类型补齐；如需要展示则在 `frontend/src/features/status/Status.tsx` 增加 UI |

## 前端期望但后端未提供的字段（Step 5）
- 未发现（以 `frontend/src/api/types.ts` + `frontend/src/features/**` 实际使用为准）。

---

## 反向验证：遍历 `frontend/src/api/client.ts` 的每个 API 方法（补充要求）
- `redeemTaskCode` → V1-01（`frontend/src/api/client.ts:50`）
- `uploadInputs` → V1-02（`frontend/src/api/client.ts:60`）
- `previewInputs` → V1-03（`frontend/src/api/client.ts:87`）
- `previewInputsWithOptions` → V1-03（`frontend/src/api/client.ts:91`）
- `selectPrimaryExcelSheet` → V1-04（`frontend/src/api/client.ts:103`）
- `previewDraft` → V1-05（`frontend/src/api/client.ts:119`）
- `patchDraft` → V1-06（`frontend/src/api/client.ts:123`）
- `confirmJob` → V1-07（`frontend/src/api/client.ts:127`）
- `getJob` → V1-08（`frontend/src/api/client.ts:131`）
- `listArtifacts` → V1-09（`frontend/src/api/client.ts:135`）
- `downloadArtifact` → V1-10（`frontend/src/api/client.ts:139`）
- `runJob` → V1-11（`frontend/src/api/client.ts:149`）
- `freezePlan` → V1-12（`frontend/src/api/client.ts:153`）
- `getPlan` → V1-13（`frontend/src/api/client.ts:157`）

---

## 后续建议
1. 在 CI 增加 OpenAPI 导出产物（或 snapshot test），并用生成工具同步 `types.ts`（避免手工漂移）。
2. 对 `DraftPreviewResponse` 引入判别联合（discriminator），并将 `status` 值域收敛到固定集合，降低前端误判风险。
3. 对“未被前端使用”的 `/v1` 端点（bundle/upload-sessions）补齐前端 client/types 或明确标记为“仅后端内部使用/未来规划”，避免长期悬空。

---

## 验收标准
1. 报告覆盖所有 API 端点（不遗漏）
2. 每个不一致问题都有明确的**问题描述 + 代码引用 + 修复方案**
3. 修复方案可直接执行（包含具体文件路径和行号）
4. 报告成功保存到指定路径：`Audit/api_contract_audit_report.md`

---

## 注意事项
1. 本次审计未修改任何代码，仅产出审计报告
2. 全量端点已在“端点检查清单（全量）”列出，且 `client.ts` 已反向验证覆盖
3. 优先关注实际会被前端调用的端点（见 V1-01 ~ V1-13 / ADM-01 ~ ADM-17 的前端映射列）
4. `draft_dump.get(...)` 的透传与 `list(...)` 缺少类型守卫已作为高风险项单列（见问题 5）
