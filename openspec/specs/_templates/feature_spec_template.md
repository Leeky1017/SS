# Spec — <short title>

## Goal

<One paragraph: what user-visible outcome we want.>

## Context

<What exists today? What is broken/missing? Why now?>

## Non-goals

- <Explicitly list what is out of scope for this issue.>

## Definitions

- <Term>: <meaning>

## Requirements

### Functional

- MUST ...
- MUST NOT ...
- SHOULD ...

### Data contracts

- MUST define/modify: <schemas, file formats, API payloads>

### Error handling & observability

- MUST return `error_code` + `message`
- MUST log event code + context (`job_id`, `run_id`, ...)

### Security

- MUST prevent path traversal (`..`) and symlink escape
- MUST redact sensitive data in logs/artifacts

## Scenarios (verifiable)

### Scenario: happy path

Given ...
When ...
Then ...

Verification:
- Command: `<command>`
- Evidence: `<file path>` / `<test name>`

### Scenario: error path

Given ...
When ...
Then ...

Verification:
- Command: `<command>`
- Evidence: `<file path>` / `<test name>`

