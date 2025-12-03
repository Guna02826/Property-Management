# Technical Implementation Details
## Enterprise Multi-Floor Commercial Office Leasing Platform

**Version:** 1.0  
**Date:** 2025-01-27  
**Document Type:** Technical Specification  
**Related Document:** SRS-Complete.md

---

## Table of Contents

1. [Technology Stack](#1-technology-stack)
2. [Database Schema](#2-database-schema)
3. [API Specifications](#3-api-specifications)
4. [WebSocket Events](#4-websocket-events)
5. [Caching Strategy](#5-caching-strategy)
6. [Security Implementation](#6-security-implementation)
7. [Deployment Architecture](#7-deployment-architecture)
8. [Monitoring & Observability](#8-monitoring--observability)
9. [Data Migration Strategy](#9-data-migration-strategy)
10. [Integration Patterns](#10-integration-patterns)

---

## 1. Technology Stack

### 1.1 Frontend

#### Web Application
- **Framework:** React 18+ with Next.js 14+ (App Router)
- **Language:** TypeScript 5.0+
- **UI Framework:** TailwindCSS 3.4+, shadcn/ui components
- **State Management:** Zustand or Redux Toolkit
- **Form Handling:** React Hook Form with Zod validation
- **Real-time:** Socket.io-client for WebSocket connections
- **Maps:** Google Maps API or Mapbox GL JS
- **AR/VR:** Three.js, A-Frame (Phase 4)
- **Charts:** Recharts or Chart.js for analytics
- **Date Handling:** date-fns or Day.js

#### Mobile Application
- **Framework:** React Native 0.72+ or Flutter 3.0+ (cross-platform)
- **Navigation:** React Navigation (React Native) or Flutter Navigator
- **State Management:** Redux Toolkit or Provider (Flutter)
- **Maps:** react-native-maps or Google Maps SDK
- **Push Notifications:** Firebase Cloud Messaging (FCM) or OneSignal
- **Biometric Auth:** react-native-biometrics or local_auth (Flutter)

### 1.2 Backend

#### Core Services
- **Runtime:** Node.js 18+ LTS
- **Framework:** Fastify 4+ (REST API)
- **Language:** TypeScript 5.0+
- **WebSocket:** Socket.io or native WebSocket server
- **GraphQL:** Apollo Server (optional, Phase 3)
- **Validation:** Zod for schema validation
- **Documentation:** OpenAPI 3.0/Swagger with fastify-swagger

#### Authentication & Authorization
- **JWT:** jsonwebtoken library
- **OAuth2:** Passport.js with Google/LinkedIn strategies
- **Biometric:** Platform-specific APIs (FaceID/TouchID)
- **2FA:** speakeasy for TOTP generation
- **Password Hashing:** bcrypt (cost factor 12)

#### Background Jobs
- **Queue:** BullMQ or Bull (Redis-based)
- **Scheduling:** node-cron or BullMQ cron jobs
- **Email:** nodemailer with SendGrid/SES transport
- **PDF Generation:** pdfkit or puppeteer

### 1.3 Database & Storage

#### Primary Database
- **PostgreSQL:** Version 14+ (managed: Cloud SQL, RDS, Azure Database)
- **ORM:** Prisma or TypeORM
- **Migrations:** Prisma Migrate or TypeORM migrations
- **Connection Pooling:** pgBouncer or built-in pooler

#### Caching & Session Storage
- **Redis:** Version 6+ (managed: ElastiCache, Memorystore, Azure Cache)
- **Use Cases:** Session storage, query caching, rate limiting, real-time data

#### Analytics Database (Optional)
- **MongoDB:** Version 6+ (for analytics aggregation, Phase 3)
- **Time-Series:** InfluxDB or TimescaleDB (for IoT data, Phase 4)

#### Object Storage
- **Provider:** AWS S3, Google Cloud Storage, or Azure Blob Storage
- **CDN:** CloudFront, Cloudflare, or Cloud CDN
- **File Types:** Images, videos, 3D models, PDFs (lease documents)

### 1.4 Infrastructure

#### Container & Orchestration
- **Container Runtime:** Docker containers
- **Orchestration:** Google Cloud Run, AWS ECS/Fargate, or Azure Container Apps (Phase 1)
- **Kubernetes:** GKE, EKS, or AKS (Phase 2+)
- **Service Mesh:** Istio or Linkerd (Phase 3+)

#### Message Queue & Event Streaming
- **Message Queue:** RabbitMQ or AWS SQS (async processing)
- **Event Bus:** Apache Kafka (Phase 3+ for event streaming)
- **Pub/Sub:** Google Pub/Sub, AWS SNS/SQS, or Azure Service Bus

#### Monitoring & Logging
- **APM:** Datadog, New Relic, or Elastic APM
- **Metrics:** Prometheus + Grafana
- **Logging:** ELK Stack (Elasticsearch, Logstash, Kibana) or CloudWatch
- **Tracing:** Jaeger or Zipkin for distributed tracing

### 1.5 AI/ML Services

#### Core ML Stack
- **Language:** Python 3.10+
- **Frameworks:** TensorFlow 2.x or PyTorch 2.0+
- **ML Libraries:** scikit-learn, pandas, numpy
- **Cloud ML:** AWS SageMaker, GCP Vertex AI, or Azure ML

#### Vector Database (Phase 3)
- **Provider:** Pinecone, Weaviate, or Qdrant
- **Use Case:** Similarity search for space recommendations

#### ML Models
- **Pricing Suggestions:** Regression models (XGBoost, Random Forest)
- **Space Recommendations:** Collaborative filtering + content-based
- **Occupancy Forecasting:** Time series models (LSTM, Prophet)
- **Bid Success Probability:** Classification models (Logistic Regression, Neural Networks)

---

## 2. Database Schema

### 2.1 Core Tables

#### users
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('SUPER_ADMIN', 'OWNER', 'CLIENT', 'BROKER', 'AGENT', 'SUPPORT')),
    email_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    last_login_at TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_created_at ON users(created_at);
```

#### buildings
```sql
CREATE TABLE buildings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    name VARCHAR(255) NOT NULL,
    address JSONB NOT NULL, -- {street, city, state, country, postal_code}
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    total_floors INTEGER NOT NULL CHECK (total_floors > 0),
    amenities JSONB, -- Array of strings
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE INDEX idx_buildings_owner_id ON buildings(owner_id);
CREATE INDEX idx_buildings_location ON buildings USING GIST (ll_to_earth(latitude, longitude));
CREATE INDEX idx_buildings_created_at ON buildings(created_at);
```

#### floors
```sql
CREATE TABLE floors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id UUID REFERENCES buildings(id) ON DELETE CASCADE NOT NULL,
    floor_number INTEGER NOT NULL,
    total_sqft DECIMAL(10, 2),
    common_area_sqft DECIMAL(10, 2) DEFAULT 0,
    net_leasable_sqft DECIMAL(10, 2) GENERATED ALWAYS AS (total_sqft - common_area_sqft) STORED,
    amenities JSONB,
    floor_plan_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    UNIQUE(building_id, floor_number)
);

CREATE INDEX idx_floors_building_id ON floors(building_id);
CREATE INDEX idx_floors_building_floor ON floors(building_id, floor_number);
```

#### spaces
```sql
CREATE TABLE spaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    floor_id UUID REFERENCES floors(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL,
    gross_sqft DECIMAL(10, 2) NOT NULL,
    usable_sqft DECIMAL(10, 2) NOT NULL,
    usage_type VARCHAR(20) NOT NULL CHECK (usage_type IN ('OFFICE', 'CANTEEN', 'RESTROOM', 'STORAGE', 'CORRIDOR', 'JANITOR', 'OTHER')),
    is_leasable BOOLEAN DEFAULT TRUE,
    base_price_monthly DECIMAL(12, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (availability_status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'RESERVED')),
    amenities JSONB, -- Array of strings
    images JSONB, -- Array of URLs
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CHECK (usable_sqft <= gross_sqft)
);

CREATE INDEX idx_spaces_floor_id ON spaces(floor_id);
CREATE INDEX idx_spaces_is_leasable ON spaces(is_leasable);
CREATE INDEX idx_spaces_availability_status ON spaces(availability_status);
CREATE INDEX idx_spaces_search ON spaces(is_leasable, availability_status) WHERE is_leasable = TRUE;
CREATE INDEX idx_spaces_price ON spaces(base_price_monthly) WHERE is_leasable = TRUE;
```

#### bids
```sql
CREATE TABLE bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID REFERENCES spaces(id) ON DELETE RESTRICT NOT NULL,
    client_id UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    bid_amount DECIMAL(12, 2) NOT NULL CHECK (bid_amount > 0),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'COUNTER_OFFERED', 'WITHDRAWN')),
    counter_offer_amount DECIMAL(12, 2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CHECK (bid_amount > 0)
);

CREATE UNIQUE INDEX idx_bids_unique_pending ON bids(space_id, client_id) WHERE status = 'PENDING';
CREATE INDEX idx_bids_space_id ON bids(space_id);
CREATE INDEX idx_bids_client_id ON bids(client_id);
CREATE INDEX idx_bids_status ON bids(status);
CREATE INDEX idx_bids_created_at ON bids(created_at);
```

#### contracts
```sql
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bid_id UUID REFERENCES bids(id),
    space_id UUID REFERENCES spaces(id) ON DELETE RESTRICT NOT NULL,
    client_id UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    owner_id UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    contract_type VARCHAR(20) NOT NULL CHECK (contract_type IN ('LEASE', 'RENTAL', 'SALE')),
    start_date DATE NOT NULL,
    end_date DATE, -- Nullable for SALE type
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PENDING_SIGNATURE', 'ACTIVE', 'EXPIRED', 'TERMINATED')),
    contract_url VARCHAR(500),
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CHECK (end_date IS NULL OR end_date > start_date)
);

CREATE INDEX idx_contracts_space_id ON contracts(space_id);
CREATE INDEX idx_contracts_client_id ON contracts(client_id);
CREATE INDEX idx_contracts_owner_id ON contracts(owner_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE UNIQUE INDEX idx_contracts_active_space ON contracts(space_id) WHERE status = 'ACTIVE';
CREATE INDEX idx_contracts_dates ON contracts(start_date, end_date);
```

#### payments
```sql
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID REFERENCES contracts(id) ON DELETE RESTRICT NOT NULL,
    payer_id UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    due_date DATE NOT NULL,
    paid_date DATE,
    status VARCHAR(20) DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'DUE', 'PAID', 'OVERDUE', 'CANCELLED')),
    installment_number INTEGER NOT NULL,
    total_installments INTEGER NOT NULL,
    payment_method VARCHAR(50), -- bank_transfer, cheque, external_gateway
    invoice_url VARCHAR(500),
    receipt_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CHECK (installment_number > 0 AND installment_number <= total_installments)
);

CREATE INDEX idx_payments_contract_id ON payments(contract_id);
CREATE INDEX idx_payments_payer_id ON payments(payer_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_due_date ON payments(due_date);
CREATE INDEX idx_payments_status_due_date ON payments(status, due_date);
```

#### notifications
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    type VARCHAR(50) NOT NULL, -- bid_update, lease_milestone, payment_event
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, created_at) WHERE is_read = FALSE;
```

### 2.2 Audit Logs Table

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    ip_address INET,
    user_agent TEXT,
    request_body JSONB,
    response_status INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
```

### 2.3 Database Constraints & Rules

- **Foreign Keys:** All foreign keys use `ON DELETE RESTRICT` or `ON DELETE CASCADE` as appropriate
- **Unique Constraints:** Email addresses, building+floor combinations, active contracts per space
- **Check Constraints:** Data validation (e.g., usable_sqft <= gross_sqft, bid_amount > 0)
- **Generated Columns:** net_leasable_sqft calculated automatically
- **Default Values:** Timestamps, status fields, boolean flags

---

## 3. API Specifications

### 3.1 Base Configuration

**Base URL:** `https://api.example.com/api/v1`

**Authentication:** 
- Header: `Authorization: Bearer {access_token}`
- Refresh: `X-Refresh-Token: {refresh_token}`

**Content-Type:** `application/json`

**Common Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `429` - Too Many Requests (rate limited)
- `500` - Internal Server Error
- `503` - Service Unavailable

**Pagination:**
- Query params: `?cursor={cursor}&limit={limit}` (default limit: 20, max: 100)
- Response: `{ data: [...], meta: { cursor, has_more, total? } }`

### 3.2 Authentication Endpoints

#### POST /api/v1/auth/register
Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "John Doe",
  "role": "CLIENT",
  "phone": "+1234567890"
}
```

**Response:** `201 Created`
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "refresh_token_here",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "CLIENT",
    "email_verified": false
  }
}
```

**Validation:**
- Email: RFC 5322 compliant
- Password: 8+ chars, 1 uppercase, 1 lowercase, 1 number
- Role: Must be valid enum value

#### POST /api/v1/auth/login
Authenticate user and receive tokens.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "token": "access_token",
  "refresh_token": "refresh_token",
  "user": { ... }
}
```

**Error:** `401 Unauthorized` after 5 failed attempts, account locked for 15 minutes

#### POST /api/v1/auth/refresh
Refresh access token using refresh token.

**Request:**
```json
{
  "refresh_token": "refresh_token_here"
}
```

**Response:** `200 OK`
```json
{
  "token": "new_access_token",
  "refresh_token": "new_refresh_token"
}
```

#### POST /api/v1/auth/password-reset
Request password reset email.

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response:** `200 OK`
```json
{
  "message": "Password reset link sent to email"
}
```

#### POST /api/v1/auth/password-reset/confirm
Confirm password reset with token.

**Request:**
```json
{
  "token": "reset_token",
  "new_password": "NewSecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "message": "Password reset successful"
}
```

### 3.3 Building Endpoints

#### GET /api/v1/buildings
List buildings with pagination.

**Query Parameters:**
- `cursor` - Pagination cursor
- `limit` - Results per page (default: 20, max: 100)
- `owner_id` - Filter by owner (optional)

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Downtown Office Tower",
      "address": { "street": "...", "city": "...", "state": "...", "country": "...", "postal_code": "..." },
      "total_floors": 10,
      "amenities": ["parking", "elevator"],
      "occupancy_rate": 0.75,
      "created_at": "2025-01-27T00:00:00Z"
    }
  ],
  "meta": {
    "cursor": "next_cursor",
    "has_more": true
  }
}
```

**Auth:** Owner (own buildings), Super Admin (all)

#### POST /api/v1/buildings
Create a new building.

**Request:**
```json
{
  "name": "Downtown Office Tower",
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "state": "NY",
    "country": "USA",
    "postal_code": "10001"
  },
  "total_floors": 10,
  "amenities": ["parking", "elevator"],
  "latitude": 40.7128,
  "longitude": -74.0060
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "name": "Downtown Office Tower",
  "total_floors": 10,
  "floors": [
    { "id": "uuid", "floor_number": 1, ... },
    { "id": "uuid", "floor_number": 2, ... }
  ],
  "created_at": "2025-01-27T00:00:00Z"
}
```

**Side-effect:** Automatically creates floor records (1 to N)

**Auth:** Owner, Super Admin

#### GET /api/v1/buildings/:id
Get building details with floors and spaces.

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "name": "Downtown Office Tower",
  "address": { ... },
  "total_floors": 10,
  "floors": [
    {
      "id": "uuid",
      "floor_number": 1,
      "total_sqft": 10000,
      "common_area_sqft": 2000,
      "net_leasable_sqft": 8000,
      "spaces": [ ... ]
    }
  ],
  "occupancy_rate": 0.75,
  "total_spaces": 50,
  "available_spaces": 12
}
```

**Auth:** Public (limited info), Owner (full details)

#### PUT /api/v1/buildings/:id
Update building information.

**Request:**
```json
{
  "name": "Updated Name",
  "address": { ... },
  "total_floors": 12,
  "amenities": ["parking", "elevator", "gym"]
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "name": "Updated Name",
  "updated_at": "2025-01-27T00:00:00Z"
}
```

**Side-effect:** Adjusts floor records if total_floors changed

**Auth:** Owner, Super Admin

### 3.4 Space Endpoints

#### GET /api/v1/spaces
Search and filter spaces.

**Query Parameters:**
- `cursor` - Pagination cursor
- `limit` - Results per page (default: 20, max: 100)
- `building_id` - Filter by building
- `floor_id` - Filter by floor
- `min_sqft` - Minimum square footage
- `max_sqft` - Maximum square footage
- `min_price` - Minimum monthly price
- `max_price` - Maximum monthly price
- `amenities` - Comma-separated amenities array
- `is_leasable` - Filter leasable spaces (default: true for clients)
- `availability_status` - Filter by status
- `sort` - Sort by: `price_asc`, `price_desc`, `sqft_asc`, `sqft_desc`, `relevance`

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Office Suite 101",
      "gross_sqft": 1000,
      "usable_sqft": 800,
      "base_price_monthly": 5000,
      "currency": "USD",
      "availability_status": "AVAILABLE",
      "amenities": ["wifi", "parking"],
      "images": ["https://..."],
      "floor": { "floor_number": 1, "building": { "name": "..." } }
    }
  ],
  "meta": {
    "cursor": "next_cursor",
    "has_more": true,
    "total": 150
  }
}
```

**Auth:** Public (leasable only), Owner (all spaces)

#### POST /api/v1/spaces
Create a new space.

**Request:**
```json
{
  "floor_id": "uuid",
  "name": "Office Suite 101",
  "gross_sqft": 1000,
  "usable_sqft": 800,
  "usage_type": "OFFICE",
  "is_leasable": true,
  "base_price_monthly": 5000,
  "currency": "USD",
  "availability_status": "AVAILABLE",
  "amenities": ["wifi", "parking"],
  "images": ["https://..."]
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "name": "Office Suite 101",
  "created_at": "2025-01-27T00:00:00Z"
}
```

**Validation:**
- `usable_sqft <= gross_sqft`
- `usage_type` must be valid enum
- `floor_id` must exist

**Auth:** Owner, Super Admin

#### GET /api/v1/spaces/:id
Get detailed space information.

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "name": "Office Suite 101",
  "gross_sqft": 1000,
  "usable_sqft": 800,
  "base_price_monthly": 5000,
  "currency": "USD",
  "availability_status": "AVAILABLE",
  "amenities": ["wifi", "parking"],
  "images": ["https://..."],
  "floor": {
    "id": "uuid",
    "floor_number": 1,
    "floor_plan_url": "https://..."
  },
  "building": {
    "id": "uuid",
    "name": "Downtown Office Tower",
    "address": { ... }
  },
  "similar_spaces": [ ... ],
  "ai_recommendation_score": 0.85
}
```

**Auth:** Public

### 3.5 Bid Endpoints

#### POST /api/v1/bids
Place a bid on a space.

**Request:**
```json
{
  "space_id": "uuid",
  "bid_amount": 4500
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "space_id": "uuid",
  "client_id": "uuid",
  "bid_amount": 4500,
  "status": "PENDING",
  "created_at": "2025-01-27T00:00:00Z"
}
```

**WebSocket Event:** `bid:status_changed` sent to space owner

**Validation:**
- `bid_amount > 0`
- No duplicate pending bid from same client on same space
- Space must be available

**Auth:** Client

#### PUT /api/v1/bids/:id/approve
Approve a bid.

**Request:**
```json
{
  "notes": "Approved - lease will be generated"
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "status": "APPROVED",
  "contract_id": "uuid",
  "updated_at": "2025-01-27T00:00:00Z"
}
```

**Side-effects:**
- Auto-generates lease document
- Updates space availability to RESERVED
- WebSocket notification to client

**Auth:** Owner, Super Admin

#### PUT /api/v1/bids/:id/reject
Reject a bid.

**Request:**
```json
{
  "notes": "Bid too low"
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "status": "REJECTED",
  "updated_at": "2025-01-27T00:00:00Z"
}
```

**WebSocket Event:** `bid:status_changed` sent to client

**Auth:** Owner, Super Admin

#### PUT /api/v1/bids/:id/counter
Make a counter-offer.

**Request:**
```json
{
  "counter_offer_amount": 4800,
  "notes": "Counter-offer: $4800/month"
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "status": "COUNTER_OFFERED",
  "counter_offer_amount": 4800,
  "updated_at": "2025-01-27T00:00:00Z"
}
```

**WebSocket Event:** `bid:status_changed` sent to client

**Auth:** Owner, Super Admin

#### GET /api/v1/bids
List bids with filters.

**Query Parameters:**
- `cursor` - Pagination cursor
- `limit` - Results per page
- `space_id` - Filter by space (owners)
- `client_id` - Filter by client (clients)
- `status` - Filter by status

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "uuid",
      "space_id": "uuid",
      "space": { "name": "Office Suite 101", ... },
      "bid_amount": 4500,
      "status": "PENDING",
      "created_at": "2025-01-27T00:00:00Z"
    }
  ],
  "meta": { "cursor": "...", "has_more": true }
}
```

**Auth:** Owner (their spaces), Client (their bids)

### 3.6 Contract Endpoints

#### GET /api/v1/contracts/:id
Get contract details.

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "contract_type": "LEASE",
  "status": "ACTIVE",
  "start_date": "2025-02-01",
  "end_date": "2026-01-31",
  "contract_url": "https://...",
  "space": { ... },
  "client": { ... },
  "owner": { ... },
  "payments": [ ... ]
}
```

**Auth:** Owner, Client (own contracts), Super Admin

#### GET /api/v1/contracts/:id/download
Download contract PDF.

**Response:** `200 OK`
- Content-Type: `application/pdf`
- Content-Disposition: `attachment; filename="lease-{id}.pdf"`

**Auth:** Owner, Client (own contracts), Super Admin

### 3.7 Payment Endpoints

#### GET /api/v1/payments
List payments with filters.

**Query Parameters:**
- `cursor` - Pagination cursor
- `limit` - Results per page
- `contract_id` - Filter by contract
- `status` - Filter by status
- `due_date_from` - Filter by due date range
- `due_date_to` - Filter by due date range

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "uuid",
      "contract_id": "uuid",
      "amount": 5000,
      "currency": "USD",
      "due_date": "2025-02-01",
      "status": "SCHEDULED",
      "installment_number": 1,
      "total_installments": 12
    }
  ],
  "meta": { "cursor": "...", "has_more": true }
}
```

**Auth:** Owner, Client (own payments), Financial Officer, Super Admin

#### POST /api/v1/payments/:id/record
Record an external payment.

**Request:**
```json
{
  "paid_date": "2025-02-01",
  "payment_method": "bank_transfer",
  "transaction_reference": "TXN123456"
}
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "status": "PAID",
  "paid_date": "2025-02-01",
  "invoice_url": "https://...",
  "receipt_url": "https://..."
}
```

**Side-effects:**
- Auto-generates invoice and receipt
- Updates payment status to PAID
- Sends confirmation notification

**Auth:** Owner, Financial Officer, Super Admin

---

## 4. WebSocket Events

### 4.1 Connection

**Endpoint:** `wss://api.example.com/ws`

**Authentication:** 
- Query param: `?token={access_token}`
- Or: Send `auth` event with token after connection

### 4.2 Client → Server Events

#### bid:place
Place a new bid (alternative to REST API).

**Payload:**
```json
{
  "space_id": "uuid",
  "bid_amount": 4500
}
```

**Response:**
```json
{
  "event": "bid:placed",
  "data": {
    "bid_id": "uuid",
    "status": "PENDING"
  }
}
```

#### bid:withdraw
Withdraw a pending bid.

**Payload:**
```json
{
  "bid_id": "uuid"
}
```

#### notification:mark_read
Mark notification as read.

**Payload:**
```json
{
  "notification_id": "uuid"
}
```

### 4.3 Server → Client Events

#### bid:status_changed
Bid status updated (approve/reject/counter).

**Payload:**
```json
{
  "event": "bid:status_changed",
  "data": {
    "bid_id": "uuid",
    "space_id": "uuid",
    "status": "APPROVED",
    "contract_id": "uuid"
  }
}
```

#### lease:generated
Lease document generated from approved bid.

**Payload:**
```json
{
  "event": "lease:generated",
  "data": {
    "contract_id": "uuid",
    "contract_url": "https://...",
    "status": "DRAFT"
  }
}
```

#### payment:due
Payment due reminder.

**Payload:**
```json
{
  "event": "payment:due",
  "data": {
    "payment_id": "uuid",
    "amount": 5000,
    "due_date": "2025-02-01",
    "days_until_due": 3
  }
}
```

#### notification:new
New notification created.

**Payload:**
```json
{
  "event": "notification:new",
  "data": {
    "notification_id": "uuid",
    "type": "bid_update",
    "title": "Bid Approved",
    "message": "Your bid on Office Suite 101 has been approved"
  }
}
```

---

## 5. Caching Strategy

### 5.1 Redis Cache TTLs

| Cache Key | TTL | Invalidation Trigger |
|-----------|-----|---------------------|
| User sessions | 24 hours | Logout, token refresh |
| Building listings | 5 minutes | Building update/create/delete |
| Space listings | 5 minutes | Space update/create/delete |
| Search results | 2 minutes | Space update/create/delete |
| Dashboard metrics | 1 minute | Bid/lease/payment changes |
| Space details | 10 minutes | Space update |
| User profile | 15 minutes | Profile update |

### 5.2 Cache Key Patterns

- `session:{user_id}` - User session data
- `building:{building_id}` - Building details
- `space:{space_id}` - Space details
- `search:{hash}` - Search result cache (hash of query params)
- `dashboard:{user_id}:{type}` - Dashboard metrics
- `rate_limit:{user_id}:{endpoint}` - Rate limiting counters

### 5.3 Cache Invalidation

**On Space Update:**
- Invalidate `space:{space_id}`
- Invalidate `building:{building_id}` (if space belongs to building)
- Invalidate all `search:*` keys
- Invalidate `dashboard:{owner_id}:*`

**On Bid Status Change:**
- Invalidate `bid:{bid_id}`
- Invalidate `dashboard:{owner_id}:*` and `dashboard:{client_id}:*`
- Invalidate `space:{space_id}` (if bid affects availability)

**On Payment Record:**
- Invalidate `payment:{payment_id}`
- Invalidate `contract:{contract_id}`
- Invalidate `dashboard:{owner_id}:*` and `dashboard:{client_id}:*`

### 5.4 Database Query Caching

- Cache frequently accessed queries (e.g., building list, space search)
- Use Redis for query result caching
- Cache key includes query hash + parameters
- Invalidate on related data changes

---

## 6. Security Implementation

### 6.1 JWT Token Structure

#### Access Token
```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "role": "CLIENT",
  "iat": 1706313600,
  "exp": 1706400000
}
```
- **Expiry:** 24 hours
- **Algorithm:** HS256 or RS256
- **Storage:** Memory (not localStorage)

#### Refresh Token
```json
{
  "userId": "uuid",
  "tokenVersion": 1,
  "iat": 1706313600,
  "exp": 1708905600
}
```
- **Expiry:** 30 days
- **Storage:** httpOnly cookie
- **Rotation:** New refresh token on each refresh

### 6.2 Rate Limiting

| Endpoint Category | Limit | Window |
|-------------------|-------|--------|
| Authentication (login/register) | 5 requests | Per IP, per minute |
| Password reset | 3 requests | Per email, per hour |
| Bidding endpoints | 10 requests | Per user, per minute |
| Search endpoints | 20 requests | Per user, per minute |
| General API | 100 requests | Per user, per minute |
| File upload | 10 requests | Per user, per minute |

**Implementation:**
- Redis-based rate limiting
- Sliding window algorithm
- Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

### 6.3 Input Validation

**All API Inputs:**
- Validated with Zod schemas
- Type checking and format validation
- Sanitization for XSS prevention
- SQL injection prevention via parameterized queries

**File Uploads:**
- Type validation (images: jpg, png, webp; PDFs: pdf)
- Size limits: Images 10MB, PDFs 50MB
- Virus scanning (optional, Phase 2)
- Content-Type validation

### 6.4 Password Security

- **Hashing:** bcrypt with cost factor 12
- **Minimum Requirements:** 8+ chars, 1 uppercase, 1 lowercase, 1 number
- **Password History:** Prevent reuse of last 5 passwords
- **Reset Token:** Cryptographically secure random token, 1-hour expiry

### 6.5 CORS Configuration

- **Allowed Origins:** Configured per environment
- **Methods:** GET, POST, PUT, DELETE, PATCH, OPTIONS
- **Headers:** Authorization, Content-Type, X-Refresh-Token
- **Credentials:** true (for cookies)

### 6.6 Security Headers

- **Content-Security-Policy:** Restrict resource loading
- **X-Frame-Options:** DENY
- **X-Content-Type-Options:** nosniff
- **Strict-Transport-Security:** max-age=31536000; includeSubDomains
- **X-XSS-Protection:** 1; mode=block

---

## 7. Deployment Architecture

### 7.1 Phase 1 (MVP) - Single Region

```
┌─────────────────────────────────────────┐
│         Load Balancer / API Gateway      │
│      (Cloud Load Balancer / ALB)         │
└──────────────┬───────────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼────┐         ┌──────▼──────┐
│  API   │         │  WebSocket  │
│ Service│         │   Service   │
│(Cloud  │         │  (Cloud Run)│
│ Run)   │         │             │
└───┬────┘         └─────────────┘
    │
    ├──────────────┬──────────────┐
    │              │              │
┌───▼────┐   ┌─────▼────┐   ┌─────▼────┐
│Postgres│   │  Redis   │   │   S3     │
│(Cloud  │   │(Elasti   │   │(Object   │
│ SQL)   │   │ Cache)   │   │ Storage) │
└────────┘   └──────────┘   └──────────┘
```

**Infrastructure:**
- **Region:** Single primary region (e.g., us-east-1)
- **API Service:** Cloud Run / ECS Fargate (auto-scaling: 1-10 instances)
- **WebSocket Service:** Separate service for real-time connections
- **Database:** Managed PostgreSQL (Cloud SQL, RDS) with automated backups
- **Cache:** Managed Redis (ElastiCache, Memorystore)
- **Storage:** S3-compatible object storage
- **CDN:** CloudFront/Cloudflare for static assets

### 7.2 Phase 2+ - Multi-Region

```
┌─────────────────────────────────────────┐
│    Global Load Balancer (Multi-Region)   │
└──────────────┬──────────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼──────┐        ┌──────▼──────┐
│ Region 1 │        │  Region 2   │
│ (Primary)│        │ (Secondary)  │
└──────────┘        └─────────────┘
    │                     │
    ├──────────────┬──────┴──────────┐
    │              │                 │
┌───▼────┐   ┌─────▼────┐      ┌─────▼────┐
│Postgres│   │  Redis   │      │Postgres  │
│Primary │   │ Cluster  │      │Replica   │
│        │   │          │      │(Read-Only)│
└────────┘   └──────────┘      └──────────┘
```

**Infrastructure:**
- **Regions:** Primary + Secondary (active-passive or active-active)
- **Database:** PostgreSQL with read replicas in secondary region
- **Redis:** Redis Cluster for high availability
- **Load Balancer:** Multi-region with health checks and failover
- **Backups:** Automated daily backups with point-in-time recovery
- **Disaster Recovery:** RTO < 4 hours, RPO < 1 hour

### 7.3 Container Configuration

**Dockerfile Example:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

**Environment Variables:**
- `NODE_ENV` - production/staging/development
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `JWT_SECRET` - JWT signing secret (from secret store)
- `AWS_ACCESS_KEY_ID` - AWS credentials (from secret store)
- `AWS_SECRET_ACCESS_KEY` - AWS secret (from secret store)

### 7.4 Auto-Scaling Configuration

**API Service:**
- **Min Instances:** 1
- **Max Instances:** 10 (Phase 1), 50 (Phase 2+)
- **CPU Threshold:** Scale up at 70%, scale down at 30%
- **Memory Threshold:** Scale up at 80%, scale down at 40%
- **Request Rate:** Scale up at 100 req/s per instance

**WebSocket Service:**
- **Min Instances:** 2 (for high availability)
- **Max Instances:** 20
- **Connection Threshold:** Scale up at 1000 connections per instance

---

## 8. Monitoring & Observability

### 8.1 Metrics

#### Application Metrics
- **API Response Times:** p50, p95, p99 percentiles
- **Error Rates:** By endpoint, by status code
- **Request Rate:** Requests per second by endpoint
- **Database Query Performance:** Query duration, slow queries (>100ms)
- **WebSocket Connections:** Active connections, connection rate
- **Cache Hit Rates:** By cache key pattern

#### Infrastructure Metrics
- **CPU Usage:** Per service instance
- **Memory Usage:** Per service instance
- **Disk I/O:** Database and cache
- **Network I/O:** Ingress/egress bytes
- **Database Connections:** Active connections, connection pool usage

### 8.2 Logging

#### Log Levels
- **ERROR:** Exceptions, failed operations, critical issues
- **WARN:** Deprecated features, performance issues, retries
- **INFO:** Important business events (bid placed, lease generated)
- **DEBUG:** Detailed execution flow (development only)

#### Log Structure (JSON)
```json
{
  "timestamp": "2025-01-27T12:00:00Z",
  "level": "INFO",
  "correlation_id": "abc123",
  "service": "api",
  "endpoint": "/api/v1/bids",
  "method": "POST",
  "user_id": "uuid",
  "message": "Bid placed successfully",
  "metadata": {
    "bid_id": "uuid",
    "space_id": "uuid",
    "bid_amount": 4500
  }
}
```

#### Correlation IDs
- Generated at request entry point
- Passed through all service calls
- Included in logs, metrics, and error reports
- Returned in API response headers: `X-Correlation-ID`

### 8.3 Alerts

#### Critical Alerts (Immediate Response)
- **API Error Rate > 1%** for 5 minutes
- **Response Time p95 > 1s** for 10 minutes
- **Database Connection Pool Exhaustion**
- **Disk Space < 20%**
- **Service Unavailable** (health check failures)

#### Warning Alerts (Monitor)
- **API Error Rate > 0.5%** for 15 minutes
- **Response Time p95 > 500ms** for 20 minutes
- **Cache Hit Rate < 70%**
- **Failed Authentication Attempts Spike** (>100 in 5 minutes)
- **Database Query Duration > 500ms**

#### Notification Channels
- **Critical:** PagerDuty, Slack #alerts-critical
- **Warning:** Slack #alerts-warning, Email
- **Info:** Slack #monitoring

### 8.4 Health Checks

#### API Health Endpoint
**GET /health**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-27T12:00:00Z",
  "services": {
    "database": "healthy",
    "redis": "healthy",
    "storage": "healthy"
  }
}
```

#### Readiness Endpoint
**GET /ready**
- Checks database connectivity
- Checks Redis connectivity
- Returns 200 if ready, 503 if not ready

#### Liveness Endpoint
**GET /live**
- Simple endpoint to verify service is running
- Returns 200 if alive

---

## 9. Data Migration Strategy

### 9.1 Initial Data Load

#### CSV/Excel Import
- **Format:** CSV or Excel files with predefined columns
- **Validation:** Schema validation before import
- **Batching:** Bulk insert with transaction batching (1000 records/batch)
- **Error Handling:** Continue on error, log failed records

#### Import Endpoint
**POST /api/v1/admin/import/buildings**
- **Request:** Multipart form-data with CSV/Excel file
- **Response:** Import summary with success/failure counts
- **Auth:** Super Admin only

#### Import Process
1. Validate file format and schema
2. Parse and validate each record
3. Batch insert into database (1000 records per transaction)
4. Generate import report with errors
5. Send notification on completion

### 9.2 Schema Migrations

#### Migration Tool
- **Prisma Migrate** or **TypeORM Migrations**
- Versioned migration files: `001_create_users.sql`, `002_add_indexes.sql`
- Rollback scripts for each migration

#### Migration Process
1. Create migration file with SQL changes
2. Test migration on staging environment
3. Backup production database
4. Run migration in transaction
5. Verify migration success
6. Rollback if errors occur

#### Zero-Downtime Migrations
- **Additive Changes:** Add columns with defaults, add indexes concurrently
- **Backward Compatible:** Maintain old and new formats during transition
- **Blue/Green Deployment:** Deploy new version, switch traffic, monitor, rollback if needed

### 9.3 Data Migration Examples

#### Example: Add New Column
```sql
-- Migration: 003_add_net_leasable_sqft.sql
ALTER TABLE floors 
ADD COLUMN net_leasable_sqft DECIMAL(10, 2);

UPDATE floors 
SET net_leasable_sqft = total_sqft - common_area_sqft;

ALTER TABLE floors 
ALTER COLUMN net_leasable_sqft SET NOT NULL;

CREATE INDEX idx_floors_net_leasable_sqft ON floors(net_leasable_sqft);
```

#### Example: Add Index Concurrently
```sql
-- Migration: 004_add_concurrent_index.sql
CREATE INDEX CONCURRENTLY idx_spaces_search 
ON spaces(is_leasable, availability_status) 
WHERE is_leasable = TRUE;
```

---

## 10. Integration Patterns

### 10.1 E-Signature Integration

#### DocuSign Integration
**Webhook Endpoint:** `POST /api/v1/webhooks/docusign`

**Event: Signature Completed**
```json
{
  "event": "envelope_completed",
  "data": {
    "envelope_id": "docu_sign_envelope_id",
    "contract_id": "uuid",
    "signed_at": "2025-01-27T12:00:00Z"
  }
}
```

**Process:**
1. Receive webhook event
2. Verify webhook signature (HMAC)
3. Update contract status to ACTIVE
4. Store signed document URL
5. Send notification to owner and client
6. Generate payment schedule

**Configuration:**
- DocuSign API credentials in secret store
- Webhook URL registered in DocuSign dashboard
- HMAC secret for webhook verification

### 10.2 Accounting/ERP Integration

#### Export Format
**CSV Export:**
```csv
contract_id,payment_id,amount,currency,due_date,paid_date,status
uuid-1,uuid-2,5000,USD,2025-02-01,2025-02-01,PAID
```

**JSON Export:**
```json
{
  "payments": [
    {
      "contract_id": "uuid",
      "payment_id": "uuid",
      "amount": 5000,
      "currency": "USD",
      "due_date": "2025-02-01",
      "paid_date": "2025-02-01",
      "status": "PAID"
    }
  ]
}
```

#### Scheduled Export
- **Schedule:** Daily at 2 AM UTC
- **Format:** CSV or JSON (configurable)
- **Destination:** S3 bucket or SFTP server
- **Notification:** Email on completion/failure

#### Direct API Integration (Phase 3)
- **QuickBooks API:** OAuth2 authentication, sync payments
- **Zoho Books API:** OAuth2 authentication, sync invoices
- **SAP Integration:** REST API or EDI format

### 10.3 Email Service Integration

#### Provider Options
- **SendGrid:** Transactional emails
- **AWS SES:** Cost-effective, high volume
- **Postmark:** High deliverability

#### Email Templates
**Template: Bid Notification**
```handlebars
Subject: New Bid on {{space_name}}

Hello {{owner_name}},

A new bid has been placed on {{space_name}}:
- Bid Amount: ${{bid_amount}}/month
- Client: {{client_name}}
- View Bid: {{bid_url}}
```

#### Retry Logic
- **Attempts:** 3 retries with exponential backoff
- **Backoff:** 1s, 2s, 4s
- **Dead Letter Queue:** Failed emails stored for manual retry

### 10.4 WhatsApp Business API Integration

#### Provider Options
- **Twilio:** WhatsApp Business API via Twilio
- **MessageBird:** WhatsApp Business API
- **Official WhatsApp Business API:** Direct integration

#### Message Template
**Template: Payment Due Reminder**
```
Hello {{client_name}},

Your payment of ${{amount}} for {{space_name}} is due on {{due_date}}.

Payment Details:
- Amount: ${{amount}}
- Due Date: {{due_date}}
- Invoice: {{invoice_url}}

Thank you!
```

#### Rate Limits
- **Phase 1:** 1000 messages/day
- **Phase 2+:** Scale based on usage
- **Template Messages:** Pre-approved templates required

### 10.5 Map Service Integration

#### Google Maps API
- **Geocoding:** Convert addresses to coordinates
- **Places API:** Nearby amenities, transit stations
- **Directions API:** Commute time calculation
- **Maps JavaScript API:** Interactive maps

#### Mapbox Alternative
- **Geocoding API:** Address to coordinates
- **Places API:** Nearby points of interest
- **Directions API:** Route calculation
- **Mapbox GL JS:** Custom map rendering

#### Caching Strategy
- Cache geocoding results (address → coordinates) for 30 days
- Cache nearby amenities for 24 hours
- Cache commute times for 1 hour

---

## Document Control

**Version History:**
- v1.0 (2025-01-27): Initial technical implementation details document

**Related Documents:**
- SRS-Complete.md - Software Requirements Specification
- API-Documentation.md - Detailed API reference (to be created)
- Database-Schema.md - Complete database schema (to be created)

**Maintenance:**
- Update this document when technology stack changes
- Update API specifications when endpoints change
- Update database schema when migrations are added

---

**End of Document**

