# Proposal: issue-459-release-zip

## Why
We need a reproducible way to bundle the latest SS code into a single zip file for distribution and offline use.

## What Changes
- Add a small packaging script that builds a zip from tracked files via `git archive`.
- Ensure generated zip artifacts in `release/` are ignored by git.

## Impact
- Affected specs: none
- Affected code: `scripts/` + `.gitignore`
- Breaking change: NO
- User benefit: one command to generate a clean release zip under `release/`
