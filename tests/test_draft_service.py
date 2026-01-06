from __future__ import annotations

import asyncio


def test_draft_preview_persists_draft(job_service, draft_service, store):
    job = job_service.create_job(requirement="need a descriptive analysis")
    draft = asyncio.run(draft_service.preview(job_id=job.job_id))
    assert "stub-draft" in draft.text

    loaded = store.load(job.job_id)
    assert loaded.draft is not None
    assert loaded.draft.text == draft.text
