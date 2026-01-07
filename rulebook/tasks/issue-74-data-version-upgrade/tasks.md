## 1. Implementation
- [ ] 1.1 Define job.json schema version constants and policy surface
- [ ] 1.2 Add explicit `JobStore.load()` migration (v1 → v2) with structured logs + persistence
- [ ] 1.3 Ensure new jobs are written as current schema (v2)

## 2. Testing
- [ ] 2.1 Add a migration test (v1 job.json → v2) and assert migration log fields
- [ ] 2.2 Keep/extend an unsupported-version rejection test

## 3. Documentation
- [ ] 3.1 Update job contract docs with the schema versioning policy + current version
- [ ] 3.2 Record run evidence: ruff, pytest, openspec validate
