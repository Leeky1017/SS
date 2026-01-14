# Spec: ss-release-zip (task delta)

## Purpose

Provide a reproducible way to package the current SS repository into a single zip file for distribution.

## Requirements

### Requirement: A zip release can be generated from tracked files

SS MUST provide a script that creates a zip archive from git-tracked files (no `.git/`, no local worktrees, no virtualenv).

#### Scenario: Generate a release zip from repo root
- **GIVEN** a git checkout of the SS repository
- **WHEN** running `scripts/ss_release_zip.sh` from the SS repo root
- **THEN** it writes a zip file under `release/` named with the current commit hash

### Requirement: Generated release zips are not committed by default

The repository MUST ignore generated zip artifacts under `release/` to avoid committing large binaries.

#### Scenario: Zip artifacts are ignored
- **GIVEN** `release/*.zip` artifacts are generated locally
- **WHEN** `scripts/ss_release_zip.sh` creates `release/*.zip`
- **THEN** `git status` does not show the generated zip as a tracked change
