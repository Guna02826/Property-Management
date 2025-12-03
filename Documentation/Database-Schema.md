# Database Schema Documentation
## Enterprise Multi-Floor Commercial Office Leasing Platform

**Version:** 1.0  
**Date:** 2025-01-27  
**Database:** PostgreSQL 14+

---

## Table of Contents

1. [Overview](#1-overview)
2. [Entity Relationship Diagram](#2-entity-relationship-diagram)
3. [Core Tables](#3-core-tables)
4. [Relationships](#4-relationships)
5. [Indexes](#5-indexes)
6. [Constraints](#6-constraints)
7. [Data Dictionary](#7-data-dictionary)
8. [Migration Guide](#8-migration-guide)

---

## 1. Overview

### 1.1 Database Information

- **Database Engine:** PostgreSQL 14+
- **Character Set:** UTF-8
- **Collation:** en_US.UTF-8
- **Primary Keys:** UUID (gen_random_uuid())
- **Timestamps:** TIMESTAMP WITH TIME ZONE (UTC)

### 1.2 Design Principles

- **Normalization:** Third Normal Form (3NF)
- **Audit Trail:** All tables include `created_at`, `updated_at`, `created_by`, `updated_by`
- **Soft Deletes:** Not implemented (hard deletes with audit logs)
- **Foreign Keys:** Enforced with CASCADE or RESTRICT as appropriate

---

## 2. Entity Relationship Diagram

```
┌─────────────┐
│    users    │
│─────────────│
│ id (PK)     │
│ email       │
│ role        │
│ ...         │
└──────┬──────┘
       │
       │ 1:N
       │
┌──────▼──────────┐      ┌──────────────┐      ┌─────────────┐
│   buildings     │ 1:N  │    floors    │ 1:N  │   spaces    │
│─────────────────│─────▶│──────────────│─────▶│─────────────│
│ id (PK)         │      │ id (PK)      │      │ id (PK)     │
│ owner_id (FK)   │      │ building_id  │      │ floor_id    │
│ name            │      │ floor_number │      │ is_leasable │
│ ...             │      │ ...          │      │ ...         │
└─────────────────┘      └──────────────┘      └──────┬──────┘
                                                       │
                                                       │ 1:N
                                                       │
┌─────────────┐      ┌──────────────┐      ┌─────────▼─────────┐
│    bids     │      │  contracts   │      │    payments      │
│─────────────│      │──────────────│      │──────────────────│
│ id (PK)     │      │ id (PK)      │      │ id (PK)          │
│ space_id    │      │ space_id     │      │ contract_id (FK) │
│ client_id   │      │ client_id    │      │ payer_id (FK)    │
│ bid_amount  │      │ contract_type│      │ amount           │
│ status      │      │ status       │      │ status           │
│ ...         │      │ ...          │      │ ...              │
└─────────────┘      └──────────────┘      └──────────────────┘
       │                    │
       │ N:1                │ N:1
       │                    │
┌──────▼──────────┐  ┌──────▼──────────┐
│   notifications │  │  audit_logs     │
│─────────────────│  │─────────────────│
│ id (PK)         │  │ id (PK)         │
│ user_id (FK)    │  │ user_id (FK)     │
│ type            │  │ action          │
│ ...             │  │ ...             │
└─────────────────┘  └─────────────────┘
```

---

## 3. Core Tables

### 3.1 users

Stores user accounts for all roles (Owner, Client, Broker, Agent, Support, Super Admin).

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN (
        'SUPER_ADMIN', 'OWNER', 'CLIENT', 'BROKER', 'AGENT', 'SUPPORT'
    )),
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
```

**Indexes:**
- `idx_users_email` on `email`
- `idx_users_role` on `role`
- `idx_users_created_at` on `created_at`

### 3.2 buildings

Stores building information owned by users.

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
```

**Indexes:**
- `idx_buildings_owner_id` on `owner_id`
- `idx_buildings_location` on `(latitude, longitude)` using GIST
- `idx_buildings_created_at` on `created_at`

### 3.3 floors

Stores floor information for buildings. Automatically created when building is created.

```sql
CREATE TABLE floors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id UUID REFERENCES buildings(id) ON DELETE CASCADE NOT NULL,
    floor_number INTEGER NOT NULL,
    total_sqft DECIMAL(10, 2),
    common_area_sqft DECIMAL(10, 2) DEFAULT 0,
    net_leasable_sqft DECIMAL(10, 2) GENERATED ALWAYS AS (
        total_sqft - common_area_sqft
    ) STORED,
    amenities JSONB,
    floor_plan_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    UNIQUE(building_id, floor_number)
);
```

**Indexes:**
- `idx_floors_building_id` on `building_id`
- `idx_floors_building_floor` on `(building_id, floor_number)`

### 3.4 spaces

Stores individual spaces (offices, canteens, restrooms, etc.) within floors.

```sql
CREATE TABLE spaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    floor_id UUID REFERENCES floors(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL,
    gross_sqft DECIMAL(10, 2) NOT NULL,
    usable_sqft DECIMAL(10, 2) NOT NULL,
    usage_type VARCHAR(20) NOT NULL CHECK (usage_type IN (
        'OFFICE', 'CANTEEN', 'RESTROOM', 'STORAGE', 'CORRIDOR', 'JANITOR', 'OTHER'
    )),
    is_leasable BOOLEAN DEFAULT TRUE,
    base_price_monthly DECIMAL(12, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (
        availability_status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'RESERVED')
    ),
    amenities JSONB, -- Array of strings
    images JSONB, -- Array of URLs
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CHECK (usable_sqft <= gross_sqft)
);
```

**Indexes:**
- `idx_spaces_floor_id` on `floor_id`
- `idx_spaces_is_leasable` on `is_leasable`
- `idx_spaces_availability_status` on `availability_status`
- `idx_spaces_search` on `(is_leasable, availability_status)` WHERE `is_leasable = TRUE`
- `idx_spaces_price` on `base_price_monthly` WHERE `is_leasable = TRUE`

### 3.5 bids

Stores bids placed by clients on spaces.

```sql
CREATE TABLE bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID REFERENCES spaces(id) ON DELETE RESTRICT NOT NULL,
    client_id UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    bid_amount DECIMAL(12, 2) NOT NULL CHECK (bid_amount > 0),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'COUNTER_OFFERED', 'WITHDRAWN'
    )),
    counter_offer_amount DECIMAL(12, 2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CHECK (bid_amount > 0)
);
```

**Indexes:**
- `idx_bids_unique_pending` on `(space_id, client_id)` WHERE `status = 'PENDING'`
- `idx_bids_space_id` on `space_id`
- `idx_bids_client_id` on `client_id`
- `idx_bids_status` on `status`
- `idx_bids_created_at` on `created_at`

### 3.6 contracts

Stores lease, rental, and sale contracts.

```sql
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bid_id UUID REFERENCES bids(id),
    space_id UUID REFERENCES spaces(id) ON DELETE RESTRICT NOT NULL,
    client_id UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    owner_id UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    contract_type VARCHAR(20) NOT NULL CHECK (contract_type IN (
        'LEASE', 'RENTAL', 'SALE'
    )),
    start_date DATE NOT NULL,
    end_date DATE, -- Nullable for SALE type
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN (
        'DRAFT', 'PENDING_SIGNATURE', 'ACTIVE', 'EXPIRED', 'TERMINATED'
    )),
    contract_url VARCHAR(500),
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    CHECK (end_date IS NULL OR end_date > start_date)
);
```

**Indexes:**
- `idx_contracts_space_id` on `space_id`
- `idx_contracts_client_id` on `client_id`
- `idx_contracts_owner_id` on `owner_id`
- `idx_contracts_status` on `status`
- `idx_contracts_active_space` on `space_id` WHERE `status = 'ACTIVE'`
- `idx_contracts_dates` on `(start_date, end_date)`

**Constraint:** At most one active contract per space (enforced by unique index)

### 3.7 payments

Stores payment schedules and recorded payments.

```sql
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID REFERENCES contracts(id) ON DELETE RESTRICT NOT NULL,
    payer_id UUID REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    due_date DATE NOT NULL,
    paid_date DATE,
    status VARCHAR(20) DEFAULT 'SCHEDULED' CHECK (status IN (
        'SCHEDULED', 'DUE', 'PAID', 'OVERDUE', 'CANCELLED'
    )),
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
```

**Indexes:**
- `idx_payments_contract_id` on `contract_id`
- `idx_payments_payer_id` on `payer_id`
- `idx_payments_status` on `status`
- `idx_payments_due_date` on `due_date`
- `idx_payments_status_due_date` on `(status, due_date)`

### 3.8 notifications

Stores user notifications.

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
```

**Indexes:**
- `idx_notifications_user_id` on `user_id`
- `idx_notifications_is_read` on `is_read`
- `idx_notifications_created_at` on `created_at`
- `idx_notifications_user_unread` on `(user_id, is_read, created_at)` WHERE `is_read = FALSE`

### 3.9 audit_logs

Stores audit trail for all system actions.

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
```

**Indexes:**
- `idx_audit_logs_user_id` on `user_id`
- `idx_audit_logs_resource` on `(resource_type, resource_id)`
- `idx_audit_logs_created_at` on `created_at`
- `idx_audit_logs_action` on `action`

---

## 4. Relationships

### 4.1 Primary Relationships

| Parent Table | Child Table | Relationship | Cascade Rule |
|--------------|-------------|--------------|--------------|
| users | buildings | 1:N | RESTRICT |
| buildings | floors | 1:N | CASCADE |
| floors | spaces | 1:N | CASCADE |
| spaces | bids | 1:N | RESTRICT |
| spaces | contracts | 1:N | RESTRICT |
| users | bids | 1:N | RESTRICT |
| users | contracts | 1:N (client) | RESTRICT |
| users | contracts | 1:N (owner) | RESTRICT |
| contracts | payments | 1:N | RESTRICT |
| users | payments | 1:N | RESTRICT |
| users | notifications | 1:N | CASCADE |
| users | audit_logs | 1:N | SET NULL |

### 4.2 Relationship Details

**users → buildings**
- One user (owner) can own many buildings
- Deleting user restricts if buildings exist

**buildings → floors**
- One building has many floors
- Deleting building cascades to floors

**floors → spaces**
- One floor has many spaces
- Deleting floor cascades to spaces

**spaces → bids**
- One space can have many bids
- Deleting space restricts if active bids exist

**spaces → contracts**
- One space can have many contracts (historical)
- Only one active contract per space (enforced by unique index)

**contracts → payments**
- One contract has many payment schedule entries
- Deleting contract restricts if payments exist

---

## 5. Indexes

### 5.1 Index Strategy

- **Primary Keys:** All tables use UUID primary keys (indexed automatically)
- **Foreign Keys:** All foreign keys are indexed
- **Search Fields:** Frequently queried fields are indexed
- **Composite Indexes:** Common query patterns use composite indexes
- **Partial Indexes:** Filtered indexes for specific conditions

### 5.2 Index Summary

| Table | Index Name | Columns | Type | Purpose |
|-------|------------|---------|------|---------|
| users | idx_users_email | email | UNIQUE | Fast email lookup |
| users | idx_users_role | role | B-tree | Role-based queries |
| buildings | idx_buildings_owner_id | owner_id | B-tree | Owner's buildings |
| buildings | idx_buildings_location | (lat, lng) | GIST | Geospatial queries |
| floors | idx_floors_building_floor | (building_id, floor_number) | UNIQUE | Floor uniqueness |
| spaces | idx_spaces_search | (is_leasable, availability_status) | Partial | Client search |
| spaces | idx_spaces_price | base_price_monthly | Partial | Price filtering |
| bids | idx_bids_unique_pending | (space_id, client_id) | UNIQUE Partial | Prevent duplicates |
| contracts | idx_contracts_active_space | space_id | UNIQUE Partial | One active contract |
| payments | idx_payments_status_due_date | (status, due_date) | B-tree | Payment queries |
| notifications | idx_notifications_user_unread | (user_id, is_read, created_at) | Partial | Unread notifications |

---

## 6. Constraints

### 6.1 Check Constraints

| Table | Constraint | Description |
|-------|------------|-------------|
| users | role IN (...) | Valid role enum |
| buildings | total_floors > 0 | Positive floor count |
| floors | net_leasable_sqft = total_sqft - common_area_sqft | Generated column |
| spaces | usable_sqft <= gross_sqft | Logical square footage |
| spaces | usage_type IN (...) | Valid usage type |
| spaces | availability_status IN (...) | Valid status |
| bids | bid_amount > 0 | Positive bid amount |
| bids | status IN (...) | Valid bid status |
| contracts | contract_type IN (...) | Valid contract type |
| contracts | end_date > start_date OR end_date IS NULL | Valid date range |
| payments | status IN (...) | Valid payment status |
| payments | installment_number > 0 AND <= total_installments | Valid installment |

### 6.2 Unique Constraints

| Table | Constraint | Columns |
|-------|------------|---------|
| users | users_email_unique | email |
| floors | floors_building_floor_unique | (building_id, floor_number) |
| bids | bids_unique_pending | (space_id, client_id) WHERE status = 'PENDING' |
| contracts | contracts_active_space_unique | space_id WHERE status = 'ACTIVE' |

### 6.3 Foreign Key Constraints

All foreign keys enforce referential integrity:
- `ON DELETE RESTRICT`: Prevents deletion if child records exist
- `ON DELETE CASCADE`: Deletes child records when parent is deleted
- `ON DELETE SET NULL`: Sets foreign key to NULL (audit_logs.user_id)

---

## 7. Data Dictionary

### 7.1 Common Field Types

| Field Name | Type | Description | Example |
|------------|------|-------------|---------|
| id | UUID | Primary key | `550e8400-e29b-41d4-a716-446655440000` |
| created_at | TIMESTAMP | Record creation time | `2025-01-27T12:00:00Z` |
| updated_at | TIMESTAMP | Last update time | `2025-01-27T12:00:00Z` |
| created_by | UUID | User who created record | `550e8400-e29b-41d4-a716-446655440000` |
| updated_by | UUID | User who last updated | `550e8400-e29b-41d4-a716-446655440000` |
| status | VARCHAR(20) | Status enum | `PENDING`, `ACTIVE`, etc. |
| amount | DECIMAL(12, 2) | Monetary amount | `5000.00` |
| sqft | DECIMAL(10, 2) | Square footage | `1000.50` |

### 7.2 Enum Values

**User Roles:**
- `SUPER_ADMIN` - System administrator
- `OWNER` - Building owner
- `CLIENT` - Tenant/client
- `BROKER` - Sales representative/broker
- `AGENT` - Support agent
- `SUPPORT` - Customer support

**Space Usage Types:**
- `OFFICE` - Office space
- `CANTEEN` - Cafeteria/dining area
- `RESTROOM` - Restroom facilities
- `STORAGE` - Storage room
- `CORRIDOR` - Hallway/corridor
- `JANITOR` - Janitorial room
- `OTHER` - Other space type

**Availability Status:**
- `AVAILABLE` - Available for lease
- `OCCUPIED` - Currently occupied
- `MAINTENANCE` - Under maintenance
- `RESERVED` - Reserved/pending

**Bid Status:**
- `PENDING` - Awaiting owner response
- `APPROVED` - Approved by owner
- `REJECTED` - Rejected by owner
- `COUNTER_OFFERED` - Counter-offer made
- `WITHDRAWN` - Withdrawn by client

**Contract Status:**
- `DRAFT` - Draft contract
- `PENDING_SIGNATURE` - Awaiting signatures
- `ACTIVE` - Active contract
- `EXPIRED` - Contract expired
- `TERMINATED` - Contract terminated

**Payment Status:**
- `SCHEDULED` - Scheduled payment
- `DUE` - Payment due
- `PAID` - Payment received
- `OVERDUE` - Payment overdue
- `CANCELLED` - Payment cancelled

---

## 8. Migration Guide

### 8.1 Creating Migrations

```bash
# Using Prisma
npx prisma migrate dev --name migration_name

# Using TypeORM
npm run migration:create -- --name migration_name
```

### 8.2 Running Migrations

```bash
# Run all pending migrations
npm run migrate

# Rollback last migration
npm run migrate:undo

# Check migration status
npm run migrate:status
```

### 8.3 Migration Best Practices

1. **Always test migrations** on staging first
2. **Backup database** before running migrations
3. **Use transactions** for data migrations
4. **Add indexes concurrently** for large tables
5. **Version control** all migration files
6. **Document breaking changes** in migration comments

---

**Last Updated:** 2025-01-27  
**Database Version:** PostgreSQL 14+

