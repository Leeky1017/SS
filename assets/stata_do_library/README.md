# assets/stata_do_library/ — Stata do template library

> **Contract**: v1.1  
> **Meta schema**: `assets/stata_do_library/schemas/do_meta/1.1.schema.json`  
> **Updated**: 2026-01-07

This directory vendors a Stata do-template library for SS.
SS treats it as a **versioned data asset** (not an OpenSpec/Rulebook task system).

## Layout

```
assets/stata_do_library/
├── do/                      # templates (.do)
│   ├── meta/                # template metadata (.meta.json)
│   └── includes/            # shared ado helpers
├── docs/                    # per-template docs (human-readable)
├── fixtures/                # sample inputs
├── schemas/                 # JSON Schemas (meta contract)
├── DO_LIBRARY_INDEX.json    # machine-readable index (CI-validated)
├── CAPABILITY_MANIFEST.json # capability manifest (non-authoritative)
└── SS_DO_CONTRACT.md        # hard contract for do templates
```

## CI gates

- Meta schema validation: `pytest -q tests/test_do_library_meta_schema.py`
- Index consistency: `pytest -q tests/test_do_library_index_consistency.py`

## Local checks

- Lint templates: `python3 assets/stata_do_library/DO_LINT_RULES.py --path assets/stata_do_library/do/`
