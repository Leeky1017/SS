from __future__ import annotations

from src.infra.exceptions import SSError


class DoTemplateSelectionParseError(SSError):
    def __init__(self, *, stage: str, reason: str):
        super().__init__(
            error_code="DO_TEMPLATE_SELECTION_PARSE_FAILED",
            message=f"do template selection parse failed ({stage}): {reason}",
            status_code=502,
        )


class DoTemplateSelectionNoCandidatesError(SSError):
    def __init__(self, *, stage: str):
        super().__init__(
            error_code="DO_TEMPLATE_SELECTION_NO_CANDIDATES",
            message=f"do template selection has no candidates ({stage})",
            status_code=500,
        )


class DoTemplateSelectionInvalidFamilyIdError(SSError):
    def __init__(self, *, family_id: str):
        super().__init__(
            error_code="DO_TEMPLATE_SELECTION_INVALID_FAMILY_ID",
            message=f"do template selection invalid family_id: {family_id}",
            status_code=502,
        )


class DoTemplateSelectionInvalidTemplateIdError(SSError):
    def __init__(self, *, template_id: str):
        super().__init__(
            error_code="DO_TEMPLATE_SELECTION_INVALID_TEMPLATE_ID",
            message=f"do template selection invalid template_id: {template_id}",
            status_code=502,
        )

