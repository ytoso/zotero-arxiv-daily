# syntax=docker/dockerfile:1

# ---------- base image ----------
FROM python:3.13-slim

# uv binary (official image)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HF_HOME=/app/models \
    TOKENIZERS_PARALLELISM=false

WORKDIR /app

# Install dependencies (CPU-only torch, per pyproject's pytorch cpu index)
COPY pyproject.toml uv.lock README.md ./
COPY src ./src
COPY config ./config
RUN uv sync --frozen --no-dev

# ---------- supercronic (container-friendly cron) ----------
# amd64 binary; for arm64 use supercronic-linux-arm64.
ARG SUPERCRONIC_VERSION=v0.2.29
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL -o /usr/local/bin/supercronic \
       "https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-linux-amd64" \
    && chmod +x /usr/local/bin/supercronic \
    && apt-get purge -y curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/logs /app/models

COPY run.sh entrypoint.sh /app/
RUN chmod +x /app/run.sh /app/entrypoint.sh

# Persistent scheduler: runs the pipeline daily per CRON_SCHEDULE (UTC).
# Manual one-shot:  docker compose exec app /app/run.sh
ENTRYPOINT ["/app/entrypoint.sh"]
