from __future__ import annotations

from src.infra.exceptions import SSError


class InputEmptyFileError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="INPUT_EMPTY_FILE",
            message="uploaded dataset file is empty",
            status_code=400,
        )


class InputUnsupportedFormatError(SSError):
    def __init__(self, *, filename: str) -> None:
        super().__init__(
            error_code="INPUT_UNSUPPORTED_FORMAT",
            message=f"unsupported dataset format: {filename}",
            status_code=400,
        )


class InputFilenameUnsafeError(SSError):
    def __init__(self, *, filename: str) -> None:
        super().__init__(
            error_code="INPUT_FILENAME_UNSAFE",
            message=f"dataset filename unsafe: {filename}",
            status_code=400,
        )


class InputPathUnsafeError(SSError):
    def __init__(self, *, job_id: str, rel_path: str) -> None:
        super().__init__(
            error_code="INPUT_PATH_UNSAFE",
            message=f"input path unsafe: {job_id}:{rel_path}",
            status_code=400,
        )


class InputParseFailedError(SSError):
    def __init__(self, *, filename: str, detail: str | None = None) -> None:
        suffix = "" if detail is None or detail.strip() == "" else f" ({detail})"
        super().__init__(
            error_code="INPUT_PARSE_FAILED",
            message=f"failed to parse dataset: {filename}{suffix}",
            status_code=400,
        )


class InputStorageFailedError(SSError):
    def __init__(self, *, job_id: str, rel_path: str) -> None:
        super().__init__(
            error_code="INPUT_STORAGE_FAILED",
            message=f"failed to store input: {job_id}:{rel_path}",
            status_code=500,
        )
