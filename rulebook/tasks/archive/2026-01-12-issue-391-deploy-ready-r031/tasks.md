## 1. Implementation
- [ ] 1.1 Add `output_formats` request plumbing (API + job persistence)
- [ ] 1.2 Normalize do-template output kind mapping (`table`/`data`/`report`/`figure`/`log`)
- [ ] 1.3 Implement `OutputFormatterService` (csv/xlsx/dta/docx/pdf/log/do)
- [ ] 1.4 Worker runs Output Formatter post-run and indexes artifacts
- [ ] 1.5 Patch 9 docx template metas to declare `putdocx`

## 2. Testing
- [ ] 2.1 Unit tests for output_formats validation + defaults
- [ ] 2.2 Unit tests for Output Formatter artifact production + indexing
- [ ] 2.3 Run `ruff check .` and `pytest -q`

## 3. Documentation
- [ ] 3.1 Spec delta: Output Formatter + failure semantics
- [ ] 3.2 Evidence log: `openspec/_ops/task_runs/ISSUE-391.md`
