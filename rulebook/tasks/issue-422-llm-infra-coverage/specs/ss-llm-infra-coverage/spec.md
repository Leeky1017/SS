# Spec: ss-llm-infra-coverage (issue-422)

## Purpose

Protect the LLM integration boundary (config validation and provider error mapping) with deterministic unit tests.

## Requirements

### Requirement: LLM client factory validates configuration

SS MUST include unit tests verifying `build_llm_client`:
- rejects empty/`stub` provider
- rejects unsupported provider values
- rejects missing `SS_LLM_API_KEY` / empty model / empty base URL for OpenAI-compatible providers

#### Scenario: Unsupported provider is rejected
- **GIVEN** a config with `llm_provider="unknown"`
- **WHEN** `build_llm_client` is called
- **THEN** it raises `LLMConfigurationError`

### Requirement: OpenAI-compatible LLM client maps provider errors

SS MUST include async unit tests verifying `OpenAICompatibleLLMClient.complete_text`:
- returns response text on success
- raises `LLMProviderError` when the OpenAI SDK raises `OpenAIError`
- raises `LLMProviderError` when response content is not a string

#### Scenario: Provider errors are mapped to LLMProviderError
- **GIVEN** an OpenAI client that raises `OpenAIError`
- **WHEN** `complete_text` is called
- **THEN** `LLMProviderError` is raised with a stable message

