# Spec Delta: BE-007 Column name normalization

## Context

Column names may contain Unicode characters or other tokens that cannot be used as Stata variable names. The system needs a stable `original -> normalized` mapping that can be shown to users and used consistently.

## Requirements

- Draft preview includes a mapping table for column normalization:
  - Each entry includes at least `dataset_key`, `role`, `original_name`, `normalized_name`.
  - `normalized_name` is Stata-safe and unique (per dataset).
- Normalization algorithm is deterministic for the same input set (stable ordering, stable collision suffixing).

## Scenarios

- Unicode column names (e.g. Chinese) produce deterministic, legal Stata names and are surfaced in draft preview.
- Duplicate/near-duplicate columns produce unique normalized names with stable suffixes.
