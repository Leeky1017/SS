from __future__ import annotations


def test_create_job_writes_job_json(job_service, store, jobs_dir):
    job = job_service.create_job(requirement="hello")
    path = jobs_dir / job.job_id / "job.json"
    assert path.exists()
    loaded = store.load(job.job_id)
    assert loaded.job_id == job.job_id
    assert loaded.status == "created"


def test_confirm_job_sets_queued(job_service, store):
    job = job_service.create_job(requirement=None)
    updated = job_service.confirm_job(job_id=job.job_id, confirmed=True)
    assert updated.status == "queued"
    assert updated.scheduled_at is not None

    loaded = store.load(job.job_id)
    assert loaded.status == "queued"
