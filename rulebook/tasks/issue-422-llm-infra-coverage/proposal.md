# Proposal: issue-422-llm-infra-coverage

## Why
LLM infra is an integration boundary (config validation + provider error mapping) but currently has low coverage, making production regressions harder to catch.

## What Changes
- Add unit tests for `build_llm_client` config validation.
- Add async unit tests for `OpenAICompatibleLLMClient.complete_text` success and error paths.

## Impact
- Affected specs: none (task-scoped spec delta only)
- Affected code: `src/infra/llm_client_factory.py`, `src/infra/openai_compatible_llm_client.py`, new tests under `tests/`
- Breaking change: NO
- User benefit: Safer LLM integration behavior with explicit, tested failure semantics.
