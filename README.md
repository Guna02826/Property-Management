# Enterprise Multi-Floor Commercial Office Leasing Platform

A cloud-based SaaS platform for managing multi-floor commercial office space leasing, renting, and sales. The system serves property owners, brokers, tenants, property managers, and administrators.

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd property-manager

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Run database migrations
npm run migrate

# Start development server
npm run dev
```

## 📋 Project Overview

This platform streamlines commercial real estate transactions from space discovery to contract execution, featuring:

- **Real-time Bidding System** with WebSocket notifications
- **AI-Powered Recommendations** for pricing and space suggestions
- **Automated Lease Generation** from approved bids
- **Multi-Building Management** with floor and space tracking
- **Payment Schedule Tracking** and invoicing
- **Advanced Analytics Dashboards** with occupancy heatmaps
- **Multi-Channel Notifications** (email, WhatsApp, push, in-app)

## 📚 Documentation

### Core Documentation
- **[SRS (Software Requirements Specification)](./Requirements/SRS-Complete.md)** - Complete requirements and specifications
- **[Technical Implementation Details](./Requirements/Technical-Implementation-Details.md)** - Technical architecture and implementation guide

### Architecture Documentation
- **[MVC Architecture](./Architecture/MVC-Architecture.md)** - MVC patterns and implementation guidelines
- **[Application Workflow](./Architecture/Application-Workflow.md)** - End-to-end workflow documentation

### Development Documentation
- **[Development Setup Guide](./Documentation/DEVELOPMENT.md)** - Local development environment setup
- **[Development Rules](./Documentation/DEVELOPMENT-RULES.md)** - Single source of truth for coding and development rules
- **[API Documentation](./Documentation/API-Documentation.md)** - Complete API reference
- **[Database Schema](./Documentation/Database-Schema.md)** - Database structure and relationships
- **[Testing Strategy](./Documentation/Testing-Strategy.md)** - Testing approach and guidelines
- **[Deployment Guide](./Documentation/DEPLOYMENT.md)** - Production deployment instructions

### Reference Documentation
- **[Environment Variables](./Documentation/ENV-VARIABLES.md)** - Configuration reference
- **[Error Codes](./Documentation/ERROR-CODES.md)** - Error code reference
- **[Contributing Guidelines](./Documentation/CONTRIBUTING.md)** - Development workflow and standards

### User Documentation
- **[User Guide](./Documentation/USER-GUIDE.md)** - End-user manual

## 🏗️ Architecture

### Technology Stack

**Frontend:**
- React 18+ with Next.js 14+ (App Router)
- TypeScript 5.0+
- TailwindCSS + shadcn/ui

**Backend:**
- Node.js 18+ LTS
- Fastify 4+ (REST API)
- TypeScript 5.0+

**Database:**
- PostgreSQL 14+ (Primary)
- Redis 6+ (Cache & Sessions)
- MongoDB 6+ (Analytics, Phase 3)

**Infrastructure:**
- Docker containers
- Cloud Run / ECS Fargate (Phase 1)
- Kubernetes (Phase 2+)

## 📁 Project Structure

```
property-manager/
├── README.md                    # Project overview and quick start
├── Architecture/                # Architecture and design documents
│   ├── MVC-Architecture.md      # MVC architecture patterns
│   └── Application-Workflow.md  # End-to-end workflow documentation
├── Requirements/                 # Official requirements documents
│   ├── SRS-Complete.md          # Software Requirements Specification
│   └── Technical-Implementation-Details.md  # Technical specifications
├── Documentation/               # Development and reference documentation
│   ├── Documentation-Index.md   # Complete documentation index
│   ├── DEVELOPMENT.md           # Development setup guide
│   ├── API-Documentation.md     # Complete API reference
│   ├── Database-Schema.md       # Database structure
│   ├── Testing-Strategy.md      # Testing guidelines
│   ├── DEPLOYMENT.md            # Deployment instructions
│   ├── ENV-VARIABLES.md         # Environment variables
│   ├── ERROR-CODES.md           # Error code reference
│   ├── CONTRIBUTING.md          # Contribution guidelines
│   └── USER-GUIDE.md            # End-user manual
├── Archive/                     # Old/deprecated documents
│   ├── Software-Requirements.md
│   ├── Software-Requirements-Specification.md
│   ├── SRS-Enterprise-Platform.md
│   └── Everything.txt
├── src/                         # Source code (to be created)
│   ├── api/                     # API routes and controllers
│   ├── services/                # Business logic services
│   ├── models/                  # Database models
│   ├── middleware/              # Express/Fastify middleware
│   ├── utils/                   # Utility functions
│   └── types/                   # TypeScript type definitions
├── tests/                       # Test files (to be created)
└── migrations/                  # Database migrations (to be created)
```

## 🔧 Development

### Prerequisites

- Node.js 18+ LTS
- PostgreSQL 14+
- Redis 6+
- Docker (optional, for containerized development)

### Available Scripts

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run test         # Run tests
npm run test:watch   # Run tests in watch mode
npm run lint         # Run linter
npm run migrate      # Run database migrations
npm run migrate:undo # Rollback last migration
```

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run integration tests
npm run test:integration

# Run E2E tests
npm run test:e2e
```

## 🚢 Deployment

See [Deployment Guide](./Documentation/DEPLOYMENT.md) for detailed deployment instructions.

**Quick Deploy:**
```bash
# Build Docker image
docker build -t property-manager .

# Run container
docker run -p 3000:3000 --env-file .env property-manager
```

## 🔐 Security

- All data encrypted at rest (AES-256)
- TLS 1.3 for data in transit
- JWT-based authentication
- Role-based access control (RBAC)
- Rate limiting on all endpoints
- Input validation and sanitization

## 📊 Performance Targets

- API Response Time: < 500ms (95th percentile)
- Page Load Time: < 2 seconds (95th percentile)
- Search Results: < 1 second
- Real-time Updates: < 100ms latency
- Supports 100,000+ concurrent users
- Handles 10,000+ transactions per minute

## 🤝 Contributing

Please read [CONTRIBUTING.md](./Documentation/CONTRIBUTING.md) for development workflow, coding standards, and pull request process.

## 📝 License

[Specify your license here]

## 👥 Team

- Development Team
- Product Management
- QA Team
- DevOps Team

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Contact the development team
- Refer to [User Guide](./Documentation/USER-GUIDE.md) for end-user support

## 🔗 Related Links

- [API Documentation](./Documentation/API-Documentation.md)
- [Database Schema](./Documentation/Database-Schema.md)
- [Environment Variables](./Documentation/ENV-VARIABLES.md)
- [Error Codes](./Documentation/ERROR-CODES.md)

---

**Version:** 1.0  
**Last Updated:** 2025-01-27

