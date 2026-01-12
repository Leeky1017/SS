## 1. Implementation
- [ ] 1.1 Add `pytest-cov` to `pyproject.toml` `dev` extras
- [ ] 1.2 Gate `ci` + `merge-serial` with `pytest --cov=src --cov-fail-under=75`

## 2. Testing
- [ ] 2.1 `ruff check .`
- [ ] 2.2 `pytest -q --cov=src --cov-fail-under=75`

## 3. Documentation
- [ ] 3.1 Update OpenSpec testing strategy to note the CI coverage gate baseline
