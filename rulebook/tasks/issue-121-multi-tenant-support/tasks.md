## 1. Spec-first
- [ ] 1.1 Define tenant model + request context
- [ ] 1.2 Document compatibility / migration plan

## 2. Implementation
- [ ] 2.1 Add tenant id parsing dependency (`X-SS-Tenant-ID` default `default`)
- [ ] 2.2 Thread `tenant_id` through domain services + queue claim
- [ ] 2.3 Enforce tenant-isolated job store layout and access checks

## 3. Tests
- [ ] 3.1 Job store: same `job_id` across tenants does not collide
- [ ] 3.2 API/queue/worker invariant: cross-tenant access is rejected

## 4. Validation + delivery
- [ ] 4.1 `ruff check .`
- [ ] 4.2 `pytest -q`
- [ ] 4.3 Update run log + deployment notes and close task card acceptance checklist
