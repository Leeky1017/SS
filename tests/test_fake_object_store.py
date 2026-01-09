from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor

from src.domain.object_store import CompletedPart
from src.infra.fake_object_store import FakeObjectStore


def test_fake_object_store_direct_put_roundtrip() -> None:
    # Arrange
    store = FakeObjectStore()
    object_key = "tenant_a/job_1/file_1.bin"
    data = b"hello"
    url = store.presign_put(object_key=object_key, expires_in_seconds=60, content_type="text/plain")

    # Act
    etag = store.put_via_presigned_url(url=url, data=data)

    # Assert
    head = store.head_object(object_key=object_key)
    assert head is not None
    assert head.size_bytes == len(data)
    assert head.etag == etag
    assert store.read_bytes(object_key=object_key) == data


def test_fake_object_store_multipart_put_roundtrip() -> None:
    # Arrange
    store = FakeObjectStore()
    object_key = "tenant_a/job_1/file_2.bin"
    upload_id = store.create_multipart_upload(
        object_key=object_key,
        content_type="application/octet-stream",
    )
    parts = [(1, b"aaa"), (2, b"bbb"), (3, b"ccc")]
    urls = [
        store.presign_upload_part(
            object_key=object_key,
            upload_id=upload_id,
            part_number=part_number,
            expires_in_seconds=60,
        )
        for part_number, _ in parts
    ]

    # Act
    etags = [
        store.put_via_presigned_url(url=url, data=data)
        for url, (_, data) in zip(urls, parts, strict=True)
    ]
    complete_etag = store.complete_multipart_upload(
        object_key=object_key,
        upload_id=upload_id,
        parts=[
            CompletedPart(part_number=n, etag=e)
            for (n, _), e in zip(parts, etags, strict=True)
        ],
    )

    # Assert
    combined = b"".join(data for _, data in parts)
    head = store.head_object(object_key=object_key)
    assert head is not None
    assert head.size_bytes == len(combined)
    assert head.etag == complete_etag
    assert store.read_bytes(object_key=object_key) == combined


def test_fake_object_store_when_parts_uploaded_concurrently_can_complete() -> None:
    # Arrange
    store = FakeObjectStore()
    object_key = "tenant_a/job_1/file_3.bin"
    upload_id = store.create_multipart_upload(object_key=object_key, content_type=None)
    parts = [(n, f"part-{n},".encode("utf-8")) for n in range(1, 11)]
    urls = {
        n: store.presign_upload_part(
            object_key=object_key,
            upload_id=upload_id,
            part_number=n,
            expires_in_seconds=60,
        )
        for n, _ in parts
    }

    # Act
    with ThreadPoolExecutor(max_workers=8) as pool:
        etags = dict(
            pool.map(
                lambda p: (p[0], store.put_via_presigned_url(url=urls[p[0]], data=p[1])),
                parts,
            )
        )
    complete_etag = store.complete_multipart_upload(
        object_key=object_key,
        upload_id=upload_id,
        parts=[CompletedPart(part_number=n, etag=etags[n]) for n, _ in parts],
    )

    # Assert
    combined = b"".join(data for _, data in parts)
    head = store.head_object(object_key=object_key)
    assert head is not None
    assert head.etag == complete_etag
    assert store.read_bytes(object_key=object_key) == combined
