# ─────────────────────────────────────────────────────────────────────────────
# Ivy Warehouse — Dockerfile
# Gebouwd op Python 3.12 slim met uv als package manager
# ─────────────────────────────────────────────────────────────────────────────
 
FROM python:3.12-slim
 
# uv installeren vanuit de officiële image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
 
WORKDIR /app
 
# Kopieer alleen de dependency bestanden eerst
# (Docker cache: als pyproject.toml niet verandert, wordt uv sync overgeslagen)
COPY pyproject.toml uv.lock* ./
 
# Installeer dependencies zonder dev tools en zonder een venv aan te maken
# --frozen: gebruik exact de versies uit uv.lock, geen resolve
# --no-dev: sla de [dependency-groups.dev] over
# --system: installeer direct in de container Python, geen aparte venv nodig
RUN uv sync --frozen --no-dev --system
 
# Kopieer de rest van het project
COPY . .
 
# profiles.yml wordt via volume mount of environment variables meegegeven
# NOOIT in de image!
 
# ─────────────────────────────────────────────────────────────────────────────
# Gebruik:
#
#   dbt-only (zelfde als voor):
#     docker run ivy-warehouse dbt run
#     docker run ivy-warehouse dbt test
#
#   Prefect worker (voor productie met een work pool):
#     docker run ivy-warehouse \
#       prefect worker start --pool ivy-pool
#
#   Losse flow draaien (handig voor Cloud Run Jobs):
#     docker run ivy-warehouse \
#       python flows/pipeline.py
# ─────────────────────────────────────────────────────────────────────────────
CMD ["python", "-m", "flows.pipeline"]