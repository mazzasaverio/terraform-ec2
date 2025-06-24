# FastAPI Backend

Backend FastAPI con uv, containerizzato con Docker. Include autenticazione JWT e reverse proxy nginx.

## Struttura

```
backend/
├── src/
│   ├── main.py          # FastAPI app
│   └── utils/           # Logging manager + Auth
├── tests/
│   └── test_api.py      # Test suite
├── logs/                # Log files
├── nginx.conf           # Nginx reverse proxy
├── pyproject.toml       # uv config
└── Dockerfile
```

## API Endpoints

### Pubblici
- `GET /` - Info sistema
- `GET /health` - Health check

### Autenticazione
- `POST /auth/login` - Login (username/password → JWT token)
- `GET /auth/me` - Info utente corrente

### Protetti (richiedono JWT)
- `GET /messages` - Lista messaggi
- `POST /messages` - Crea messaggio
- `GET /messages/{id}` - Ottieni messaggio
- `DELETE /messages/{id}` - Elimina messaggio

## Autenticazione

### Utenti di default
- **admin** / admin123 (role: admin)
- **user** / user123 (role: user)

### Uso con curl
```bash
# Login
TOKEN=$(curl -X POST "http://localhost/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" | jq -r .access_token)

# API call con token
curl -H "Authorization: Bearer $TOKEN" http://localhost/messages
```

## Sviluppo Locale

Dal root del progetto:

```bash
# Avvia backend
make backend-dev

# Test
make test-local

# Logs
make backend-logs

# Stop
make backend-stop
```

API disponibile su http://localhost:8000

### Con uv

```bash
cd backend
uv sync
uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
uv run pytest tests/ -v
```

## Deploy con Nginx

Il deploy include nginx come reverse proxy:

```bash
# Dal root del progetto
make deploy-backend
```

Nginx fornisce:
- Rate limiting (10 req/s)
- Security headers
- CORS handling
- Proxy verso FastAPI (porta 8000) 