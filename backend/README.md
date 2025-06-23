# FastAPI Backend

Un backend moderno e sicuro costruito con **FastAPI** e **uv** (package manager di Astral), containerizzato con Docker e deployato automaticamente su EC2 tramite Terraform.

## 🎯 Overview

Questo backend fa parte di un sistema full-stack che include:
- **Infrastructure**: Terraform per EC2, VPC, Security Groups
- **Backend**: FastAPI con uv, containerizzato e auto-deployato
- **Deployment**: Sistema unificato tramite Makefile principale

## 🚀 Features

### API Endpoints
- `GET /` - Root endpoint con informazioni sistema
- `GET /health` - Health check con timestamp
- `GET /messages` - Lista tutti i messaggi
- `POST /messages` - Crea nuovo messaggio
- `GET /messages/{id}` - Ottieni messaggio specifico
- `DELETE /messages/{id}` - Elimina messaggio

### Tecnologie Moderne
- **Python 3.13** - Ultima versione con performance migliorate
- **uv** - Package manager ultra-veloce di Astral
- **FastAPI** - Framework async ad alte performance
- **Loguru** - Logging avanzato con rotazione file
- **Docker** - Containerizzazione con health checks
- **Pydantic** - Validazione dati automatica

## 🏗️ Architettura

```
backend/
├── src/
│   ├── __init__.py
│   └── main.py          # FastAPI application
├── tests/
│   ├── __init__.py
│   └── test_api.py      # Test suite
├── logs/                # Log files (persistent)
├── pyproject.toml       # uv configuration
├── uv.lock             # Dependency lock file
├── Dockerfile          # Multi-stage build
├── docker-compose.yml  # Development setup
├── docker-compose.prod.yml # Production setup
├── deploy.sh           # EC2 deployment script
├── .env.example        # Environment template
└── README.md           # This file
```

## 🔧 Development Setup

### Prerequisites
- Docker e Docker Compose
- Python 3.13+ (opzionale, per sviluppo locale)
- uv package manager (opzionale)

### Quick Start Locale

Dal **root del progetto** (non dalla cartella backend):

```bash
# Avvia backend in modalità sviluppo
make backend-dev

# Testa gli endpoints
make test-local

# Visualizza logs
make backend-logs

# Ferma il backend
make backend-stop
```

Il backend sarà disponibile su:
- **API**: http://localhost:8000
- **Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Sviluppo Locale con uv

Se preferisci lavorare direttamente con uv:

```bash
cd backend

# Installa dipendenze
uv sync

# Avvia in modalità sviluppo
uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

# Esegui tests
uv run pytest tests/ -v
```

## 🚀 Deployment

### Deployment Automatico

Dal **root del progetto**:

```bash
# Deploy completo (infrastruttura + backend)
make deploy

# Solo backend (se infrastruttura già esistente)
make deploy-backend

# Verifica status
make status

# Test API remota
make test-remote
```

### Deployment Manuale

Se vuoi deployare solo il backend:

```bash
cd backend
chmod +x deploy.sh
./deploy.sh
```

Lo script:
1. Estrae l'IP dell'istanza EC2 da Terraform
2. Copia i file necessari via SCP
3. Avvia i container Docker sull'EC2
4. Verifica il health check

## 🧪 Testing

### Test Locali
```bash
# Test completo locale
make test-local

# Test specifici con uv
cd backend
uv run pytest tests/ -v
```

### Test Remoti
```bash
# Test API deployata su EC2
make test-remote

# Test manuale
curl http://YOUR_EC2_IP:8000/health
```

## 📊 Monitoring e Logs

### Logs Locali
```bash
# Visualizza logs container locale
make backend-logs

# Logs specifici
cd backend
docker compose logs -f simple-backend
```

### Logs Remoti
```bash
# Visualizza logs container su EC2
make logs

# SSH nell'istanza
make ssh

# Logs direttamente su EC2
docker logs simple-backend -f
```

## 🔒 Security Features

- **Container non-root**: App gira con utente dedicato
- **Health checks**: Monitoraggio automatico container
- **Environment variables**: Configurazione sicura
- **SSH keys sicure**: Non memorizzate in Terraform state
- **Logging strutturato**: Tracciabilità completa

## 🌍 Environment Variables

Il backend utilizza le seguenti variabili (vedi `.env.example`):

```bash
# Application
APP_NAME=Simple Backend
APP_VERSION=1.0.0
ENVIRONMENT=production
DEBUG=false

# Server
HOST=0.0.0.0
PORT=8000

# Logging
LOG_LEVEL=INFO
LOG_ROTATION=10 MB
LOG_RETENTION=30 days
```

## 🐳 Docker

### Immagini
- **Base**: `ghcr.io/astral-sh/uv:python3.13-bookworm-slim`
- **Multi-stage build**: Ottimizzazione dimensioni
- **Health check**: Endpoint `/health` ogni 30s

### Comandi Docker
```bash
# Build immagine
make backend-build

# Avvia con Docker Compose
cd backend
docker compose up -d

# Logs
docker compose logs -f

# Stop
docker compose down
```

## 🔄 CI/CD Integration

Il backend è progettato per integrarsi facilmente con sistemi CI/CD:

1. **Build**: `docker build -t backend .`
2. **Test**: `uv run pytest`
3. **Deploy**: `./deploy.sh` (richiede Terraform output)

## 📈 Performance

### Optimizations
- **uv**: Package manager 10-100x più veloce di pip
- **FastAPI**: Framework async ad alte performance
- **Multi-stage Docker**: Immagini leggere
- **Health checks**: Restart automatico su failure

### Monitoring
- **Loguru**: Logging strutturato con rotazione
- **Health endpoint**: Status applicazione
- **Docker stats**: Monitoraggio risorse

## 🛠️ Troubleshooting

### Problemi Comuni

**Backend non risponde localmente:**
```bash
# Verifica container
docker ps
make backend-logs

# Riavvia
make backend-stop
make backend-dev
```

**Deploy fallisce:**
```bash
# Verifica infrastruttura
make status

# Verifica SSH keys
make infra-ssh-keys

# Deploy manuale
cd backend && ./deploy.sh
```

**Logs non visibili:**
```bash
# Verifica mount volumes
cd backend
docker compose config

# Accesso diretto EC2
make ssh
docker logs simple-backend
```

## 🔗 Links Utili

- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **uv Package Manager**: https://github.com/astral-sh/uv
- **Loguru**: https://loguru.readthedocs.io/
- **Docker Best Practices**: https://docs.docker.com/develop/dev-best-practices/

## 📝 Note di Sviluppo

### Struttura Codice
- **Separazione responsabilità**: Endpoint, modelli, business logic
- **Type hints**: Completa tipizzazione Python
- **Async/await**: Gestione asincrona richieste
- **Error handling**: Gestione errori strutturata

### Best Practices Seguite
- **12-Factor App**: Configurazione via environment
- **Container Security**: Non-root user, minimal image
- **Logging**: Structured logging con context
- **Health Checks**: Monitoring e auto-recovery

---

Per comandi completi e deployment, consulta il **README principale** del progetto. 