## 1. Implementation
- [x] 1.1 Add v1 config limits for upload-sessions (TTL, size, parts, sessions/job)
- [x] 1.2 Implement upload session issuance (direct/multipart) + refresh URLs
- [x] 1.3 Implement finalize (strong idempotency; manifest + fingerprint + artifacts)

## 2. Testing
- [x] 2.1 Add pytest coverage for direct + multipart flows (fake object store)
- [x] 2.2 Add anyio concurrency tests for create-session + finalize

## 3. Documentation
- [x] 3.1 Update run log with commands/output + stress/bench plan
