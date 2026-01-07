## 1. Implementation
- [ ] 1.1 Define audit event schema + audit logger port
- [ ] 1.2 Emit audit events for job create/confirm/run and status transitions (API + worker)
- [ ] 1.3 Add request context correlation for audit events (request_id, actor)

## 2. Testing
- [ ] 2.1 Unit tests for audit emission in job/worker services
- [ ] 2.2 Integration tests for API endpoints emitting audit events (basic coverage)

## 3. Documentation
- [ ] 3.1 Document correlation keys for audit events (job_id, request_id)
