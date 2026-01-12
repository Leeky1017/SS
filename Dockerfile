FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    SS_JOBS_DIR=/data/jobs \
    SS_QUEUE_DIR=/data/queue \
    SS_DO_TEMPLATE_LIBRARY_DIR=/app/assets/stata_do_library

WORKDIR /app

RUN mkdir -p /data/jobs /data/queue

COPY requirements.txt /app/requirements.txt

RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir -r requirements.txt

COPY src /app/src

COPY assets /app/assets

EXPOSE 8000 8001

CMD ["python", "-m", "src.main"]
