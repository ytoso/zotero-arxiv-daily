#!/usr/bin/env bash
# Run the pipeline once, retrying a few minutes later if it retrieves
# 0 papers on a weekday (arXiv can occasionally return an empty feed).
set -u

RETRY_MINUTES="${RETRY_MINUTES:-20}"
MAX_RETRIES="${MAX_RETRIES:-4}"

cd /app

for attempt in $(seq 0 "$MAX_RETRIES"); do
  ts=$(date -u +%Y%m%d-%H%M%S)
  log="/app/logs/run-${ts}.log"
  echo "[$(date -u +%H:%M:%S)] Run attempt $((attempt + 1))/$((MAX_RETRIES + 1))"

  uv run src/zotero_arxiv_daily/main.py > "$log" 2>&1
  rc=$?
  cat "$log"

  if [ "$rc" -ne 0 ]; then
    echo "[$(date -u +%H:%M:%S)] Pipeline error (exit $rc) — not retrying."
    exit "$rc"
  fi

  if ! grep -q "Total 0 papers retrieved" "$log"; then
    echo "[$(date -u +%H:%M:%S)] Papers retrieved — done."
    exit 0
  fi

  dow=$(date -u +%u) # 1=Mon .. 7=Sun
  if [ "$dow" -ge 6 ]; then
    echo "[$(date -u +%H:%M:%S)] No papers, but it's the weekend (day $dow) — expected, not retrying."
    exit 0
  fi

  if [ "$attempt" -lt "$MAX_RETRIES" ]; then
    echo "[$(date -u +%H:%M:%S)] No papers on a weekday — retrying in ${RETRY_MINUTES} min."
    sleep $((RETRY_MINUTES * 60))
  fi
done

echo "[$(date -u +%H:%M:%S)] Still no papers after ${MAX_RETRIES} retries — giving up."
exit 0
