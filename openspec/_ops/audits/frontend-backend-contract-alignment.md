# Frontend ↔ Backend contract alignment audit

Scope:
- Backend API schemas: `src/api/schemas.py`
- Backend domain contracts/models: `src/domain/draft_v1_contract.py`, `src/domain/models.py`
- Frontend TypeScript API types: `frontend/src/api/types.ts`
- Frontend Step3 consumers: `frontend/src/features/step3/*.tsx`
- Legacy Desktop Pro consumers: `assets/desktop_pro_*.js`, `index.html`

Single source of truth:
- `src/api/schemas.py` (and the shapes it enforces at runtime via FastAPI response models)

## Findings

Note: “Backend actual format” vs “Frontend expected format” describes the mismatch observed during audit; `Status` reflects whether it has been aligned in this workstream.

| ID | Status | Field path | Backend actual format | Frontend expected format | Evidence (file:line) |
| --- | --- | --- | --- | --- | --- |
| F-001 | Fixed | `DraftPreviewResponse.stage1_questions[].options[]` | `string[]` | `{ option_id: string, label: string, value: string \\| number \\| boolean \\| null }[]` | Backend: `src/api/schemas.py:153`, `src/domain/draft_v1_contract.py:68`, `src/api/draft.py:63` · Frontend: `frontend/src/api/types.ts:130`, `frontend/src/features/step3/panelsConfirm.tsx:114` · Desktop Pro: `assets/desktop_pro_api.js:43`, `assets/desktop_pro_blueprint_render.js:181` |
| F-002 | Fixed | `DraftPreviewPendingResponse.message` | `string` (required) | `string \\| undefined` | Backend: `src/api/schemas.py:185` · Frontend: `frontend/src/api/types.ts:118` |
| F-003 | Fixed | `DraftPreviewPendingResponse.retry_until` | `string` (required, RFC3339) | `string \\| undefined` | Backend: `src/api/schemas.py:187` · Frontend: `frontend/src/api/types.ts:120` |
| F-004 | Fixed | `DraftPreviewReadyResponse.decision` | `string` (required) | `"auto_freeze" \\| "require_confirm" \\| "require_confirm_with_downgrade" \\| undefined` | Backend: `src/api/schemas.py:168` · Frontend: `frontend/src/api/types.ts:157` |
| F-005 | Fixed | `DraftPreviewReadyResponse.risk_score` | `number` (required) | `number \\| undefined` | Backend: `src/api/schemas.py:169` · Frontend: `frontend/src/api/types.ts:158` |
| F-006 | Fixed | `DraftPreviewReadyResponse.column_candidates` | `string[]` (required; may be empty) | `string[] \\| undefined` | Backend: `src/api/schemas.py:174` · Frontend: `frontend/src/api/types.ts:162` |
| F-007 | Fixed | `DraftPreviewReadyResponse.data_quality_warnings` | `{type,severity,message,suggestion?}[]` (required; may be empty) | `{type,severity,message,suggestion?}[] \\| undefined` | Backend: `src/api/schemas.py:175` · Frontend: `frontend/src/api/types.ts:165` |
| F-007a | Fixed | `DraftDataQualityWarning.suggestion` | `string \\| null` | `string \\| undefined` | Backend: `src/api/schemas.py:142` · Frontend: `frontend/src/api/types.ts:127` · Consumer handles null: `frontend/src/features/step3/panelsBase.tsx:107` |
| F-008 | Fixed | `DraftPreviewReadyResponse.stage1_questions` | `{question_id,question_text,question_type,options,priority}[]` (required; may be empty) | `{...}[] \\| undefined` | Backend: `src/api/schemas.py:176` · Frontend: `frontend/src/api/types.ts:166` |
| F-009 | Fixed | `DraftPreviewReadyResponse.open_unknowns` | `{field,description,impact,blocking?,candidates?}[]` (required; may be empty) | `{...}[] \\| undefined` | Backend: `src/api/schemas.py:177` · Frontend: `frontend/src/api/types.ts:167` |
| F-009a | Fixed | `DraftOpenUnknown.blocking` | `boolean \\| null` | `boolean \\| undefined` | Backend: `src/api/schemas.py:160` · Frontend: `frontend/src/api/types.ts:148` |
| F-010 | Fixed | `DraftPatchRequest.field_updates` | `Record<string, JsonValue>` | `Record<string, string>` | Backend: `src/api/schemas.py:190` · Frontend: `frontend/src/api/types.ts:173` · Consumer: `frontend/src/features/step3/Step3.tsx:111` |
| F-011 | Fixed | `DraftPatchResponse.draft_preview` | `Record<string, JsonValue>` | `Partial<DraftPreviewReadyResponse> \\| undefined` | Backend: `src/api/schemas.py:197` · Frontend: `frontend/src/api/types.ts:180` |
| F-012 | Fixed | `ConfirmJobRequest.answers` | `object` (backend accepts; defaults to `{}`) | `Record<string, string[]> \\| undefined` (React Step3 omits if no stage1 questions) | Backend: `src/api/schemas.py:25` · Frontend: `frontend/src/api/types.ts:23`, `frontend/src/features/step3/Step3.tsx:133` · Desktop Pro always sends: `assets/desktop_pro_blueprint_flow.js:164` |
| F-013 | Fixed | `ConfirmJobRequest.expert_suggestions_feedback` | `object` (backend accepts; defaults to `{}`) | `Record<string, unknown> \\| undefined` (React Step3 omits) | Backend: `src/api/schemas.py:27` · Frontend: `frontend/src/api/types.ts:25`, `frontend/src/features/step3/Step3.tsx:140` |
| F-014 | Fixed | `ConfirmJobResponse.message` | `string` | missing | Backend: `src/api/schemas.py:34` · Frontend: `frontend/src/api/types.ts:32` |
| F-015 | Fixed | `TaskCodeRedeemResponse.expires_at` | `string` | missing | Backend: `src/api/schemas.py:217` · Frontend: `frontend/src/api/types.ts:14` |
| F-016 | Fixed | `TaskCodeRedeemResponse.is_idempotent` | `boolean` | missing | Backend: `src/api/schemas.py:218` · Frontend: `frontend/src/api/types.ts:15` |
| F-017 | Fixed | `InputsPreviewResponse.column_count` | `number \\| null` (always present) | `number \\| null \\| undefined` | Backend: `src/api/schemas.py:202` · Frontend: `frontend/src/api/types.ts:99` |
| F-018 | Fixed | `InputsPreviewResponse.sheet_names` | `string[]` (always present) | `string[] \\| undefined` | Backend: `src/api/schemas.py:203` · Frontend: `frontend/src/api/types.ts:100` |
| F-019 | Fixed | `InputsPreviewResponse.selected_sheet` | `string \\| null` (always present) | `string \\| null \\| undefined` | Backend: `src/api/schemas.py:204` · Frontend: `frontend/src/api/types.ts:101` |
| F-020 | Fixed | `InputsPreviewResponse.header_row` | `boolean \\| null` (always present) | `boolean \\| null \\| undefined` | Backend: `src/api/schemas.py:205` · Frontend: `frontend/src/api/types.ts:102` |
