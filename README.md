# Outline Knowledge Base

A self-hosted team wiki and knowledge base built with Outline, deployed using Docker Compose with PostgreSQL and Redis.

## Overview

This project sets up a complete Outline wiki instance with:
- **Outline**: Team wiki and documentation platform
- **PostgreSQL**: Database for storing wiki content
- **Redis**: Caching and session storage
- **Ngrok**: Public HTTPS tunnel for development

## Prerequisites

- Docker and Docker Compose
- Ngrok account (for public access)
- Slack app (for authentication)

## Quick Start

1. **Clone and setup**
   ```bash
   git clone <your-repo>
   cd docker-outline-knowledge-base
   ```

2. **Configure environment**
   ```bash
   cp docker.env.example docker.env
   # Edit docker.env with your settings
   ```

3. **Start services**
   ```bash
   docker-compose up -d
   ```

4. **Access Outline**
   - Local: http://localhost:3000
   - Public: https://nonturbinate-johnnie-unmarketed.ngrok-free.dev

## Configuration

### Environment Variables (`docker.env`)

#### Basic Settings
```env
NODE_ENV=production
URL=https://your-domain.com
PORT=3000
SECRET_KEY=your-secret-key-here
UTILS_SECRET=your-utils-secret-here
```

#### Database Configuration
```env
DATABASE_URL=postgres://user:pass@postgres:5432/outline
POSTGRES_USER=user
POSTGRES_PASSWORD=pass
POSTGRES_DB=outline
```

#### Redis Configuration
```env
REDIS_URL=redis://redis:6379
```

#### Slack Integration
```env
SLACK_CLIENT_ID=your-slack-client-id
SLACK_CLIENT_SECRET=your-slack-client-secret
```

#### File Storage (Optional)
```env
# AWS S3
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
AWS_S3_UPLOAD_BUCKET_NAME=your-bucket

# Local storage (default)
FILE_STORAGE=local
FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data
```

#### Email Configuration (Optional)
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=your-email@gmail.com
SMTP_REPLY_EMAIL=your-email@gmail.com
```

## Slack Integration Setup

### 1. Create Slack App

1. Go to https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. Name your app and select workspace

### 2. Configure OAuth & Permissions

1. Go to "OAuth & Permissions"
2. Add redirect URL:
   ```
   https://your-domain.com/auth/slack.callback
   ```
3. Add Bot Token Scopes:
   - `users:read`
   - `users:read.email`
   - `team:read`

### 3. Get Credentials

1. Copy "Client ID" and "Client Secret"
2. Add to `docker.env`:
   ```env
   SLACK_CLIENT_ID=your-client-id
   SLACK_CLIENT_SECRET=your-client-secret
   ```

## Docker Services

### Outline Application
- **Image**: `docker.getoutline.com/outlinewiki/outline:latest`
- **Port**: 3000
- **Volumes**: `storage-data:/var/lib/outline/data`

### PostgreSQL Database
- **Image**: `postgres:alpine`
- **Port**: 5432
- **Volume**: `database-data:/var/lib/postgresql/data`
- **Health Check**: `pg_isready`

### Redis Cache
- **Image**: `redis:alpine`
- **Port**: 6379
- **Config**: Custom `redis.conf`
- **Health Check**: `redis-cli ping`

### Ngrok Tunnel
- **Image**: `ngrok/ngrok:latest`
- **Domain**: `nonturbinate-johnnie-unmarketed.ngrok-free.dev`
- **Auth Token**: Required for custom domains

## Installation Methods

### Local Development
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f outline

# Stop services
docker-compose down
```

### Production Deployment

#### Option 1: Render
1. Push to GitHub
2. Create Web Service on Render
3. Add PostgreSQL and Redis add-ons
4. Set environment variables
5. Deploy

#### Option 2: Railway
1. Connect GitHub repo to Railway
2. Add PostgreSQL and Redis services
3. Configure environment variables
4. Deploy

#### Option 3: Fly.io
```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Deploy
fly launch
fly postgres create
fly redis create
fly deploy
```

## File Structure

```
docker-outline-knowledge-base/
├── docker-compose.yml      # Main service configuration
├── docker.env             # Environment variables
├── redis.conf/            # Redis configuration
├── Dockerfile.outline     # Custom Outline image
├── render.yaml           # Render deployment config
├── fly.toml              # Fly.io deployment config
└── README.md             # This file
```

## Troubleshooting

### Common Issues

**Memory errors on deployment**
```bash
# Add to Dockerfile
ENV NODE_OPTIONS="--max-old-space-size=1024"
```

**Database connection failed**
```bash
# Check database is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres
```

**Slack redirect URI mismatch**
1. Update Slack app redirect URI
2. Match exactly with your domain
3. Include `/auth/slack.callback` path

**File upload issues**
```bash
# Check volume permissions
docker-compose exec outline ls -la /var/lib/outline/data

# Or use S3 storage instead
```

### Useful Commands

```bash
# Reset database
docker-compose down -v
docker-compose up -d

# Backup database
docker-compose exec postgres pg_dump -U user outline > backup.sql

# Restore database
docker-compose exec -T postgres psql -U user outline < backup.sql

# View real-time logs
docker-compose logs -f

# Update images
docker-compose pull
docker-compose up -d
```

## Security Considerations

1. **Change default passwords** in `docker.env`
2. **Use strong SECRET_KEY** (generate with `openssl rand -hex 32`)
3. **Enable HTTPS** in production
4. **Restrict database access** to application only
5. **Regular backups** of database and files
6. **Update images** regularly for security patches

## Performance Optimization

1. **Redis caching** - Enabled by default
2. **Database indexing** - Handled by Outline
3. **File storage** - Use S3 for better performance
4. **Memory limits** - Adjust based on usage
5. **Load balancing** - Use reverse proxy for multiple instances

## Support

- **Outline Documentation**: https://docs.getoutline.com
- **Docker Compose Reference**: https://docs.docker.com/compose/
- **Slack API Documentation**: https://api.slack.com/docs

## License

This project configuration is open source. Outline itself is licensed under BSL 1.1.
