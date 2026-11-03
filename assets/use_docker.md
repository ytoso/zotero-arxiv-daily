## 🐳 Docker Deployment

Containerized deployment that **schedules itself** — no host cron needed. The container runs a small cron daemon ([supercronic](https://github.com/aptible/supercronic)) that executes the pipeline daily, with automatic retries when a weekday run retrieves no papers.

### Prerequisites

- Docker + Docker Compose
- A `.env` file with your secrets (see the main README)

### 1. Build and start

```bash
git clone git@github.com:ytoso/zotero-arxiv-daily.git
cd zotero-arxiv-daily

# create .env here (ZOTERO_ID, ZOTERO_KEY, SENDER, SENDER_PASSWORD,
# RECEIVER, OPENAI_API_KEY, OPENAI_API_BASE)

docker compose up -d --build
```

That's it. The container stays up and runs the pipeline on the schedule.

### 2. Schedule & retry behavior

- **Schedule**: controlled by `CRON_SCHEDULE` in `docker-compose.yml` (default `30 1 * * *` = 01:30 UTC daily, right after arXiv publishes).
- **Retry on empty weekday runs**: if the pipeline retrieves **0 papers** on a weekday (Mon–Fri), `run.sh` waits `RETRY_MINUTES` (default 20) and re-runs, up to `MAX_RETRIES` (default 4) times. Weekends are not retried, since arXiv publishes nothing then.

All three are configurable via `environment:` in `docker-compose.yml`.

### 3. Run once manually

```bash
docker compose exec app /app/run.sh
# smoke test with 10 papers:
docker compose exec -e DEBUG=true app /app/run.sh
```

### 4. View logs

```bash
docker compose logs -f app          # scheduler + run output
ls logs/                            # one log file per run attempt
```

### Configuration

- **Secrets** come from `.env` (`env_file`).
- **Categories / SMTP / model** are in `config/custom.yaml`, baked into the image at build time. Change them and rebuild, or mount your own:
  ```yaml
  volumes:
    - ./config/custom.yaml:/app/config/custom.yaml:ro
  ```
- **Parallel LLM speed** is `executor.llm_concurrency` in `config/base.yaml` (default `8`).

### Model & log persistence

- The embedding model is cached in `./models` (mounted as `HF_HOME`) — downloaded once.
- Logs are written to `./logs`.

### Useful commands

```bash
docker compose up -d --build    # (re)build and start
docker compose exec app /app/run.sh   # run once manually
docker compose down             # stop
```

### Notes for users in China

- If the build fails downloading supercronic from GitHub, pass a proxy: `docker compose build --build-arg HTTP_PROXY=... --build-arg HTTPS_PROXY=...`.
- If the Hugging Face model download is slow, add `HF_ENDPOINT=https://hf-mirror.com` under `environment:`.

### GPU support

By default the image uses CPU-only torch (small, and fast enough — the pipeline's bottleneck is the LLM API, not compute). For GPU embeddings, switch `pyproject.toml` to the CUDA torch wheel and use a CUDA base image with `--gpus all`.
