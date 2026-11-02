## 🐳 Docker Deployment

You can run the pipeline in a container instead of GitHub Actions. This is the easiest way to deploy on your own server: all Python dependencies (including torch) are bundled into the image, and secrets are injected from a `.env` file.

### Prerequisites

- Docker + Docker Compose installed
- A `.env` file with your secrets (see the main README)

### 1. Build the image

```bash
git clone git@github.com:ytoso/zotero-arxiv-daily.git
cd zotero-arxiv-daily

# create .env here (ZOTERO_ID, ZOTERO_KEY, SENDER, SENDER_PASSWORD,
# RECEIVER, OPENAI_API_KEY, OPENAI_API_BASE)

docker compose build
```

> [!NOTE]
> In some regions you may want to set a registry mirror for `docker pull`
> (base images) and `HF_ENDPOINT=https://hf-mirror.com` for the Hugging Face
> model download. Add it under `environment:` in `docker-compose.yml` if needed.

### 2. Run once (manual test)

```bash
docker compose run --rm app
# quick smoke test with 10 papers:
docker compose run --rm -e DEBUG=true app
```

The image is a **one-shot job**: it runs the pipeline, sends the email, and exits.

### 3. Schedule it daily with host cron

arXiv releases each day's batch at ~00:00 UTC (summer) / 01:00 UTC (winter).
To email the newest papers, run shortly after release, e.g. 01:30 UTC:

```bash
crontab -e
```

```cron
# 01:30 UTC daily — adjust the paths to your machine
30 1 * * * cd /home/user/Codes/zotero-arxiv-daily && /usr/bin/docker compose run --rm app >> logs/cron.log 2>&1
```

### Configuration

- **Secrets** come from the `.env` file (`env_file` in `docker-compose.yml`).
- **Categories / SMTP / model** are in `config/custom.yaml`, baked into the image at build time. Change them and run `docker compose build` again — or mount your own file:
  ```yaml
  volumes:
    - ./config/custom.yaml:/app/config/custom.yaml:ro
  ```
- **Parallel LLM speed** is controlled by `executor.llm_concurrency` in `config/base.yaml` (default `8`).

### Model & log persistence

- The embedding model is cached in `./models` (mounted as `HF_HOME`), so it is not re-downloaded on every run.
- Logs are written to `./logs`.

### Useful commands

```bash
docker compose build          # build/rebuild the image
docker compose run --rm app   # run once
docker logs <container-id>    # inspect a run's output
```

### GPU support

By default the image uses CPU-only torch (small, and more than fast enough —
the pipeline's bottleneck is the LLM API, not compute). If you ever want GPU
embeddings, switch `pyproject.toml` to the CUDA torch wheel and use a CUDA base
image with `--gpus all`.
