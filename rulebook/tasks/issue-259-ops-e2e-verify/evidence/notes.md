# Notes: issue-259-ops-e2e-verify

## Findings (running)
- LLM proxy supports Opus 4.5 as `claude-opus-4-5-20251101`; legacy alias `claude-opus-4-5` returns 503 “no available channels”.
- Stata runner (Windows Stata 18 via WSL interop) works in batch mode and produces `.log`.
- E2E attempt failed at run phase because generated do-file used `use` on `.csv` (r(609)); fix is to `import delimited` for CSV.

## Decisions
- Normalize Opus 4.5 alias to versioned id in config loader.
- Teach `DoFileGenerator` to import CSV (and infer format by extension when missing).

## Later
- Consider extracting structured variables (outcome/treatment/controls) from LLM output so `draft preview` fields are non-null without patching.

