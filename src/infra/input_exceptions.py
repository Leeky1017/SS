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


class InputRoleInvalidError(SSError):
    def __init__(self, *, role: str) -> None:
        super().__init__(
            error_code="INPUT_ROLE_INVALID",
            message=f"dataset role invalid: {role}",
            status_code=400,
        )


class InputRoleCountMismatchError(SSError):
    def __init__(self, *, expected: int, actual: int) -> None:
        super().__init__(
            error_code="INPUT_ROLE_COUNT_MISMATCH",
            message=f"dataset roles count mismatch: expected={expected} actual={actual}",
            status_code=400,
        )


class InputFilenameCountMismatchError(SSError):
    def __init__(self, *, expected: int, actual: int) -> None:
        super().__init__(
            error_code="INPUT_FILENAME_COUNT_MISMATCH",
            message=f"dataset filenames count mismatch: expected={expected} actual={actual}",
            status_code=400,
        )


class InputDatasetKeyConflictError(SSError):
    def __init__(self, *, dataset_key: str) -> None:
        super().__init__(
            error_code="INPUT_DATASET_KEY_CONFLICT",
            message=f"dataset_key conflict: {dataset_key}",
            status_code=400,
        )


class InputPrimaryDatasetMissingError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="INPUT_PRIMARY_DATASET_MISSING",
            message="primary_dataset role missing",
            status_code=400,
        )


class InputPrimaryDatasetMultipleError(SSError):
    def __init__(self, *, count: int) -> None:
        super().__init__(
            error_code="INPUT_PRIMARY_DATASET_MULTIPLE",
            message=f"multiple primary_dataset roles: {count}",
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


class InputMainDataSourceNotFoundError(SSError):
    def __init__(self, *, main_data_source_id: str) -> None:
        super().__init__(
            error_code="INPUT_MAIN_DATA_SOURCE_NOT_FOUND",
            message=f"main_data_source_id not found: {main_data_source_id}",
            status_code=400,
        )
