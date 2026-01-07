from src.infra.stata_safety import find_unsafe_dofile_reason


def test_find_unsafe_dofile_reason_with_stata_line_continuation_returns_none() -> None:
    do_file = "\n".join(
        [
            "version 18",
            "quietly twoway (scatter y x) ///",
            "    (lfit y x)",
        ]
    )
    assert find_unsafe_dofile_reason(do_file) is None

