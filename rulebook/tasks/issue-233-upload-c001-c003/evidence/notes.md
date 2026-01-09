# Notes: issue-233-upload-c001-c003

## Scope guardrails
- This PR covers UPLOAD-C001..C003 only (bundle + object-store boundary). Upload sessions + finalize are deferred to UPLOAD-C004..C006.

## Open questions (parked)
- Authorization header semantics for bundle endpoints will align with the upcoming auth work (task line B-2); for now, endpoints follow existing server auth patterns.

