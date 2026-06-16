# Ivy Warehouse

dbt project voor het Ivy data platform op Google BigQuery.

---

## Vereisten

Installeer deze tools eenmalig op je laptop:

- [Python 3.12](https://www.python.org/downloads/release/python-31210/) — kies de Windows installer (64-bit)
- [uv](https://docs.astral.sh/uv/) — Python package manager
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) — voor Google Cloud authenticatie
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) — alleen nodig als je de container lokaal wil draaien

```powershell
# uv installeren via winget (Windows)
winget install astral-sh.uv

# gcloud installeren via winget (Windows)
winget install Google.CloudSDK
```

---

## Eerste keer opzetten

### 1. Repository clonen

```powershell
git clone https://github.com/ivy-global/ivy-warehouse.git
cd ivy-warehouse
```

### 2. Dependencies installeren

uv installeert automatisch Python 3.12 en alle packages uit `uv.lock`:

```powershell
uv sync
```

### 3. Google Cloud authenticatie

```powershell
gcloud auth login
gcloud auth application-default login
gcloud config set project ivy-warehouse
```

### 4. profiles.yml aanmaken

dbt heeft een `profiles.yml` nodig om verbinding te maken met BigQuery. Dit bestand staat **niet** in git omdat het persoonlijke instellingen bevat.

Kopieer de template en pas hem aan:

```powershell
# Windows
copy profiles.yml.template $HOME\.dbt\profiles.yml
```

Open `~/.dbt/profiles.yml` en pas dit aan:
```yaml
dataset: dev_JOUNAAM    # bijvoorbeeld: dev_alex
```

### 5. Verbinding testen

```powershell
uv run dbt debug
```

Alle checks moeten groen zijn. Als dat zo is ben je klaar om te ontwikkelen.

---

## Dagelijks gebruik

```powershell
# Alle modellen runnen
uv run dbt run

# Alleen een specifiek model
uv run dbt run --select stg_mijn_model

# Alles runnen én testen
uv run dbt build

# Alleen tests
uv run dbt test

# dbt documentatie lokaal bekijken
uv run dbt docs generate
uv run dbt docs serve
```

Of activeer eerst de venv en laat `uv run` weg:

```powershell
.venv\Scripts\activate     # Windows
source .venv/bin/activate  # Mac/Linux

dbt run
dbt test
```

---

## Packages updaten

```powershell
# Alles updaten naar de nieuwste versies (binnen de ranges in pyproject.toml)
uv sync --upgrade

# Één package updaten
uv sync --upgrade-package dbt-bigquery

# Nieuw package toevoegen
uv add prefect
```

Commit de bijgewerkte `uv.lock` daarna naar git zodat iedereen dezelfde versies krijgt.

---

## Docker

Docker gebruik je om dbt te draaien op een server of in Google Cloud — zonder dat daar iets geïnstalleerd hoeft te worden.

### Image bouwen

```powershell
docker build -t ivy-warehouse .
```

### Lokaal testen met Docker

```powershell
docker run \
  -v $HOME/.dbt:/root/.dbt:ro \
  -v $HOME/.gcp:/root/.gcp:ro \
  ivy-warehouse dbt run
```

Op Windows (PowerShell):
```powershell
docker run `
  -v "$env:USERPROFILE\.dbt:/root/.dbt:ro" `
  -v "$env:USERPROFILE\.gcp:/root/.gcp:ro" `
  ivy-warehouse dbt run
```

Dit montet je lokale `profiles.yml` en service account key in de container — zonder dat ze in de image gebakken zitten.

### Andere commando's via Docker

```powershell
# Testen
docker run ... ivy-warehouse dbt test

# Specifiek model
docker run ... ivy-warehouse dbt run --select stg_orders

# Productie target
docker run ... ivy-warehouse dbt run --target prod
```

### Deployen naar Google Cloud Run

```powershell
# Authenticeer Docker met Google Artifact Registry
gcloud auth configure-docker europe-west4-docker.pkg.dev

# Tag en push de image
docker tag ivy-warehouse europe-west4-docker.pkg.dev/ivy-warehouse/dbt/ivy-warehouse:latest
docker push europe-west4-docker.pkg.dev/ivy-warehouse/dbt/ivy-warehouse:latest

# Maak een Cloud Run Job aan (eenmalig)
gcloud run jobs create dbt-run \
  --image europe-west4-docker.pkg.dev/ivy-warehouse/dbt/ivy-warehouse:latest \
  --region europe-west4 \
  --service-account dbt-runner@ivy-warehouse.iam.gserviceaccount.com

# Handmatig triggeren
gcloud run jobs execute dbt-run --region europe-west4
```

---

## Projectstructuur

```
ivy-warehouse/
├── dbt_project.yml          # dbt projectconfiguratie
├── pyproject.toml           # Python dependencies (bewerk dit)
├── uv.lock                  # exacte package versies (niet handmatig bewerken)
├── Dockerfile               # voor server/cloud deployments
├── profiles.yml.template    # kopieer dit naar ~/.dbt/profiles.yml
├── .gitignore
├── models/
│   ├── staging/             # views, 1:1 op brondata
│   ├── intermediate/        # tussenliggende transformaties
│   └── marts/               # eindproducten voor rapportage
├── seeds/                   # kleine statische CSV bestanden
├── tests/                   # custom data tests
├── macros/                  # herbruikbare SQL functies
└── snapshots/               # historische data (SCD type 2)
```

---

## Omgevingen

| Target | Dataset in BigQuery | Wanneer |
|--------|-------------------|---------|
| `dev` | `dev_JOUNAAM_*` | Lokaal ontwikkelen |
| `prod` | `prod_*` | Productie (via service account) |
| `ci` | Via GitHub secrets | Automatisch bij pull request |

```powershell
uv run dbt run                 # dev (standaard)
uv run dbt run --target prod   # productie
```

---

## Problemen

**`dbt debug` geeft een fout op de verbinding**
Controleer of je bent ingelogd: `gcloud auth application-default login`

**`uv sync` vindt Python 3.12 niet**
Installeer Python 3.12 via https://www.python.org/downloads/release/python-31210/ en open een nieuwe terminal.

**Docker kan `profiles.yml` niet vinden**
Controleer of het pad in het `-v` argument klopt en of `~/.dbt/profiles.yml` bestaat.
