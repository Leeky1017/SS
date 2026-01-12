from __future__ import annotations

from src.domain.worker_retry import backoff_seconds, normalized_max_attempts


def test_normalized_max_attempts_with_invalid_input_returns_one() -> None:
    assert normalized_max_attempts(None) == 1
    assert normalized_max_attempts("nope") == 1


def test_normalized_max_attempts_with_non_positive_returns_one() -> None:
    assert normalized_max_attempts(0) == 1
    assert normalized_max_attempts(-10) == 1


def test_normalized_max_attempts_with_positive_returns_value() -> None:
    assert normalized_max_attempts(3) == 3


def test_backoff_seconds_with_invalid_base_returns_zero() -> None:
    assert backoff_seconds(attempt=1, base_seconds="x", max_seconds=30.0) == 0.0
    assert backoff_seconds(attempt=1, base_seconds=0.0, max_seconds=30.0) == 0.0


def test_backoff_seconds_with_cap_applies_max_seconds() -> None:
    assert backoff_seconds(attempt=10, base_seconds=2.0, max_seconds=3.0) == 3.0


def test_backoff_seconds_with_attempt_increases_exponentially() -> None:
    assert backoff_seconds(attempt=1, base_seconds=1.0, max_seconds=30.0) == 1.0
    assert backoff_seconds(attempt=2, base_seconds=1.0, max_seconds=30.0) == 2.0
    assert backoff_seconds(attempt=3, base_seconds=1.0, max_seconds=30.0) == 4.0
