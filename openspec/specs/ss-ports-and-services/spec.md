# Spec: ss-ports-and-services

## Purpose

Define SS ports (interfaces) and domain services decomposition so external complexity stays in infra and business logic stays testable.

## Requirements

### Requirement: Domain depends only on ports and models

Domain services MUST depend only on domain models and explicit ports, and MUST NOT depend on FastAPI, filesystem, subprocess, or third-party SDKs.

#### Scenario: Domain stays framework-agnostic
- **WHEN** reviewing `src/domain/`
- **THEN** it does not import FastAPI or infra adapters

### Requirement: External dependencies are explicit and injectable

All ports MUST be injected explicitly (constructor args / `Depends`) and MUST NOT be accessed via global singletons or implicit forwarding.

#### Scenario: Dependency injection is used
- **WHEN** assembling services in API/worker
- **THEN** dependencies are passed explicitly rather than imported globally

### Requirement: Ports are narrow and serializable

Port signatures MUST be narrow and stable, and port return values MUST be serializable into artifacts and `job.json`.

#### Scenario: Ports support testing
- **WHEN** unit testing a domain service
- **THEN** a fake port implementation can replace the real infra adapter

