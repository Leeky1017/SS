## 1. Implementation
- [ ] 1.1 Serve API under `/v1` while keeping legacy routes available
- [ ] 1.2 Add deprecation headers (`Deprecation`, `Sunset`) for legacy routes
- [ ] 1.3 Update OpenSpec to document versioning + deprecation policy

## 2. Testing
- [ ] 2.1 Update API tests to use `/v1` as the primary surface
- [ ] 2.2 Add regression tests for legacy coexistence + deprecation headers

## 3. Documentation
- [ ] 3.1 Record run evidence: `ruff`, `pytest`, `openspec validate`
- [ ] 3.2 Ship via PR (preflight + required checks + auto-merge)
