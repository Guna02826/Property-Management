# Development Setup Guide
## Enterprise Multi-Floor Commercial Office Leasing Platform

**Version:** 1.0  
**Date:** 2025-01-27

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Local Development Setup](#2-local-development-setup)
3. [Environment Configuration](#3-environment-configuration)
4. [Database Setup](#4-database-setup)
5. [Running the Application](#5-running-the-application)
6. [Development Workflow](#6-development-workflow)
7. [Common Tasks](#7-common-tasks)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

### Required Software

- **Node.js:** Version 18+ LTS ([Download](https://nodejs.org/))
- **PostgreSQL:** Version 14+ ([Download](https://www.postgresql.org/download/))
- **Redis:** Version 6+ ([Download](https://redis.io/download))
- **Git:** Latest version ([Download](https://git-scm.com/downloads))
- **Docker:** (Optional) For containerized development ([Download](https://www.docker.com/))

### Recommended Tools

- **VS Code:** With extensions:
  - ESLint
  - Prettier
  - Prisma (if using Prisma ORM)
  - Docker
- **Postman/Insomnia:** For API testing
- **DBeaver/pgAdmin:** For database management
- **Redis Insight:** For Redis management

---

## 2. Local Development Setup

### 2.1 Clone Repository

```bash
git clone <repository-url>
cd property-manager
```

### 2.2 Install Dependencies

```bash
# Install Node.js dependencies
npm install

# Or using yarn
yarn install
```

### 2.3 Install Global Tools (Optional)

```bash
# Prisma CLI (if using Prisma)
npm install -g prisma

# TypeORM CLI (if using TypeORM)
npm install -g typeorm
```

---

## 3. Environment Configuration

### 3.1 Create Environment File

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your local configuration
```

### 3.2 Required Environment Variables

See [ENV-VARIABLES.md](./ENV-VARIABLES.md) for complete list. Minimum required:

```env
# Application
NODE_ENV=development
PORT=3000
API_VERSION=v1

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/property_manager_dev
DB_HOST=localhost
DB_PORT=5432
DB_NAME=property_manager_dev
DB_USER=postgres
DB_PASSWORD=your_password

# Redis
REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRES_IN=24h
JWT_REFRESH_SECRET=your-refresh-secret-key
JWT_REFRESH_EXPIRES_IN=30d

# Object Storage (AWS S3 example)
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
AWS_S3_BUCKET=property-manager-dev

# Email Service (SendGrid example)
SENDGRID_API_KEY=your-sendgrid-api-key
EMAIL_FROM=noreply@example.com

# External APIs
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
WHATSAPP_API_KEY=your-whatsapp-api-key
```

---

## 4. Database Setup

### 4.1 Create Database

```bash
# Using PostgreSQL CLI
createdb property_manager_dev

# Or using psql
psql -U postgres
CREATE DATABASE property_manager_dev;
\q
```

### 4.2 Run Migrations

```bash
# Using Prisma
npx prisma migrate dev

# Using TypeORM
npm run migration:run

# Or custom migration script
npm run migrate
```

### 4.3 Seed Database (Optional)

```bash
# Seed with sample data
npm run seed

# Or using Prisma
npx prisma db seed
```

### 4.4 Verify Database Connection

```bash
# Test database connection
npm run db:test

# Or using Prisma Studio
npx prisma studio
```

---

## 5. Running the Application

### 5.1 Start Redis

```bash
# Using Docker
docker run -d -p 6379:6379 redis:6-alpine

# Or using local Redis installation
redis-server
```

### 5.2 Start Development Server

```bash
# Start all services (API + WebSocket)
npm run dev

# Start API only
npm run dev:api

# Start WebSocket server only
npm run dev:ws

# Start with hot reload
npm run dev:watch
```

### 5.3 Verify Application

- **API:** http://localhost:3000/api/v1/health
- **WebSocket:** ws://localhost:3001
- **API Documentation:** http://localhost:3000/api-docs

---

## 6. Development Workflow

### 6.1 Branch Strategy

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Create bugfix branch
git checkout -b bugfix/your-bugfix-name

# Create hotfix branch
git checkout -b hotfix/your-hotfix-name
```

### 6.2 Code Standards

- Follow [CONTRIBUTING.md](./CONTRIBUTING.md) for coding standards
- Run linter before committing: `npm run lint`
- Format code: `npm run format`
- Write tests for new features

### 6.3 Commit Messages

Follow conventional commits:
```
feat: add user authentication
fix: resolve payment calculation bug
docs: update API documentation
test: add unit tests for bid service
refactor: improve error handling
```

### 6.4 Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- path/to/test/file.test.ts
```

---

## 7. Common Tasks

### 7.1 Database Migrations

```bash
# Create new migration
npm run migrate:create -- --name migration_name

# Run migrations
npm run migrate

# Rollback last migration
npm run migrate:undo

# Check migration status
npm run migrate:status
```

### 7.2 Generate API Client

```bash
# Generate TypeScript client from OpenAPI spec
npm run generate:client

# Update API documentation
npm run docs:generate
```

### 7.3 Code Generation

```bash
# Generate Prisma client (if using Prisma)
npx prisma generate

# Generate TypeORM entities (if using TypeORM)
npm run generate:entities
```

### 7.4 Debugging

```bash
# Start with debugger
npm run dev:debug

# VS Code: Use launch.json configuration
# Attach debugger to running process
```

---

## 8. Troubleshooting

### 8.1 Common Issues

#### Database Connection Error

```bash
# Check PostgreSQL is running
pg_isready

# Check connection string
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL -c "SELECT 1"
```

#### Redis Connection Error

```bash
# Check Redis is running
redis-cli ping

# Should return: PONG

# Check Redis connection
redis-cli -h localhost -p 6379
```

#### Port Already in Use

```bash
# Find process using port 3000
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

#### Migration Errors

```bash
# Reset database (WARNING: Deletes all data)
npm run migrate:reset

# Or manually drop and recreate
dropdb property_manager_dev
createdb property_manager_dev
npm run migrate
```

### 8.2 Environment Issues

```bash
# Verify environment variables are loaded
npm run env:check

# Reload environment
source .env  # Linux/macOS
# Windows: Restart terminal
```

### 8.3 Dependency Issues

```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Update dependencies
npm update
```

### 8.4 TypeScript Errors

```bash
# Check TypeScript configuration
npx tsc --noEmit

# Regenerate type definitions
npm run types:generate
```

---

## 9. Development Tips

### 9.1 Hot Reload

- Frontend: Next.js hot reload is enabled by default
- Backend: Use `nodemon` or `ts-node-dev` for hot reload
- Database: Use Prisma Studio or DBeaver for real-time data viewing

### 9.2 API Testing

```bash
# Start server
npm run dev

# In another terminal, test endpoints
curl http://localhost:3000/api/v1/health

# Or use Postman collection
# Import from docs/postman-collection.json
```

### 9.3 Database Queries

```bash
# Using Prisma Studio
npx prisma studio

# Using psql
psql $DATABASE_URL

# Using custom script
npm run db:query -- "SELECT * FROM users LIMIT 10"
```

### 9.4 Logging

- Development logs: Console output
- Structured logs: Check `logs/` directory
- Debug mode: Set `LOG_LEVEL=debug` in `.env`

---

## 10. Next Steps

1. Read [API Documentation](./API-Documentation.md)
2. Review [Database Schema](./Database-Schema.md)
3. Check [Testing Strategy](./Testing-Strategy.md)
4. Follow [Contributing Guidelines](./CONTRIBUTING.md)

---

**Need Help?**
- Check [Troubleshooting](#8-troubleshooting) section
- Review [Error Codes](./ERROR-CODES.md)
- Contact development team
- Create an issue in repository

