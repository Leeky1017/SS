## 1. Implementation
- [x] 1.1 Define `DraftPreviewOutputV2` schema in `src/domain/draft_preview_llm.py`
- [x] 1.2 Implement `build_draft_preview_prompt_v2()` (keep v1 prompt builder)
- [x] 1.3 Implement `parse_draft_preview_v2()` with v1 fallback + explicit parse error
- [x] 1.4 Wire draft preview to use v2 prompt + parsed fields

## 2. Testing
- [x] 2.1 Add `tests/unit/test_draft_preview_llm.py` (panel/DID/IV scenarios)
- [x] 2.2 Add edge-case tests (missing fields, invalid input)

## 3. Documentation
- [x] 3.1 Update `openspec/specs/ss-llm-brain/spec.md` to document draft preview schema v2
