## 1. Implementation
- [ ] 1.1 Delete legacy UX audit spec folder (`openspec/specs/ss-frontend-ux-audit/`)
- [ ] 1.2 Create `openspec/specs/ss-ux-remediation/` (spec + design docs)
- [ ] 1.3 Create task cards (FE-001..FE-064, BE-001..BE-009, E2E-001)
- [ ] 1.4 Confirm `find openspec/specs -name "*ux-audit*"` has no results

## 2. Testing
- [ ] 2.1 `openspec validate --specs --strict --no-interactive`
- [ ] 2.2 `ruff check .`
- [ ] 2.3 `pytest -q`

## 3. Documentation
- [ ] 3.1 Update any in-repo references to the removed spec path
