# Simple Backend with Neon PostgreSQL

A FastAPI backend application with Neon PostgreSQL database integration.

## Features

- FastAPI REST API
- Neon PostgreSQL database with SQLAlchemy ORM
- Async database operations
- JWT authentication
- S3 file storage
- Comprehensive logging
- Database migrations with Alembic
- Docker support
- Comprehensive testing

## Database Setup

This backend uses **Neon PostgreSQL** for both development and production environments:

- **Development Database** - For local development and testing
- **Production Database** - For production deployment

## Quick Start

### Prerequisites

- Python 3.13+
- Docker (optional)
- Neon PostgreSQL account

### Neon PostgreSQL Setup

1. **Create a Neon account** at [neon.tech](https://neon.tech)

2. **Create two databases:**
   - One for development (e.g., `simple_backend_dev`)
   - One for production (e.g., `simple_backend_prod`)

3. **Get your connection strings** from the Neon dashboard

4. **Configure environment:**
   ```bash
   cd backend
   cp env.example .env
   ```

5. **Edit `.env` file:**
   ```env
   # Development Database
   NEON_DEV_DATABASE_URL=postgresql+asyncpg://username:password@host:port/dev_database?sslmode=require
   
   # Production Database
   NEON_PROD_DATABASE_URL=postgresql+asyncpg://username:password@host:port/prod_database?sslmode=require
   
   # Application settings
   DEBUG=true
   LOG_LEVEL=INFO
   SECRET_KEY=your-secret-key-here
   ```

6. **Setup databases:**
   ```bash
   ./scripts/setup-neon.sh
   ```

### Local Development

1. **Install dependencies:**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -e .
   ```

2. **Run the application:**
   ```bash
   python -m uvicorn src.main:app --reload
   ```

The API will be available at `http://localhost:8000`

### Docker Development

```bash
# Start development environment
docker-compose up --build

# Run tests
./scripts/test-docker.sh
```

### Docker Production

```bash
# Start production environment
docker-compose -f docker-compose.prod.yml up --build
```

## Testing

### Local Testing

```bash
# Run tests
python -m pytest tests/ -v
```

### Docker Testing

```bash
# Run tests with Docker
./scripts/test-docker.sh
```

## Database Migrations

### Create a new migration:
```bash
alembic revision --autogenerate -m "Description of changes"
```

### Apply migrations to development:
```bash
DATABASE_URL="$NEON_DEV_DATABASE_URL" alembic upgrade head
```

### Apply migrations to production:
```bash
DATABASE_URL="$NEON_PROD_DATABASE_URL" alembic upgrade head
```

### Rollback migrations:
```bash
alembic downgrade -1
```

## API Endpoints

### Authentication
- `POST /auth/login` - Login and get JWT token
- `GET /auth/me` - Get current user info

### Messages
- `GET /messages` - List all messages
- `POST /messages` - Create a new message
- `GET /messages/{id}` - Get message by ID
- `DELETE /messages/{id}` - Delete message

### S3 Operations
- `GET /s3/files` - List S3 files
- `POST /s3/upload` - Upload file to S3
- `GET /s3/download/{key}` - Download file from S3
- `DELETE /s3/files/{key}` - Delete file from S3

### Health Checks
- `GET /health` - Application health check
- `GET /s3/health` - S3 service health check

## Sample User

After running the setup script, a sample user is created:

- **Username:** `admin`
- **Password:** `admin123`

## Testing on Virtual Machine

To test the backend on your EC2 virtual machine:

1. **SSH into your VM:**
   ```bash
   ssh -i your-key.pem ubuntu@your-vm-ip
   ```

2. **Install dependencies:**
   ```bash
   sudo apt update
   sudo apt install python3 python3-pip python3-venv docker.io docker-compose
   ```

3. **Deploy the backend:**
   ```bash
   cd /path/to/your/project/backend
   cp env.example .env
   # Edit .env with your Neon database URLs
   ./scripts/setup-neon.sh
   ```

4. **Run with Docker:**
   ```bash
   # Development
   docker-compose up --build
   
   # Production
   docker-compose -f docker-compose.prod.yml up --build
   ```

5. **Configure firewall:**
   ```bash
   sudo ufw allow 80
   sudo ufw allow 443
   ```

The API will be available at `http://your-vm-ip`

## Troubleshooting

### Database Connection Issues
- Verify Neon database URLs in `.env` file
- Check if databases exist in Neon dashboard
- Test connection: `./scripts/setup-neon.sh`

### Migration Issues
- Reset database: `alembic downgrade base && alembic upgrade head`
- Check migration history: `alembic history`

### Docker Issues
- Rebuild containers: `docker-compose build --no-cache`
- Check logs: `docker-compose logs backend`

### Permission Issues
- Check file permissions: `chmod +x scripts/*.sh`
- Ensure Docker is running: `sudo systemctl status docker` 