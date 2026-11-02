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

RUN mkdir -p /app/logs /app/models

# One-shot job: runs the pipeline once and exits.
# Schedule it with host cron:  docker compose run --rm app
CMD ["uv", "run", "src/zotero_arxiv_daily/main.py"]
