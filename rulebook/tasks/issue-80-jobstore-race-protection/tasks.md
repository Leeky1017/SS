## 1. Implementation
- [ ] 1.1 Add a persisted monotonic job `version` field (schema + migrations)
- [ ] 1.2 Add optimistic concurrency checks to `JobStore.save()` (structured conflict error)
- [ ] 1.3 Ensure domain state machine remains the source of truth for transitions

## 2. Testing
- [ ] 2.1 Add a conflict regression test (two writers from same base version)
- [ ] 2.2 Update/extend migration tests for the new current schema version

## 3. Documentation
- [ ] 3.1 Update job contract docs to define `version` and current supported schema versions
- [ ] 3.2 Record run evidence: ruff, pytest, openspec validate

