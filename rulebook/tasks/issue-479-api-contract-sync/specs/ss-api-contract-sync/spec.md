# Purpose

Establish an automated, CI-enforced guardrail to keep SS frontend TypeScript API types in sync with backend
FastAPI/Pydantic schemas.

## Requirements

### Requirement: Deterministic OpenAPI export

#### Scenario: Export OpenAPI spec without starting the server
- **WHEN** the contract sync pipeline runs
- **THEN** it exports the backend OpenAPI spec deterministically from the FastAPI app code

### Requirement: TypeScript types are generated from OpenAPI

#### Scenario: Generate frontend types from OpenAPI
- **WHEN** the contract sync pipeline runs
- **THEN** it generates `frontend/src/api/types.ts` and `frontend/src/features/admin/adminApiTypes.ts`
- **THEN** manual editing of these files is forbidden (changes must come from generation)

### Requirement: CI fails on drift

#### Scenario: PR introduces schema/types mismatch
- **WHEN** a PR changes backend schemas or routes without regenerating frontend types
- **THEN** CI fails with a contract sync check error

### Requirement: Contract-first workflow for agents

#### Scenario: Agent changes an API contract
- **WHEN** an agent needs to change request/response fields or schema names
- **THEN** the agent changes backend Pydantic/FastAPI schemas first
- **THEN** the agent regenerates frontend types using the contract sync pipeline
