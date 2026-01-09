# Spec: ss-env-bootstrap (issue-214)

## Purpose

Make SS setup reproducible by fully specifying required dependencies and environment variables (including Yunwu LLM proxy configuration).

## Requirements

### Requirement: Environment surface is complete and explicit

SS MUST provide a root `.env.example` that enumerates every supported `SS_*` environment variable with explicit default values (except secrets).

#### Scenario: `.env.example` covers all config keys
- **WHEN** a developer reads `.env.example`
- **THEN** all `SS_*` settings used by `src/config.py` are listed with documented defaults

### Requirement: Yunwu proxy configuration is documented

SS MUST document how to call LLMs via Yunwu (OpenAI-compatible) proxy, including base URL options and authentication header shape.

#### Scenario: Yunwu proxy can be configured via env vars
- **WHEN** a developer sets `SS_LLM_BASE_URL` and `SS_LLM_API_KEY`
- **THEN** SS can be configured to call a Yunwu-proxied Claude model without code changes

