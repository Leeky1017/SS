# Spec: ss-ports-and-services

## Purpose

Define SS ports (interfaces) and domain services decomposition so external complexity stays in infra adapters and business logic stays testable.

## Requirements

### Requirement: Terminology distinguishes adapters from shared infrastructure

This spec MUST use the following terms consistently:
- **infra adapters** are concrete implementations that integrate external systems (filesystem, subprocess, SDKs, network services).
- **shared application infrastructure** is application-level shared primitives usable across layers (e.g., `src/infra/exceptions.py` `SSError` hierarchy; structured logging helpers).

#### Scenario: Reviews use consistent terminology
- **WHEN** reviewing a dependency from `src/domain/`
- **THEN** it is classified as either an infra adapter or shared application infrastructure

### Requirement: Domain depends only on models, ports, and shared application infrastructure

Domain services MUST depend only on domain models, explicit ports, and shared application infrastructure.
Domain services MUST NOT depend on FastAPI or infra adapters (filesystem, subprocess, or third-party SDKs).

#### Scenario: Domain stays framework-agnostic
- **WHEN** reviewing `src/domain/`
- **THEN** it does not import FastAPI or infra adapters (but MAY import shared application infrastructure)

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
