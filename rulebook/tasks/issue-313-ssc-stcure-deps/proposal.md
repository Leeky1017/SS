# Proposal: issue-313-ssc-stcure-deps

## Why
TI/TJ smoke-suite includes `TI09`, which previously required `stcure`. In practice `ssc install stcure` fails (package not found), so the template must not depend on it; we also want a canonical SSC dependency list for provisioning remote/server Stata environments.

## What Changes
- Add canonical SSC dependency list for `assets/stata_do_library/` templates.
- Replace the `TI09` implementation so it no longer depends on `stcure` (built-in approximation).
- Re-run the TI/TJ smoke-suite to confirm all templates pass with zero missing deps.

## Impact
- Affected specs: `openspec/specs/ss-do-template-library/SSC_DEPENDENCIES.md`
- Affected code: none
- Breaking change: NO
- User benefit: remote/server Stata environments can be provisioned up-front; `TI09` no longer blocks TI/TJ smoke-suite due to undocumented SSC deps.
