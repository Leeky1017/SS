# Delta spec: SSC dependency list + TI09 dep removal

## Context

Some templates in `assets/stata_do_library/` require Stata SSC packages. `TI09` previously depended on `stcure`, but `ssc install stcure` fails (package not found), so `TI09` must not depend on it.

## Requirements

1. Provide a canonical SSC dependency list under OpenSpec:
   - File: `openspec/specs/ss-do-template-library/SSC_DEPENDENCIES.md`
   - Includes: SSC package name, templates that require it, and install command.
2. `TI09` MUST run without external Stata packages (no `stcure` dependency in template meta or smoke-suite manifest).
3. The TI/TJ smoke-suite MUST pass for all templates in the manifest:
   - Manifest: `assets/stata_do_library/smoke_suite/manifest.issue-271.ti01-ti11.tj01-tj06.1.0.json`
   - Expected: 17/17 passed, and `missing_deps` is empty.

## Non-goals

- Auto-install SSC packages at template runtime.
- Changing template contents beyond dependency documentation and verification.
