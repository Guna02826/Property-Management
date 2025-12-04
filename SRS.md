## Software Requirements Specification (Consolidated)
## Enterprise Multi-Floor Commercial Office Leasing Platform

**Version:** 1.0  
**Date:** 2025-12-03  
**Document Type:** Consolidated Software Requirements Specification  
**Intended Audience:** Product Management, Development, QA, Architecture, DevOps, Security, Compliance, External Integrators

---

## 1. Introduction

### 1.1 Purpose

This document provides a single, consolidated Software Requirements Specification (SRS) for the Enterprise Multi-Floor Commercial Office Leasing Platform.
It unifies and normalizes requirements and terminology defined across:

- `Final Requirements/SRS-Complete.md`
- `Final Requirements/Technical-Implementation-Details.md`
- `Architecture/MVC-Architecture.md`
- `Architecture/Application-Workflow.md`
- `Documentation/Database-Schema.md`
- `Documentation/API-Documentation.md`
- `Documentation/ERROR-CODES.md`

The goals are:

- To describe the system in a form suitable for enterprise delivery, audits, and contracts.
- To provide a single requirements view that is consistent with architecture, workflows, database schema, API surface, and error model.
- To retain traceability to the original FR-*/NFR-* requirements defined in `SRS-Complete.md`.

### 1.2 Scope

The platform is a cloud-based SaaS solution for managing commercial office space across multiple buildings and floors, covering:

- Discovery and comparison of leasable office spaces.
- End-to-end transaction flows for leasing, renting, and selling spaces.
- Management of buildings, floors, spaces (including non-leasable/common areas).
- Real-time bidding and negotiation workflows.
- Automated contract (lease/rental/sale) generation and e-signature integration.
- Payment schedule generation and tracking (including EMI/installments) for external payments.
- Analytics, dashboards, and occupancy/revenue reporting.
- Multi-channel notifications, AI-based pricing and recommendations.

In-scope and out-of-scope items are identical to those defined in `SRS-Complete.md` (Sections 2.1 and 2.2). Any differences are resolved in favour of `SRS-Complete.md` unless explicitly stated in this document.

### 1.3 Definitions, Acronyms, and Abbreviations

- **Client / Tenant** – End user searching for and occupying spaces.
- **Owner / Building Owner** – Entity that owns one or more buildings and spaces.
- **Broker / Sales Representative** – Third party assisting clients and owners with deals.
- **Support / Agent** – Support staff handling tickets and inquiries.
- **Super Admin / System Administrator** – Platform operator with full permissions.
- **Property Manager / Financial Officer** – Operational roles focused on property and finance management.
- **Building** – A physical building containing one or more floors.
- **Floor** – A level in a building, containing one or more spaces.
- **Space / Office Space** – Individual area inside a floor (OFFICE, CANTEEN, RESTROOM, STORAGE, CORRIDOR, JANITOR, OTHER).
- **Leasable Space** – Space with `is_leasable = true`, exposed to Clients for search and bidding.
- **Non-Leasable / Common Area** – Internal/common space (canteens, restrooms, corridors, etc.) with `is_leasable = false`, used for planning and occupancy calculations.
- **Bid** – Offer submitted by a Client to occupy/buy a space under specific terms.
- **Contract / Lease / Rental / Sale Agreement** – Legal agreement resulting from approved bids.
- **Payment Schedule** – Planned sequence of payments (full or EMI/installments) linked to a contract.
- **FR-x.y** – Functional Requirement ID as defined in `SRS-Complete.md`.
- **NFR-x.y** – Non-Functional Requirement ID as defined in `SRS-Complete.md`.

### 1.4 References

- `Final Requirements/SRS-Complete.md` – Canonical list of FR-*/NFR-* requirements, assumptions, constraints, and acceptance criteria.
- `Final Requirements/Technical-Implementation-Details.md` – Detailed technical design, API patterns, WebSocket events, security, and deployment.
- `Architecture/MVC-Architecture.md` – MVC components, models, controllers, and service layer patterns.
- `Architecture/Application-Workflow.md` – End-to-end workflows by role and system automation.
- `Documentation/Database-Schema.md` – Normalized PostgreSQL schema and integrity rules.
- `Documentation/API-Documentation.md` – Detailed REST and WebSocket API reference.
- `Documentation/ERROR-CODES.md` – Error contract and error-code catalog.

### 1.5 Document Overview

This consolidated SRS is structured as follows:

- Section 2 – Overall description and system context.
- Section 3 – Users, roles, and access control.
- Section 4 – System features and functional requirements (grouped).
- Section 5 – External and internal interfaces (APIs, UI, integrations, notifications).
- Section 6 – Non-functional requirements (security, performance, reliability, etc.).
- Section 7 – Data model and business rules.
- Section 8 – Workflows and use cases.
- Section 9 – Error handling and logging.
- Section 10 – Traceability and alignment with implementation.
- Section 11 – Assumptions, constraints, and document control.

---

## 2. Overall Description

### 2.1 Product Perspective

The platform is a multi-tenant cloud SaaS offering, delivered as:

- Web application (React/Next.js) for Clients, Owners, Brokers, Support, and Admins.
- Optional mobile application (React Native/Flutter) for Clients, Owners, and Brokers.
- REST and WebSocket APIs for integrations and real-time updates.

Backend services (Node.js/Fastify) expose versioned APIs under `/api/v1`, communicating with:

- Primary PostgreSQL database (see `Database-Schema.md`).
- Redis for caching, rate limiting, and sessions.
- Object storage (S3 or equivalent) for media and documents.
- Optional analytics store (MongoDB/TimescaleDB) and AI/ML services (Python-based).

System context diagrams and module dependency flows are defined in `SRS-Complete.md` Section 8 and `Technical-Implementation-Details.md` Section 7; this document assumes those as the architectural baseline.

### 2.2 Product Functions (Summary)

At a high level, the platform provides:

1. **User Management & Authentication** (FR-1.x, FR-11.x, NFR-1.x)
2. **Building & Floor Management** (FR-2.x)
3. **Space Management (Leasable and Non-Leasable)** (FR-3.x)
4. **Search & Discovery (including map and comparison)** (FR-4.x)
5. **Bidding & Negotiation** (FR-5.x)
6. **Contract / Lease / Rental / Sale Management** (FR-6.x)
7. **Payment Schedule and Tracking** (FR-7.x)
8. **Dashboards & Reporting** (FR-8.x)
9. **Notifications & Communication** (FR-9.x)
10. **AI & Analytics** (FR-10.x)
11. **Security, Compliance, and Auditability** (FR-11.x, NFR-1.x, NFR-8.x, NFR-9.x)
12. **Mobile Features** (FR-12.x) and **Data Management** (FR-13.x)

Each group below reuses the FR/NFR identifiers from `SRS-Complete.md` and aligns them with the architecture, workflows, and database schema.

### 2.3 User Classes and Characteristics

User roles and capabilities are identical to those in `SRS-Complete.md` Section 3:

- Client / Tenant
- Building Owner / Admin
- Sales Representative / Broker
- Support Agent
- Property Manager
- Financial Officer
- Super Admin / System Administrator

These roles map directly to `UserModel.role` in `MVC-Architecture.md` and to allowed actions via RBAC (see Sections 3 and 6).

### 2.4 Operating Environment

The operating environment is as defined in `SRS-Complete.md` Sections 5 and 6, and `Technical-Implementation-Details.md` Sections 1 and 7:

- Cloud infrastructure (Cloud Run / ECS Fargate) backed by managed PostgreSQL and Redis.
- Modern browsers (latest two versions of Chrome, Firefox, Safari, Edge) and recent iOS/Android versions.
- Secure TLS endpoints (`https://` and `wss://`).

### 2.5 Design and Implementation Constraints

Constraints from `SRS-Complete.md` Sections 6.1–6.10 and `Technical-Implementation-Details.md` (e.g., technology stack, no in-platform payment processing in early phases, performance and compliance targets) apply without modification.

---

## 3. Users, Roles, and Access Control

### 3.1 Role Model

The system SHALL support at least the following roles (FR-1.9, NFR-1.4):

- `SUPER_ADMIN`
- `OWNER`
- `CLIENT`
- `BROKER`
- `AGENT`
- `SUPPORT`
- `MANAGER` - Property Manager
- `ASSISTANT_MANAGER` - Assistant Property Manager
- `SALES_REP` - Sales Representative

These roles are enforced in:

- `users.role` column (`Database-Schema.md`, `users` table).
- Controller-level authorization checks (`MVC-Architecture.md` Section 3).
- Configurable role hierarchy system (`role_hierarchy_config` and `user_role_hierarchy` tables).

### 3.2 Role-Based Access Control (RBAC)

The system SHALL:

- Enforce RBAC at all API endpoints (FR-1.10, NFR-1.4, NFR-1.11).
- Restrict Owner-only endpoints (e.g., building and space management) to `OWNER` and `SUPER_ADMIN`.
- Restrict admin endpoints to `SUPER_ADMIN` only (AdminDashboardController).
- Restrict client-only capabilities (e.g., bidding, viewing own leases, payments) to `CLIENT`.
- Provide least-privilege access for `BROKER`, `AGENT`, `SUPPORT`, `MANAGER`, `ASSISTANT_MANAGER`, and `SALES_REP` based on use cases defined in `SRS-Complete.md` Section 3.1 and `Application-Workflow.md`.
- Enforce configurable role hierarchy where `SALES_REP` must be overseen by `MANAGER` when `MANAGER` role exists (see `Role-Hierarchy-System.md`).

### 3.3 Authentication

Authentication requirements (FR-1.1–FR-1.8, FR-11.x, NFR-1.x) include:

- Email/password registration and login with password strength rules.
- Optional OAuth2 (Google, LinkedIn) and biometric login on mobile.
- Two-factor authentication (2FA) when enabled.
- Account lockout after repeated failed login attempts.
- JWT-based stateless authentication (`Technical-Implementation-Details.md` Section 6.1).

---

## 4. System Features and Functional Requirements

> Note: This section consolidates functional requirements from `SRS-Complete.md` Sections 4.1–4.13, mapped to architecture and data structures defined in `MVC-Architecture.md` and `Database-Schema.md`.
> Requirement IDs (FR-x.y) are preserved to maintain traceability.

### 4.1 User Management & Authentication (FR-1.x, FR-11.x)

#### 4.1.1 Account Lifecycle

- The system SHALL support user registration, email verification, login, logout, password reset, and profile management (FR-1.1–FR-1.9).
- The system SHALL maintain audit logs for all authentication events (NFR-9.5, AuditLogModel).

#### 4.1.2 Security Controls

- The system SHALL enforce password strength rules and email validation (FR-13.3–FR-13.5, NFR-1.1–NFR-1.3).
- The system SHALL implement rate limiting on authentication endpoints (`ERROR-CODES.md`, `RATE_LIMIT_EXCEEDED`, NFR-1.9).

### 4.2 Building & Floor Management (FR-2.x)

#### 4.2.1 Building Management

- Owners SHALL be able to create, update, and view buildings with:
  - Name, structured address, geo-coordinates.
  - `total_floors` and building-level amenities (FR-2.1–FR-2.3).
- Building data SHALL be stored in the `buildings` table and exposed via `BuildingController` (`MVC-Architecture.md`, `Technical-Implementation-Details.md` Section 3.3).

#### 4.2.2 Floor Management

- On building creation, the system SHALL auto-create floor records 1..N (FR-2.2) as `floors` rows linked to `buildings.id`.
- Owners SHALL be able to update floor-level square footage and amenities (FR-2.4).
- The system SHALL compute `net_leasable_sqft` as `total_sqft - common_area_sqft` via generated column (FR-2.5, `Database-Schema.md` Section 3.3).
- Floor numbers MUST be unique per building (FR-13.2).

### 4.3 Space Management (FR-3.x)

#### 4.3.1 Space Definition

- The system SHALL allow Owners to create spaces with:
  - `floor_id`, `name`, `gross_sqft`, `usable_sqft`, `usage_type`, `is_leasable`, `base_price_monthly`, `currency`, `availability_status`, `amenities`, `images` (FR-3.1–FR-3.5).
- `usable_sqft` SHALL NOT exceed `gross_sqft` (FR-13.1, `spaces` CHECK).
- `usage_type` SHALL be enforced as an enum matching `Database-Schema.md` (OFFICE, CANTEEN, RESTROOM, STORAGE, CORRIDOR, JANITOR, OTHER).

#### 4.3.2 Leasable vs Non-Leasable Spaces

- The system SHALL use `is_leasable`:
  - `true` for client-facing leasable spaces.
  - `false` for internal/common areas (FR-3.2, FR-2.6).
- Client search endpoints SHALL return only `is_leasable = true` spaces (FR-3.6, FR-4.5, `OfficeSpaceController.search`).
- Owners SHALL manage both leasable and non-leasable spaces, with the ability to toggle `is_leasable` and `usage_type` (Application-Workflow.md “Space & Common-Area Modifications”).

### 4.4 Search & Discovery (FR-4.x)

#### 4.4.1 Filters and Listings

- Clients SHALL be able to search spaces by location, building, floor, size, price range, availability, and amenities (FR-4.1–FR-4.3).
- The system SHALL implement cursor-based pagination on all list endpoints (FR-4.6, NFR-2.9).
- Search responses SHALL include key details as described in `Application-Workflow.md` “Space Discovery & Browsing” and `API-Documentation.md` (space cards with size, price, location, status, AI match score).

#### 4.4.2 Map and Comparison

- The system SHALL provide a map view of spaces using external mapping APIs (FR-4.2, `Technical-Implementation-Details.md` Section 10.5).
- The system SHALL allow clients to compare multiple spaces side-by-side (FR-4.4), exposing a comparison API as defined in `Application-Workflow.md` and `API-Documentation.md`.

### 4.5 Bidding & Negotiation (FR-5.x)

#### 4.5.1 Bid Creation and Validation

- Clients SHALL place bids on AVAILABLE and leasable spaces (FR-5.1).
- The system SHALL validate:
  - `bid_amount > 0`.
  - The space is still `AVAILABLE` and `is_leasable = true`.
  - No existing active pending bid from the same client on the same space (FR-5.5, unique partial index `bids_unique_pending`).

#### 4.5.2 Real-Time Updates and Decisioning

- Owners SHALL receive real-time bid notifications via WebSockets and notifications center (FR-5.2, FR-5.3, `WebSocket Events`).
- Owners SHALL be able to approve, reject, or counter bids (FR-5.3, `BidController` endpoints).
- The system SHALL retain full bid history per space and user (FR-5.6).

### 4.6 Contract / Lease / Rental / Sale Management (FR-6.x)

#### 4.6.1 Contract Generation

- Upon bid approval, the system SHALL generate contract records of type LEASE, RENTAL, or SALE from the approved bid (FR-6.1, FR-6.2).
- Contracts SHALL be stored in the `contracts` table with enforced `contract_type` enum and a unique active contract per space (NFR-10.1, `contracts_active_space_unique` index).

#### 4.6.2 E-Signature and Lifecycle

- The system SHALL integrate with e-signature providers (e.g., DocuSign) to handle signing workflows (FR-6.4, `Technical-Implementation-Details.md` Section 10.1).
- Contract status transitions (DRAFT → PENDING_SIGNATURE → ACTIVE → EXPIRED/TERMINATED) SHALL be tracked and audited (FR-6.6–FR-6.7, NFR-9.x).

### 4.7 Payment Schedule and Tracking (FR-7.x)

#### 4.7.1 Schedule Generation

- The system SHALL generate payment schedules for contracts, including:
  - `amount`, `currency`, `due_date`, `installment_number`, `total_installments`, `status` (FR-7.1, FR-7.6).
- Payments SHALL be tracked in the `payments` table and exposed via `PaymentController` (`Technical-Implementation-Details.md` Sections 2.4 and 3.7).

#### 4.7.2 External Payments and Invoicing

- The system SHALL record external payments (bank transfers, cheques, external gateways) but SHALL NOT process payments directly in early phases (FR-7.3–FR-7.5, Scope 2.2).
- The system SHALL generate invoices and receipts for recorded payments (FR-7.4, FR-7.7).

### 4.8 Dashboards & Reporting (FR-8.x)

- Owner dashboards SHALL display occupancy, revenue, active bids, and upcoming income (`Application-Workflow.md`, “Analytics & Reporting”; FR-8.1, FR-8.2, FR-8.4).
- Client dashboards SHALL display active bids, leases, and upcoming payments (FR-8.2).
- Reports SHALL be exportable in CSV, PDF, and Excel formats (FR-8.5).

### 4.9 Notifications (FR-9.x)

- The system SHALL support multi-channel notifications (email, WhatsApp, push, in-app) for bid updates, contract milestones, and payment events (FR-9.1–FR-9.4, `Technical-Implementation-Details.md` Sections 10.3–10.4).
- Notification records SHALL be persisted in `notifications` and accessible via `NotificationController`.

### 4.10 AI & Analytics (FR-10.x)

- The system SHALL provide AI-powered:
  - Pricing suggestions.
  - Space recommendations.
  - Bid success probability.
  - Occupancy and revenue forecasts (FR-10.1–FR-10.5).
- Implementation details (ML stack, models, and data pipelines) are as in `Technical-Implementation-Details.md` Sections 1.5 and 4.

### 4.11 Additional Features (FR-11.x–FR-13.x)

- Security & compliance functional requirements (FR-11.x) align with NFRs in Section 6.
- Mobile-specific capabilities (FR-12.x) and data validation rules (FR-13.x) apply as defined in `SRS-Complete.md`.

---

## 5. External and Internal Interfaces

### 5.1 API Interfaces

REST API endpoints and contracts are fully documented in `API-Documentation.md` and summarized in:

- `MVC-Architecture.md` (Controller → Endpoint mapping).
- `Application-Workflow.md` (API by workflow).
- `Technical-Implementation-Details.md` Section 3.

The SRS requires:

- All public APIs to be documented with OpenAPI/Swagger (NFR-4.5, NFR-5.8).
- All list endpoints to support cursor-based pagination (FR-4.6, NFR-2.9).
- Standardized error responses per `ERROR-CODES.md`.

### 5.2 WebSocket Interfaces

WebSocket events for bid updates, leases, payments, and notifications SHALL conform to payload structures defined in `Technical-Implementation-Details.md` Section 4.

### 5.3 User Interface

User interface views and flows SHALL follow the conceptual UI definitions in `MVC-Architecture.md` Section 4 and `Application-Workflow.md`. Accessibility and responsiveness requirements are captured in NFR-5.x.

### 5.4 External Integrations

External integrations (e-signature, email, WhatsApp, mapping, CRM/ERP) SHALL follow flows and security patterns defined in `Technical-Implementation-Details.md` Sections 10.1–10.5 and `SRS-Complete.md` Section 8.3.

---

## 6. Non-Functional Requirements (Consolidated)

This section consolidates NFRs from `SRS-Complete.md` Section 5, grouped by concern.
NFR IDs (NFR-x.y) are preserved.

### 6.1 Security (NFR-1.x, NFR-8.x, NFR-9.x)

- AES-256 encryption at rest and TLS 1.3 in transit (NFR-1.1–NFR-1.2, NFR-8.4).
- Mandatory RBAC across all endpoints (NFR-1.4).
- 2FA support and zero-trust posture (NFR-1.5–NFR-1.6).
- Regular security audits, penetration tests, and secret management in cloud-native secret stores (NFR-1.7, NFR-1.10).
- Comprehensive audit logging with tamper-resistance and retention policies (NFR-9.1–NFR-9.5).
- GDPR, CCPA, SOC 2, PCI-DSS (for payment-related data), ISO 27001, and data residency compliance (NFR-8.1–NFR-8.10).

### 6.2 Performance and Scalability (NFR-2.x, NFR-6.x)

- Response times, throughput, and scale targets as in NFR-2.1–NFR-2.11 and NFR-6.x:
  - 95% of API requests in < 500ms.
  - 95% of page loads in < 2 seconds.
  - 100,000+ concurrent users, 10,000+ transactions/minute.
- Use cursor-based pagination, caching (Redis), and indexed queries (`Database-Schema.md` Sections 5–6).

### 6.3 Reliability and Availability (NFR-3.x)

- 99.99% uptime, failover mechanisms, replication, backups, disaster recovery (NFR-3.1–NFR-3.11).
- Circuit breaker and retry patterns (`Technical-Implementation-Details.md` Sections 5 and 6, `Application-Workflow.md` Error Handling).

### 6.4 Maintainability and Observability (NFR-4.x)

- Modular architecture, microservices pattern, test coverage, CI/CD, and migration versioning as defined in NFR-4.1–NFR-4.11.
- Centralized logging, tracing, and metrics (`Technical-Implementation-Details.md` Section 8).

### 6.5 Usability, Compatibility, and Accessibility (NFR-5.x, NFR-7.x)

- WCAG 2.1 AA compliance, responsive design, multi-language, and localization support (NFR-5.1–NFR-5.7).
- Browser compatibility and PWA capabilities (NFR-7.x).

### 6.6 Data Integrity (NFR-10.x)

- Enforcement of integrity rules (e.g., one active lease per space, constraints on square footage, valid enumerations) via database constraints and application logic (`Database-Schema.md` Sections 3–6, NFR-10.1–NFR-10.4).

---

## 7. Data Model and Business Rules

The canonical data model is defined in `Database-Schema.md` and mapped to MVC models in `MVC-Architecture.md`.

### 7.1 Core Entities

- `users` ↔ `UserModel`
- `buildings` ↔ `BuildingModel`
- `floors` ↔ `FloorModel`
- `spaces` ↔ `OfficeSpaceModel`
- `bids` ↔ `BidModel`
- `contracts` ↔ `ContractModel`
- `payments` ↔ `PaymentModel`
- `notifications` ↔ `NotificationModel`
- `audit_logs` ↔ `AuditLogModel`

### 7.2 Key Business Rules

- Floor uniqueness per building (`UNIQUE(building_id, floor_number)`).
- `usable_sqft <= gross_sqft` for spaces.
- At most one active contract per space.
- Only `is_leasable = true` spaces are visible to Clients in search endpoints.
- Bids allowed only for spaces that are `AVAILABLE` and `is_leasable = true`.
- Payment installments must satisfy `installment_number > 0 AND installment_number <= total_installments`.

---

## 8. Workflows and Use Cases

Detailed workflows by role are specified in `Application-Workflow.md`.
This SRS requires that:

- Every step in the Client, Owner, Broker, Support, and Super Admin workflows is realizable via existing or planned APIs and UI views.
- Automated workflows (AI pricing, bid processing, lease generation, payment processing, notifications, renewal, analytics, occupancy tracking, fraud detection, backups) are implemented as described in `Application-Workflow.md` Section “System Automated Workflows”.

---

## 9. Error Handling and Logging

The platform SHALL:

- Return errors using the standard error format and error codes defined in `ERROR-CODES.md`.
- Map business logic and validation failures to appropriate HTTP status codes (400, 401, 403, 404, 409, 422, 429, 500, 503).
- Log all errors with correlation IDs and sufficient context (`Technical-Implementation-Details.md` Sections 6 and 8).

---

## 10. Traceability and Alignment

### 10.1 Requirements Traceability

- Each functional and non-functional requirement in this SRS maps to FR-*/NFR-* IDs in `SRS-Complete.md`.
- Implementation artefacts (controllers, models, tables, and key endpoints) are mapped in:
  - `MVC-Architecture.md` (Controller ↔ Endpoint ↔ Model).
  - `Database-Schema.md` (Model ↔ Table).
  - `Application-Workflow.md` (Workflow Step ↔ Endpoint).

### 10.2 Consistency Rules

To maintain internal and cross-document consistency:

- Role names, status enums, and entity names used in:
  - This `SRS.md`
  - `SRS-Complete.md`
  - `MVC-Architecture.md`
  - `Database-Schema.md`
  - `API-Documentation.md`
  - `ERROR-CODES.md`
  MUST remain synchronized.
- Any change to core domain concepts (roles, statuses, contract types, space usage types, key constraints) MUST be reflected across all the above documents.

---

## 11. Assumptions, Constraints, and Document Control

### 11.1 Assumptions and Constraints

All assumptions and constraints in `SRS-Complete.md` Section 6 apply without change.
This SRS does not introduce new project-level constraints beyond alignment and consistency requirements described in Section 10.

### 11.2 Version History

- **v1.0 (2025-12-03):** Initial consolidated SRS created from:
  - `Final Requirements/SRS-Complete.md`
  - `Final Requirements/Technical-Implementation-Details.md`
  - `Architecture/MVC-Architecture.md`
  - `Architecture/Application-Workflow.md`
  - `Documentation/Database-Schema.md`
  - `Documentation/API-Documentation.md`
  - `Documentation/ERROR-CODES.md`

### 11.3 Approval and Distribution

- **Prepared by:** Architecture / Development Team  
- **Reviewed by:** Product Management, QA, Security, DevOps  
- **Approved by:** [To be filled]  

Distribution:

- Product Management
- Development Team
- QA Team
- DevOps / SRE
- Security / Compliance

---

**End of Document**



