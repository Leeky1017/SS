# Spec: ss-testing-strategy

## Purpose

Define a user-centric, layered testing strategy for SS (unit → user journeys → concurrency → stress/chaos → production monitoring), so correctness is validated at the level users experience and regressions are caught early.

## Requirements

### Requirement: Canonical testing strategy lives under OpenSpec

The SS testing strategy MUST be maintained under `openspec/specs/ss-testing-strategy/` and treated as canonical.

#### Scenario: Strategy is discoverable
- **WHEN** browsing `openspec/specs/ss-testing-strategy/`
- **THEN** `spec.md`, `README.md`, and `task_cards/` exist

### Requirement: Strategy defines layered test architecture

The strategy MUST define these layers and their goals:
- Unit (fast, deterministic, module-level)
- User Journey (real user flows across API boundaries)
- Concurrency (multi-user/worker race conditions and atomicity)
- Stress (load, stability, boundary data volume)
- Chaos (resource exhaustion and dependency failure)
- Production monitoring validation (metrics/logs/SLO feedback loop)

#### Scenario: Layers are documented
- **WHEN** reading `openspec/specs/ss-testing-strategy/README.md`
- **THEN** each layer has an explicit goal, example scenarios, and an intended test location

### Requirement: User-centric scenarios are enumerated

The strategy MUST enumerate the user-centric scenarios described in the strategy README, including:
- User journeys A–D
- Concurrency scenarios 1–4
- Stress scenarios 1–4
- Chaos scenarios for resource exhaustion and dependency unavailability

#### Scenario: Scenario catalog is reviewable
- **WHEN** reviewing `openspec/specs/ss-testing-strategy/README.md`
- **THEN** each scenario lists validation points and an intended `tests/...` module path

### Requirement: Implementation is tracked via task cards

This spec MUST provide task cards for implementing the strategy:
- `openspec/specs/ss-testing-strategy/task_cards/user_journeys.md`
- `openspec/specs/ss-testing-strategy/task_cards/concurrent.md`
- `openspec/specs/ss-testing-strategy/task_cards/stress.md`
- `openspec/specs/ss-testing-strategy/task_cards/chaos.md`

#### Scenario: Task cards are actionable
- **WHEN** a contributor picks up testing work
- **THEN** each task card contains Goal, In scope, Dependencies, and an Acceptance checklist

### Requirement: CI enforces a baseline coverage gate

The required CI workflows (`ci` and `merge-serial`) MUST run pytest with coverage for `src` and MUST fail when overall coverage drops below the baseline threshold.

Baseline threshold (initial): 75%.

#### Scenario: CI fails when coverage drops below the baseline
- **GIVEN** CI runs `pytest -q --cov=src --cov-fail-under=75`
- **WHEN** overall coverage is below 75%
- **THEN** the CI job fails

### Requirement: Spec passes strict validation

`openspec/specs/ss-testing-strategy/spec.md` MUST pass strict validation.

#### Scenario: Strict validation passes
- **WHEN** `openspec validate --specs --strict --no-interactive` is executed
- **THEN** it exits with code `0`
