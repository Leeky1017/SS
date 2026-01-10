# SS Dependencies & Setup Checklist

## System prerequisites

- Python `>=3.12`
- `git`
- (Optional) Stata installed locally (for Stata runner features)
- (Optional) Postgres / Redis (only if you switch `SS_JOB_STORE_BACKEND`)

## Stata (SSC packages)

Some templates require Stata SSC packages and will fail-fast if missing.

- Canonical list: `openspec/specs/ss-do-template-library/SSC_DEPENDENCIES.md`

## Python dependencies

SS is a Python package with dependencies defined in `pyproject.toml`.

### Install (local dev)

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -U pip
pip install -e ".[dev]"
```

## Environment variables

SS reads config from environment variables (see `.env.example` for the full surface).

### Quick start (local)

```bash
cp .env.example .env
# edit .env to fill SS_LLM_API_KEY (and optionally adjust SS_LLM_PROVIDER/SS_LLM_MODEL)
set -a
. ./.env
set +a
python -m src.main
```

## Yunwu (OpenAI-compatible proxy) configuration

Yunwu docs: https://yunwu.apifox.cn/

- API key: https://yunwu.ai/token
- Base URL (pick one; data is shared):
  - `https://yunwu.ai/v1`
  - `https://yunwu.zeabur.app/v1`
  - `https://api.apiplus.org/v1`
  - `https://api3.wlai.vip/v1`
- Auth header: `Authorization: Bearer <YOUR_API_KEY>`
- Endpoint: `POST /v1/chat/completions`

Model ids vary by provider/model availability on Yunwu. Set `SS_LLM_MODEL` accordingly (examples from Yunwu docs include `claude-3-5-sonnet-20240620` and `claude-sonnet-4-20250514`).

## Verification

```bash
. .venv/bin/activate
ruff check .
pytest -q
```
