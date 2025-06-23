# Simple FastAPI Backend

Un backend semplificato con FastAPI per testare endpoint di base.

## 🚀 Struttura

```
backend/
├── src/
│   ├── __init__.py
│   └── main.py           # App FastAPI con endpoint
├── tests/
│   ├── __init__.py
│   └── test_api.py       # Test per gli endpoint
├── Dockerfile
├── docker-compose.yml    # Per sviluppo locale
├── docker-compose.prod.yml  # Per produzione
├── deploy.sh             # Script di deploy su EC2
├── pyproject.toml        # Dipendenze uv
└── README.md
```

## 📋 Endpoint Disponibili

- `GET /` - Info API
- `GET /health` - Health check
- `POST /messages` - Crea un messaggio
- `GET /messages/{id}` - Ottieni un messaggio
- `GET /messages` - Lista tutti i messaggi
- `DELETE /messages/{id}` - Elimina un messaggio

## 🧪 Test Locali

```bash
# 1. Sviluppo con hot reload
cd backend
docker compose up -d

# 2. Test dell'API
curl http://localhost:8000/
curl http://localhost:8000/health

# 3. Crea un messaggio
curl -X POST http://localhost:8000/messages \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello World","user_id":"test"}'

# 4. Lista messaggi
curl http://localhost:8000/messages

# 5. Ottieni messaggio specifico
curl http://localhost:8000/messages/1
```

## 🧪 Test Unitari

```bash
cd backend
uv run pytest tests/ -v
```

## 🚀 Deploy su EC2

```bash
# Prerequisiti: Infrastructure deployata
cd infrastructure
make apply

# Deploy del backend
cd ../backend
./deploy.sh
```

Il deploy automaticamente:
1. Builda l'immagine Docker
2. La trasferisce su EC2
3. Avvia il container
4. Mostra URL per i test

## 📖 Docs

Una volta avviato, le docs sono disponibili su:
- Local: http://localhost:8000/docs
- EC2: http://YOUR_EC2_IP:8000/docs

## 🔧 Tecnologie

- **FastAPI** - Framework web
- **Logfire** - Logging e monitoring
- **uv** - Package manager
- **Docker** - Containerizzazione
- **pytest** - Testing 