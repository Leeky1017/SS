# Proposal: issue-214-env-deps-bootstrap

## Summary

ADDED:
- Root dependency checklist for local setup

MODIFIED:
- Expand `.env.example` to include the full SS config surface (including Yunwu LLM proxy settings)

## Impact

- Makes local setup reproducible (dependencies + env surface are explicit).
- Enables switching from stub LLM to Yunwu-proxied Claude via env vars without code changes.

