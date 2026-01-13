## 1. Implementation
- [x] 1.1 Frontend: primary/aux upload areas + state
- [x] 1.2 Frontend: Excel sheet dropdown + refresh preview
- [x] 1.3 Frontend: preview table UX (sticky first col, better scroll, stats)
- [x] 1.4 Backend: preview returns sheet list + row/col counts + normalized headers
- [x] 1.5 Backend: persist selected sheet into `inputs/manifest.json` and use it in execution

## 2. Testing
- [x] 2.1 Add tests for Excel sheet selection + do-file generation uses sheet
- [x] 2.2 Run `ruff check .` and `pytest -q`

## 3. Documentation
- [x] 3.1 Update OpenSpec doc (`ss-inputs-upload-sessions`) for new manifest/preview fields
