# Spec: ss-stata-infra-coverage (issue-424)

## Purpose

Protect the Stata integration boundary (dependency preflight + command resolution) with deterministic unit tests so coverage can safely move above 80%.

## Requirements

### Requirement: Dependency checker filters and validates dependencies

SS MUST include unit tests verifying `LocalStataDependencyChecker`:
- ignores dependencies from unsupported sources
- rejects unsafe package names (adds them to `missing`)
- returns stable `RunError` codes for workspace/write/subprocess/read failures
- returns `missing` dependencies when the preflight output file lists missing packages

#### Scenario: Unsafe dependency names are reported as missing
- **GIVEN** dependencies including an unsafe Stata package name
- **WHEN** `LocalStataDependencyChecker.check` runs successfully
- **THEN** the result includes that dependency in `missing`

### Requirement: Stata command utilities handle Windows/WSL interop defensively

SS MUST include unit tests verifying `src/infra/stata_cmd.py`:
- `_is_windows_stata_cmd` detects Windows Stata executables
- `build_stata_batch_cmd` selects `/e do` for Windows Stata and `-b do` otherwise
- `_validate_wsl_windows_interop` is a no-op when WSL interop prerequisites are not met
- `_validate_wsl_windows_interop` raises `SSError(error_code="WSL_INTEROP_UNAVAILABLE")` for timeout/subprocess failures and non-zero `cmd.exe` exit codes

