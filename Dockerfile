# ─────────────────────────────────────────────────────────────────────────────
# Ivy Warehouse — Dockerfile
# Gebouwd op Python 3.12 slim met uv als package manager
# ─────────────────────────────────────────────────────────────────────────────

FROM python:3.12-slim

# uv installeren vanuit de officiële image (snel en betrouwbaar)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Kopieer alleen de dependency bestanden eerst
# (Docker cache: als pyproject.toml niet verandert, wordt uv sync overgeslagen)
COPY pyproject.toml uv.lock* ./

# Installeer dependencies zonder dev tools en zonder een venv aan te maken
# --frozen: gebruik exact de versies uit uv.lock, installeer nooit iets anders
# --no-dev: sla de [dependency-groups.dev] over
# --system: installeer direct in de container Python, geen aparte venv nodig
RUN uv sync --frozen --no-dev --system

# Kopieer de rest van het project
COPY . .

# profiles.yml wordt via een volume mount of environment variables meegegeven
# NOOIT in de image bakken!

# Default: run alle modellen
# Overschrijf via `docker run ... dbt test` of `dbt run --select ...`
CMD ["dbt", "run"]
