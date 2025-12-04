# MVC Architecture – Enterprise Multi-Floor Commercial Office Leasing Platform

**Pattern:** Model–View–Controller (MVC)  
**Scope:** High-level responsibilities and main components for web application  
**Version:** 1.0  
**Date:** 2025-12-02  
**Related Documents:** [Software Requirements Specification](../Final%20Requirements/SRS-Complete.md), [Application Workflow](./Application-Workflow.md)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Models (Domain Layer)](#2-models-domain-layer)
3. [Controllers (Application Layer)](#3-controllers-application-layer)
4. [Views (Presentation Layer)](#4-views-presentation-layer)
5. [MVC Flow Examples](#5-mvc-flow-examples)
6. [Separation of Concerns Guidelines](#6-separation-of-concerns-guidelines)
7. [Production & Performance Considerations](#7-production--performance-considerations)
8. [API Endpoint Mapping](#8-api-endpoint-mapping)
9. [Database Model Mapping](#9-database-model-mapping)
10. [Service Layer Patterns](#10-service-layer-patterns)

---

## 1. Overview

- **Models:** Domain entities, validation, and persistence logic.
- **Views:** UI pages/screens and reusable components.
- **Controllers:** Request handling, orchestration of models, and response building.

This document describes the primary MVC components required to support the core leasing workflow: **discover spaces → place bids → approve bids → generate lease → pay → manage leases**.

---

## 2. Models (Domain Layer)

> Logical model list; concrete implementation can use ORM entities (e.g., Sequelize/TypeORM/Prisma) or similar.

### 2.1 Core Models

- **UserModel**
  - Fields: `id`, `email`, `passwordHash`, `role`, `firstName`, `lastName`, `phoneNumber`, `companyName`, `isActive`, `createdAt`, `updatedAt`.
  - Responsibilities:
    - Persist and retrieve user data.
    - Password hashing and verification helper methods.
    - Role checks (`isClient`, `isOwner`, `isAdmin`, `isSalesRep`/`isBroker`, `isManager`, `isAssistantManager`).
  - Why this design:
    - Single user table with a `role` field keeps authentication and RBAC simple while still supporting multiple personas.
    - Fits workflows where the same login system is reused for client, owner, and admin dashboards.
  - Where used:
    - `AuthController` and `UserController` for login/profile.
    - All controllers for authorization checks (e.g., owner-only routes, **sales-rep access to CRM/lead endpoints**).

- **BuildingModel**
  - Fields: `id`, `ownerId`, `name`, `addressLine1`, `addressLine2`, `city`, `stateProvince`, `postalCode`, `country`, `latitude`, `longitude`, `description`, `totalFloors`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Link to owner.
    - Provide building-level queries (by city/owner).
    - Act as the single source of truth for how many floors a building has (`totalFloors`).
  - Why this design:
    - Separating buildings allows clean grouping of floors/spaces and per‑owner portfolios.
    - Location fields and coordinates are needed for search and map views.
    - Using `totalFloors` as canonical input allows automatic floor creation without redundant manual entry.
  - Where used:
    - `BuildingController` for CRUD.
    - Owner dashboard and public search/list views.
    - `FloorController` / background services to auto-generate or adjust floors when `totalFloors` changes.

- **FloorModel**
  - Fields: `id`, `buildingId`, `floorNumber`, `name`, `totalSqft`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Maintain building–floor hierarchy.
    - Validate uniqueness per building (`buildingId + floorNumber`).
  - Why this design:
    - Explicit floor records make it easy to show multi‑floor maps and floor‑level occupancy.
    - Avoids encoding floor information only inside space codes.
    - Designed to be automatically created/updated when `BuildingModel.totalFloors` is set, removing redundant manual floor input.
  - Where used:
    - `FloorController` and `OfficeSpaceController` when creating/listing office spaces.
    - Owner building/floor management views (read/update metadata, while base floors 1..N are generated from the building).

- **OfficeSpaceModel**
  - Fields: `id`, `floorId`, `spaceCode`, `name`, `usageType` (office, canteen, restroom, janitor, storage, meeting_room, etc.), `grossSqft`, `usableSqft`, `basePriceMonthly`, `currency`, `availabilityStatus`, `availableFrom`, `availableTo`, `description`, `amenities`, `images`, `isLeasable`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Provide search/filter by location, size, price, status.
    - Enforce state rules (`AVAILABLE`, `RESERVED`, `LEASED`, `SOLD`).
    - Represent both **leasable office areas** and **non-leasable/common areas** such as canteens, restrooms, janitor rooms, storage rooms, etc.
    - Ensure that **net leasable area** on a floor correctly excludes common-area `usageType` spaces and uses `usableSqft` rather than `grossSqft`.
  - Why this design:
    - Keeps all client‑visible **office space** listing data in a single model optimized for search and display, while `isLeasable` and `usageType` cleanly separate spaces that appear in client search from internal/common areas.
    - Supports both rental/lease and sale workflows by tracking availability (`AVAILABLE`, `LEASED`, `SOLD`) and the correct square footage that can actually be monetized.
  - Where used:
    - `OfficeSpaceController` for search and detail APIs.
    - Client office-space search/list/detail views (only `isLeasable = true`) and owner office-space/common-area management.

- **BidModel**
  - Fields: `id`, `spaceId`, `clientId`, `ownerId`, `bidAmount`, `currency`, `leaseTermMonths`, `startDate`, `status`, `counterAmount`, `counterMessage`, `clientMessage`, `expiresAt`, `transactionType` (`RENTAL`, `LEASE`, `SALE`), `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Manage bid lifecycle (pending → approved/rejected/countered/withdrawn).
    - Business rules (only one active bid per client/space if configured).
    - Distinguish whether a bid is for a **rental/lease** agreement or a **sale** transaction.
  - Why this design:
    - Keeps negotiation logic separate from contracts so multiple offers (rental, lease, or purchase) can exist before a deal is finalized.
    - Mirrors real‑world commercial workflows where the same space might be offered for rent or sale with different pricing.
  - Where used:
    - `BidController` and owner/client bid views.
    - Input to `ContractController`/`LeaseController` when generating contracts.

- **ContractModel (Lease / Rental / Sale)**
  - Fields: `id`, `spaceId`, `clientId`, `ownerId`, `bidId`, `contractNumber`, `startDate`, `endDate` (nullable for sale), `termMonths`, `monthlyRent` (for rental/lease), `salePrice` (for sale), `currency`, `depositAmount`, `status`, `contractType` (`LEASE`, `RENTAL`, `SALE`), `documentUrl`, `signedAtClient`, `signedAtOwner`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Track contract lifecycle (draft → pending-signature → active → expired/cancelled/completed) for both rental/lease and sale transactions.
    - Ensure at most one **active monetization contract** per space at a time (e.g., cannot be both actively leased and sold simultaneously).
  - Why this design:
    - Generalizes “lease” into a contract abstraction that supports **rental, lease, and sale** without duplicating models.
    - Keeps legal contract data separate from bids and payment schedules, enabling long-term tracking regardless of transaction type.
  - Where used:
    - `ContractController`/`LeaseController` and client/owner contract views.
    - `PaymentController` to link payments/EMIs to an underlying contract.

- **PaymentModel**
  - Fields: `id`, `contractId`, `payerId`, `amount`, `currency`, `paymentType`, `status`, `dueDate`, `installmentNumber`, `totalInstallments`, `paymentProvider`, `providerPaymentId`, `errorCode`, `errorMessage`, `paidAt`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Persist transactions and map them to contracts (lease, rental, or sale).
    - Represent both scheduled (future) and completed payments via `dueDate` and `paidAt`.
    - Support EMI/installment plans through `installmentNumber` and `totalInstallments` for each lease.
    - Optionally reference an external payment provider record, when owners use third-party gateways.
  - Why this design:
    - Treats the platform as a **payment tracker** for both full and EMI schedules, regardless of where the actual money moves.
    - Enables clear audit of what was paid for which lease and when, and what is **yet to be paid** across all installments.
  - Where used:
    - `PaymentController` and payment history/schedule sections of client/owner lease views.
    - Reporting/analytics on realized revenue and upcoming income.

- **NotificationModel**
  - Fields: `id`, `userId`, `type`, `title`, `message`, `channel`, `isRead`, `createdAt`, `readAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Store all user notifications.
    - Mark-as-read functionality for in-app center.
  - Why this design:
    - Decouples notification delivery (email, in‑app, WhatsApp) from core business actions.
    - Allows building a unified notifications center in the UI while still supporting external channels.
  - Where used:
    - `NotificationController` and notification bell/center views.
    - Triggered from `BidController`, `LeaseController`, `PaymentController`, etc., with `channel` values like `IN_APP`, `EMAIL`, `WHATSAPP` (SMS can be added later if needed).

- **PrivateVisitModel**
  - Fields: `id`, `spaceId`, `clientId`, `salesRepId`, `visitDate`, `startTime`, `endTime`, `status`, `visitType`, `notes`, `contactPreference`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Store private visit bookings for spaces.
    - Enforce conflict detection (no overlapping visits on same day for same space).
    - Track visit lifecycle (SCHEDULED → CONFIRMED → COMPLETED/CANCELLED/NO_SHOW).
  - Why this design:
    - Separates visit scheduling from bids/contracts, allowing clients to view spaces before committing.
    - Conflict detection prevents double-booking and scheduling clashes.
    - Supports different visit types (PRIVATE, GROUP, VIRTUAL) for flexible scheduling.
  - Where used:
    - `VisitController` for booking and managing visits.
    - Client space detail views for scheduling visits.
    - Sales rep dashboards for managing assigned visits.
    - Manager dashboards for overseeing subordinate visit activities.

- **RoleHierarchyConfigModel**
  - Fields: `id`, `organizationId`, `parentRole`, `childRole`, `isEnabled`, `requiresApproval`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Store configurable role hierarchy rules (e.g., Manager oversees Sales Rep).
    - Enable/disable hierarchy per organization.
    - Define approval requirements for hierarchical actions.
  - Why this design:
    - Flexible hierarchy system that can be configured per organization.
    - Supports business rules like "Sales Rep must be overseen by Manager when Manager exists".
  - Where used:
    - `AdminController` for hierarchy configuration.
    - User creation/assignment logic to enforce hierarchy rules.
    - Authorization checks for hierarchical permissions.

- **UserRoleHierarchyModel**
  - Fields: `id`, `parentUserId`, `childUserId`, `hierarchyConfigId`, `isActive`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
  - Responsibilities:
    - Store actual hierarchical relationships between users.
    - Link users to hierarchy configuration rules.
    - Track active/inactive relationships.
  - Why this design:
    - Implements the hierarchy defined in `RoleHierarchyConfigModel` at the user level.
    - Allows dynamic assignment and reassignment of hierarchical relationships.
  - Where used:
    - User management workflows for assigning managers to sales reps.
    - Authorization checks to determine oversight relationships.
    - Manager dashboards for viewing subordinates.

- **AuditLogModel**
  - Fields: `id`, `actorId`, `actionType`, `entityType`, `entityId`, `metadata`, `createdAt`.
  - Responsibilities:
    - Track sensitive actions for compliance and debugging.
  - Why this design:
    - Central audit log supports security reviews and troubleshooting without polluting business tables.
    - Scales well as more actions are added over time.
  - Where used:
    - Written by controllers/services on key events (login, bid changes, lease sign, payment, visit booking).
    - Read by admin tools and ops dashboards.

---

## 3. Controllers (Application Layer)

> Controllers receive HTTP requests, validate input, call services/models, and return responses or render views. All REST endpoints are documented with OpenAPI/Swagger and kept in sync via CI/CD.

### 3.1 Auth & User Controllers

- **AuthController**
  - Endpoints:
    - `POST /auth/register` – create new user (client or owner).
    - `POST /auth/login` – authenticate and issue session/JWT.
    - `POST /auth/logout` – invalidate session/token.
    - `GET /auth/me` – return current user profile.
  - Responsibilities:
    - Input validation for credentials.
    - Invoke `UserModel` for persistence and password checks.
    - Set authentication cookies/headers.
  - Why this design:
    - Keeps authentication concerns isolated from other controllers.
    - Simple mapping to common auth routes used by frontend frameworks.
  - Where used:
    - Called by login/registration views and any “who am I” checks on app load.

- **UserController**
  - Endpoints:
    - `GET /users/me` – get own profile.
    - `PATCH /users/me` – update profile fields.
  - Responsibilities:
    - Authorize user.
    - Apply partial updates to `UserModel`.
  - Why this design:
    - Separates profile management from low-level auth tokens.
    - Keeps a clear REST surface for user settings pages.
  - Where used:
    - Profile/settings views for all roles.

### 3.2 Building & Office Space Controllers

- **BuildingController**
  - Endpoints:
    - `POST /buildings` – create building (owner only).
    - `GET /buildings` – list owner buildings (owner) or public buildings (client).
    - `GET /buildings/{id}` – building details.
    - `PATCH /buildings/{id}` – update building (owner).
  - Responsibilities:
    - Owner authorization and ownership checks.
    - Trigger building validation and persistence.
  - Why this design:
    - Encapsulates all building-related rules (ownership, address uniqueness) in one place.
    - Matches owner workflows where buildings are the main management unit.
  - Where used:
    - Owner dashboard and building management views.

- **FloorController**
  - Endpoints:
    - `POST /buildings/{id}/floors` – create floor.
    - `GET /floors/{id}` – floor details.
    - `PATCH /floors/{id}` – update floor metadata.
  - Responsibilities:
    - Ensure `buildingId` exists and belongs to owner.
  - Why this design:
    - Keeps floor operations explicitly tied to a parent building.
    - Allows future floor-level features (heatmaps, per-floor stats) without changing routes.
  - Where used:
    - Building/floor management views when owners add or edit floors.

- **OfficeSpaceController**
  - Endpoints:
    - `POST /floors/{id}/spaces` – create office space (owner), including internal/common areas (canteen, restroom, janitor room, etc.) by setting `isLeasable` and `type`.
    - `GET /spaces` – search and filter office spaces (public/client) with **cursor-based (keyset) pagination** (`cursor`, `limit` → returns `nextCursor`).
    - `GET /spaces/{id}` – office space detail.
    - `PATCH /spaces/{id}` – update office space details/availability (owner).
  - Responsibilities:
    - Enforce authorization.
    - Use model queries for filtering by location/size/price.
    - Ensure only `isLeasable = true` spaces are returned in client-facing listing/search endpoints, while owners can view/edit both leasable and internal/common spaces.
  - Why this design:
    - Centralizes all office space listing-related endpoints, so search/list/detail logic stays consistent.
    - Cleanly separates owner write operations from client read operations on office spaces.
    - Allows owners to fully model their floors (including canteens, restrooms, janitor rooms, storage, etc.) without exposing internal/common areas in the marketplace.
  - Where used:
    - Client office-space search/detail views and owner office-space/common-area management UIs.

### 3.3 Bidding & Contract Controllers

- **BidController**
  - Endpoints:
    - `POST /spaces/{id}/bids` – client creates a bid.
    - `GET /bids` – list bids (filtered by role: client vs owner) with **cursor-based pagination**.
    - `GET /bids/{id}` – bid details.
    - `POST /bids/{id}/approve` – owner approves bid.
    - `POST /bids/{id}/reject` – owner rejects bid.
    - `POST /bids/{id}/counter` – owner counter-offers.
  - Responsibilities:
    - Validate bid input and business rules.
    - Update `BidModel` status and trigger notifications.
  - Why this design:
    - Encapsulates negotiation logic in one controller instead of spreading it across spaces or leases.
    - Reflects the importance of bids as a first-class concept in the product.
  - Where used:
    - Client bid creation and tracking views.
    - Owner bid review/decision views.

- **ContractController / LeaseController**
  - Endpoints:
    - `POST /bids/{id}/contracts` – create contract (lease, rental, or sale) from approved bid.
    - `GET /contracts` – list contracts (client/owner view) with **cursor-based pagination**.
    - `GET /contracts/{id}` – contract details.
    - `POST /contracts/{id}/sign-client` – client signs contract.
    - `POST /contracts/{id}/sign-owner` – owner signs contract.
  - Responsibilities:
    - Generate contract records from bids, setting `contractType` appropriately for rental, lease, or sale.
    - Enforce that only authorized parties can sign.
    - Update contract status and office-space status accordingly (e.g., mark space as `LEASED` or `SOLD`).
  - Why this design:
    - Separates legal contract logic from negotiation and payment concerns while supporting multiple transaction types in a unified way.
    - Makes it easy to plug in different signature and document storage mechanisms for leases, rentals, and sale agreements.
  - Where used:
    - Client/owner contract views for signing and reviewing lease/rental/sale details.

### 3.4 Visit & Scheduling Controllers

- **VisitController**
  - Endpoints:
    - `POST /spaces/{id}/visits` – create private visit booking (client or sales rep).
    - `GET /visits` – list visits (filtered by role: client sees own visits, sales rep sees assigned visits, manager sees subordinate visits).
    - `GET /visits/{id}` – visit details.
    - `PATCH /visits/{id}` – update visit (status, time, notes).
    - `POST /visits/{id}/cancel` – cancel visit.
    - `POST /visits/{id}/confirm` – confirm visit (sales rep/manager).
    - `GET /spaces/{id}/visits/available-slots` – get available time slots for a date (conflict detection).
  - Responsibilities:
    - Validate visit booking requests and check for conflicts (same day, same space, overlapping times).
    - Enforce hierarchy rules (sales rep visits may require manager approval if configured).
    - Trigger notifications for visit confirmations, reminders, and cancellations.
  - Why this design:
    - Centralizes visit scheduling logic with conflict detection.
    - Supports different user roles (client, sales rep, manager) with appropriate access levels.
    - Integrates with hierarchy system for oversight and approval workflows.
  - Where used:
    - Client space detail views for booking visits.
    - Sales rep dashboards for managing assigned visits.
    - Manager dashboards for overseeing visit activities.

### 3.5 Payment & Notification Controllers

- **PaymentController**
  - Endpoints:
    - `POST /contracts/{id}/payments` – create or update payment schedule entries / record payments for a contract (lease, rental, or sale).
    - `GET /payments` – list payments for current user (supports filters like `upcoming=true`) with **cursor-based pagination**.
    - `GET /payments/{id}` – payment details.
  - Responsibilities:
    - Manage payment schedule generation and updates (including EMI/installment plans) per contract.
    - Record payments that happened outside the platform (bank transfer, cheque, external gateways).
    - Update `PaymentModel` and `LeaseModel` status when payments are marked as received.
    - Expose payment history and **future scheduled payments (based on `dueDate`)** for both clients and owners.
  - Why this design:
    - Treats the backend as the **source of truth for payment schedules and statuses**, not as a direct payment processor.
    - Cleanly separates **billing schedule and tracking** concerns into a single layer that can optionally integrate with external gateways if needed later.
  - Where used:
    - Payment sections on lease detail views, upcoming-bills widgets on dashboards, and any back-office flows that reconcile payments.

- **NotificationController**
  - Endpoints:
    - `GET /notifications` – list notifications for current user with **cursor-based pagination**.
    - `POST /notifications/{id}/read` – mark as read.
  - Responsibilities:
    - Fetch notifications per user.
    - Update read flags.
  - Why this design:
    - Provides a dedicated surface for building notification centers and badges.
    - Makes it easy to extend with filters (unread, type) later.
  - Where used:
    - Notification bell, notification list panels, and “mark as read” actions.

### 3.5 Admin / Super Admin Controllers

- **AdminDashboardController**
  - Endpoints:
    - `GET /admin/overview` – high-level metrics.
    - `GET /admin/users` – list/search users.
  - Responsibilities:
    - Provide system-wide stats and management tools for super admins.
  - Why this design:
    - Keeps admin-only capabilities away from normal business controllers.
    - Matches typical requirement for a single “control plane” for ops.
  - Where used:
    - Internal admin console and operational dashboards.

---

## 4. Views (Presentation Layer)

> Views are UI pages/screens; implementation can be React/Next.js, etc., but conceptually they map to these logical views.

### 4.1 Public & Auth Views

- **Home / Landing View**
  - Purpose: Introduce platform, quick search, CTA to sign up/login.
  - Data: Featured buildings/spaces, marketing content.
  - Why this design:
    - Focuses on primary conversion actions (search and sign‑up).
  - Where used:
    - Entry point for new/anonymous users and marketing campaigns.

- **Login View**
  - Fields: email, password.
  - Actions: login, forgot password (if implemented later).
  - Why this design:
    - Simple, minimal form mapped directly to `AuthController.login`.
  - Where used:
    - Access gate for all authenticated dashboards (client, owner, admin).

- **Registration View**
  - Separate paths or options for Client vs Owner.
  - Fields: basic profile + role selection.
  - Why this design:
    - Allows capturing different required fields per role while sharing the same auth backend.
  - Where used:
    - New account creation before accessing any protected functionality.

### 4.2 Client Views

- **Client Dashboard View**
  - Shows: active leases, bids (with status), **upcoming bills (next scheduled payments)**, notifications.
  - Why this design:
    - Gives a single “home base” for the client’s current commitments and actions.
  - Where used:
    - Default landing after client login.

- **Space Search/List View**
  - Filters: location, size, price, availability, basic amenities.
  - Results: cards with key details and “View Details” action.
  - Why this design:
    - Optimized for fast discovery and comparison of multiple spaces.
  - Where used:
    - Main discovery flow before viewing specific space details or placing bids.

- **Space Detail View**
  - Space information, images, pricing, availability.
  - Actions: “Place Bid”, “Add to Favourites” (if implemented), “Contact Owner”.
  - Why this design:
    - Concentrates all decision-making information and the main CTA (Place Bid) on one screen.
  - Where used:
    - Entry point to the bidding workflow for clients.

- **Bid List & Detail Views**
  - List: all bids with statuses.
  - Detail: bid history, messages, owner responses, actions (accept counter, withdraw, etc.).
  - Why this design:
    - Clearly separates overview (list) from deep inspection (detail) of negotiations.
  - Where used:
    - Client’s “My Bids” area connected to `BidController` endpoints.

- **Lease Detail View**
  - Shows: lease terms, status, **payment schedule (future and past payments)**, download document.
  - Actions: sign (if pending), pay, view invoices.
  - Why this design:
    - Single place to manage the full lifecycle of a lease from the client side.
  - Where used:
    - Linked from client dashboard and notifications about leases.

### 4.3 Owner Views

- **Owner Dashboard View**
  - Cards: number of buildings, spaces, active bids, active leases, **upcoming income (sum of future due payments)**.
  - Quick links: “Add Building”, “View Bids”.
  - Why this design:
    - Gives owners a quick snapshot of performance and urgent tasks.
  - Where used:
    - Default landing after owner login.

- **Building & Floor Management Views**
  - Building List / Detail: manage building info.
  - Floor List / Detail: manage floors for a building.
  - Why this design:
    - Mirrors the real-world hierarchy owners think in (portfolio → buildings → floors).
  - Where used:
    - Management flows backed by `BuildingController` and `FloorController`.

- **Space Management Views**
  - Space List (by building/floor).
  - Forms to create/edit spaces, upload images, set pricing and availability.
  - Why this design:
    - Streamlines bulk operations on spaces within a specific context (building/floor).
  - Where used:
    - Owner tools for configuring listings consumed by client search.

- **Owner Bid Management View**
  - List bids grouped by space/status.
  - Detail page for each bid with approve/reject/counter actions.
  - Why this design:
    - Organizes negotiations around spaces, which matches how owners think about inventory.
  - Where used:
    - Interfaces with `BidController` actions for decision-making.

- **Owner Lease Management View**
  - List of leases, filter by status.
  - Detail with ability to sign and track payments, including **planned payment schedules and projected income**.
  - Why this design:
    - Central place to oversee contractual obligations and financial status.
  - Where used:
    - Connected to `LeaseController` and `PaymentController` for owners.

### 4.4 Admin Views

- **Admin Overview View**
  - High-level system metrics: total users, buildings, spaces, bids, leases, payments.
  - Why this design:
    - Gives super admins immediate visibility into platform health and usage.
  - Where used:
    - Back-office / internal admin console.

- **User Management View**
  - Search and inspect user accounts, activate/deactivate users.
  - Why this design:
    - Supports operational tasks like handling abuse, troubleshooting, and onboarding owners.
  - Where used:
    - Admin flows tied to `AdminDashboardController` and user management endpoints.

---

## 5. MVC Flow Examples

### 5.1 Place Bid Flow (Client)

1. **View:** Client opens `SpaceDetailView` and clicks “Place Bid”.
2. **Controller:** `BidController.create` validates input and permissions.
3. **Model:** `BidModel` creates new bid; `NotificationModel` records notifications.
4. **View:** Client is redirected to `BidDetailView` with status “Pending”; owner sees new bid in `OwnerBidManagementView`.

### 5.2 Approve Bid and Generate Lease (Owner)

1. **View:** Owner opens `OwnerBidManagementView` and selects a pending bid.
2. **Controller:** `BidController.approve` changes bid status and calls `LeaseController.createFromBid`.
3. **Model:** `LeaseModel` is created, `SpaceModel` status may move to `RESERVED`, `NotificationModel` stores client notification.
4. **View:** Owner sees lease in `OwnerLeaseManagementView`; client sees new lease in `ClientDashboardView`.

### 5.3 Payment for Lease

1. **View:** Client opens `LeaseDetailView` and clicks “Pay”.
2. **Controller:** `PaymentController.initiate` creates a `PaymentModel` and redirects to/payment widget.
3. **Model:** Payment gateway callback hits `PaymentController.webhook`, which updates `PaymentModel` and possibly `LeaseModel` status.
4. **View:** Client sees updated payment and lease status; email/notification sent.

---

## 6. Separation of Concerns Guidelines

- **Models** should not know about HTTP or UI; they encapsulate data and core business rules.
- **Controllers** should be thin coordinators: validate, call services/models, handle errors, choose view/response.
- **Views** should not contain business logic; only presentation logic and basic input validation.
- Shared logic between controllers should live in **service classes** (e.g., `BidService`, `LeaseService`, `PaymentService`) that sit between controllers and models.

---

## 8. API Endpoint Mapping

This section maps MVC Controllers to the API endpoints defined in the [API Documentation](../Documentation/API-Documentation.md).

### 8.1 Auth & User Controllers

| Controller Method | API Endpoint | HTTP Method | Request Body | Response |
|-------------------|--------------|-------------|--------------|----------|
| `AuthController.register` | `/api/v1/auth/register` | POST | `{ email, password, role, ... }` | `{ data: { user, token } }` |
| `AuthController.login` | `/api/v1/auth/login` | POST | `{ email, password }` | `{ data: { user, token } }` |
| `AuthController.logout` | `/api/v1/auth/logout` | POST | - | `{ data: { success: true } }` |
| `AuthController.refreshToken` | `/api/v1/auth/refresh-token` | POST | `{ refreshToken }` | `{ data: { token } }` |
| `UserController.getMe` | `/api/v1/users/me` | GET | - | `{ data: { user } }` |
| `UserController.updateMe` | `/api/v1/users/me` | PUT | `{ name, phone, ... }` | `{ data: { user } }` |

### 8.2 Building & Space Controllers

| Controller Method | API Endpoint | HTTP Method | Request Body | Response |
|-------------------|--------------|-------------|--------------|----------|
| `BuildingController.create` | `/api/v1/buildings` | POST | `{ name, address, totalFloors, ... }` | `{ data: { building } }` |
| `BuildingController.list` | `/api/v1/buildings` | GET | Query: `?cursor=&limit=` | `{ data: [buildings], meta: { cursor } }` |
| `BuildingController.getById` | `/api/v1/buildings/{id}` | GET | - | `{ data: { building } }` |
| `BuildingController.update` | `/api/v1/buildings/{id}` | PUT | `{ name, ... }` | `{ data: { building } }` |
| `FloorController.create` | `/api/v1/buildings/{id}/floors` | POST | `{ floorNumber, totalSqft, ... }` | `{ data: { floor } }` |
| `OfficeSpaceController.create` | `/api/v1/floors/{id}/spaces` | POST | `{ name, grossSqft, isLeasable, ... }` | `{ data: { space } }` |
| `OfficeSpaceController.search` | `/api/v1/spaces` | GET | Query: `?building_id=&is_leasable=true&cursor=` | `{ data: [spaces], meta: { cursor } }` |
| `OfficeSpaceController.getById` | `/api/v1/spaces/{id}` | GET | - | `{ data: { space } }` |

### 8.3 Bidding & Contract Controllers

| Controller Method | API Endpoint | HTTP Method | Request Body | Response |
|-------------------|--------------|-------------|--------------|----------|
| `BidController.create` | `/api/v1/spaces/{id}/bids` | POST | `{ bidAmount, leaseTermMonths, ... }` | `{ data: { bid } }` |
| `BidController.list` | `/api/v1/bids` | GET | Query: `?space_id=&status=&cursor=` | `{ data: [bids], meta: { cursor } }` |
| `BidController.approve` | `/api/v1/bids/{id}/approve` | POST | `{ notes }` | `{ data: { bid, contract } }` |
| `BidController.reject` | `/api/v1/bids/{id}/reject` | POST | `{ reason }` | `{ data: { bid } }` |
| `BidController.counter` | `/api/v1/bids/{id}/counter` | POST | `{ counterAmount, message }` | `{ data: { bid } }` |
| `ContractController.createFromBid` | `/api/v1/bids/{id}/contracts` | POST | `{ contractType, ... }` | `{ data: { contract } }` |
| `ContractController.list` | `/api/v1/contracts` | GET | Query: `?space_id=&status=&cursor=` | `{ data: [contracts], meta: { cursor } }` |
| `ContractController.signClient` | `/api/v1/contracts/{id}/sign-client` | POST | `{ signature }` | `{ data: { contract } }` |

### 8.4 Payment & Notification Controllers

| Controller Method | API Endpoint | HTTP Method | Request Body | Response |
|-------------------|--------------|-------------|--------------|----------|
| `PaymentController.createSchedule` | `/api/v1/contracts/{id}/payments` | POST | `{ paymentType, installments, ... }` | `{ data: { payments: [...] } }` |
| `PaymentController.list` | `/api/v1/payments` | GET | Query: `?contract_id=&status=&cursor=` | `{ data: [payments], meta: { cursor } }` |
| `PaymentController.recordPayment` | `/api/v1/payments/{id}/record` | POST | `{ paidAt, transactionRef, ... }` | `{ data: { payment } }` |
| `NotificationController.list` | `/api/v1/notifications` | GET | Query: `?unread=true&cursor=` | `{ data: [notifications], meta: { cursor } }` |
| `NotificationController.markRead` | `/api/v1/notifications/{id}/read` | POST | - | `{ data: { notification } }` |

---

## 9. Database Model Mapping

This section maps MVC Models to the database schema defined in [Database Schema](../Documentation/Database-Schema.md).

### 9.1 Model to Table Mapping

| MVC Model | Database Table | Key Fields | Relationships |
|-----------|---------------|------------|---------------|
| `UserModel` | `users` | `id`, `email`, `role`, `password_hash` | - |
| `BuildingModel` | `buildings` | `id`, `owner_id`, `name`, `address`, `total_floors` | `owner_id → users.id` |
| `FloorModel` | `floors` | `id`, `building_id`, `floor_number`, `total_sqft`, `common_area_sqft` | `building_id → buildings.id` |
| `OfficeSpaceModel` | `spaces` | `id`, `floor_id`, `gross_sqft`, `usable_sqft`, `is_leasable`, `usage_type` | `floor_id → floors.id` |
| `BidModel` | `bids` | `id`, `space_id`, `client_id`, `bid_amount`, `status`, `transaction_type` | `space_id → spaces.id`, `client_id → users.id` |
| `ContractModel` | `contracts` | `id`, `space_id`, `client_id`, `contract_type`, `start_date`, `end_date` | `space_id → spaces.id`, `client_id → users.id` |
| `PaymentModel` | `payments` | `id`, `contract_id`, `payer_id`, `amount`, `due_date`, `status`, `installment_number` | `contract_id → contracts.id`, `payer_id → users.id` |
| `NotificationModel` | `notifications` | `id`, `user_id`, `type`, `title`, `message`, `channel`, `is_read` | `user_id → users.id` |

### 9.2 ORM Implementation Notes

**Recommended ORM:** Prisma or TypeORM for TypeScript/Node.js

**Example Prisma Schema Snippet:**
```prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  role      String
  buildings Building[]
  bids      Bid[]
  contracts Contract[]
  payments  Payment[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Building {
  id         String   @id @default(uuid())
  ownerId    String
  owner      User     @relation(fields: [ownerId], references: [id])
  floors     Floor[]
  totalFloors Int
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
}

model Space {
  id          String   @id @default(uuid())
  floorId     String
  floor       Floor    @relation(fields: [floorId], references: [id])
  isLeasable  Boolean  @default(true)
  usageType   String
  grossSqft   Decimal
  usableSqft  Decimal
  bids        Bid[]
  contracts   Contract[]
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}
```

### 9.3 Query Optimization Patterns

- **Eager Loading:** Use `include` or `relations` to load related entities in one query
- **Selective Fields:** Only fetch required fields for list views
- **Cursor Pagination:** Use `id > cursor` pattern for efficient pagination
- **Indexed Queries:** Ensure all foreign keys and filter fields are indexed

---

## 10. Service Layer Patterns

While MVC provides the basic structure, complex business logic should live in **Service classes** that sit between Controllers and Models.

### 10.1 Service Layer Architecture

```
Controller → Service → Model → Database
           ↓
        External APIs
        (Payment, Email, etc.)
```

### 10.2 Core Services

#### BidService
**Responsibilities:**
- Validate bid business rules
- Calculate bid scores (AI integration)
- Check auto-approval conditions
- Handle bid status transitions
- Trigger notifications

**Example:**
```typescript
class BidService {
  async createBid(spaceId: string, clientId: string, bidData: BidInput) {
    // 1. Validate space availability
    const space = await SpaceModel.findById(spaceId);
    if (space.availabilityStatus !== 'AVAILABLE') {
      throw new Error('Space not available');
    }
    
    // 2. Check for duplicate bids
    const existingBid = await BidModel.findActiveBySpaceAndClient(spaceId, clientId);
    if (existingBid) {
      throw new Error('Active bid already exists');
    }
    
    // 3. Get AI suggestion
    const aiSuggestion = await AIService.getBidSuggestion(spaceId, bidData.bidAmount);
    
    // 4. Create bid
    const bid = await BidModel.create({
      ...bidData,
      spaceId,
      clientId,
      aiSuggestion,
      status: 'PENDING'
    });
    
    // 5. Trigger notifications
    await NotificationService.sendBidCreated(bid);
    
    // 6. Emit WebSocket event
    await WebSocketService.emit('bid:created', bid);
    
    return bid;
  }
}
```

#### LeaseService
**Responsibilities:**
- Generate lease documents from templates
- Apply jurisdiction-specific rules
- Manage lease lifecycle
- Handle renewals
- Generate payment schedules

#### PaymentService
**Responsibilities:**
- Generate payment schedules (EMI/installments)
- Calculate due dates
- Track payment status
- Generate invoices/receipts
- Handle payment recording

#### NotificationService
**Responsibilities:**
- Route notifications to appropriate channels
- Manage user preferences
- Handle delivery failures
- Track read receipts

### 10.3 Service Dependencies

```
BidService
  ├── SpaceService (validate availability)
  ├── AIService (get suggestions)
  ├── NotificationService (send alerts)
  └── WebSocketService (real-time updates)

LeaseService
  ├── BidService (get approved bid data)
  ├── DocumentService (generate contract)
  ├── PaymentService (create schedule)
  └── NotificationService (send lease)

PaymentService
  ├── ContractService (get contract terms)
  ├── InvoiceService (generate invoices)
  └── NotificationService (payment reminders)
```

### 10.4 Error Handling in Services

```typescript
class ServiceError extends Error {
  constructor(
    public code: string,
    public message: string,
    public statusCode: number = 400
  ) {
    super(message);
  }
}

// Usage in service
if (!space.isLeasable) {
  throw new ServiceError(
    'SPACE_NOT_LEASABLE',
    'This space is not available for leasing',
    400
  );
}
```

---

## 7. Production & Performance Considerations

- **Validation & Security**
  - Use Fastify’s schema-based validation for all request bodies, params, and responses.
  - Centralized auth/authorization middleware to enforce roles on controllers.
- **Performance**
  - Apply caching where appropriate (e.g., building/space metadata, configuration lists).
  - Use **cursor-based (keyset) pagination** and filtering on all list endpoints (spaces, bids, leases, payments, notifications, reports).
  - Optimize N+1 patterns by using efficient ORM queries and batching where needed.
- **Error Handling & Logging**
  - Global error handler translating technical exceptions into clean API errors.
  - Structured logging in controllers/services with correlation IDs.
- **Rate Limiting & Throttling**
  - Rate limit sensitive endpoints (auth, bids, payments, notifications) at the Fastify plugin/middleware layer.
  - Backpressure handling for WebSockets and streaming endpoints.

---

## 11. Quick Reference

### Controller → API Endpoint Quick Map

| Controller | Base Path | Key Endpoints |
|------------|-----------|---------------|
| `AuthController` | `/api/v1/auth` | `/register`, `/login`, `/logout`, `/refresh-token` |
| `UserController` | `/api/v1/users` | `/me` (GET, PUT) |
| `BuildingController` | `/api/v1/buildings` | `/` (GET, POST), `/{id}` (GET, PUT, DELETE) |
| `FloorController` | `/api/v1/buildings/{id}/floors` | `/` (GET, POST), `/{id}` (GET, PUT) |
| `OfficeSpaceController` | `/api/v1/spaces` | `/` (GET, POST), `/{id}` (GET, PUT), `/search` |
| `BidController` | `/api/v1/bids` | `/` (GET, POST), `/{id}` (GET), `/{id}/approve`, `/{id}/reject`, `/{id}/counter` |
| `ContractController` | `/api/v1/contracts` | `/` (GET, POST), `/{id}` (GET), `/{id}/sign-client`, `/{id}/sign-owner` |
| `VisitController` | `/api/v1/visits` | `/` (GET, POST), `/{id}` (GET, PATCH), `/{id}/cancel`, `/{id}/confirm`, `/spaces/{id}/available-slots` |
| `PaymentController` | `/api/v1/payments` | `/` (GET, POST), `/{id}` (GET), `/{id}/record` |
| `NotificationController` | `/api/v1/notifications` | `/` (GET), `/{id}/read` |
| `RoleHierarchyController` | `/api/v1/admin/role-hierarchy` | `/config` (GET, POST), `/config/{id}` (PATCH), `/relationships` (GET, POST, DELETE) |

### Model → Database Table Quick Map

| Model | Table | Primary Key | Key Foreign Keys |
|-------|-------|-------------|------------------|
| `UserModel` | `users` | `id` (UUID) | - |
| `BuildingModel` | `buildings` | `id` (UUID) | `owner_id → users.id` |
| `FloorModel` | `floors` | `id` (UUID) | `building_id → buildings.id` |
| `OfficeSpaceModel` | `spaces` | `id` (UUID) | `floor_id → floors.id` |
| `BidModel` | `bids` | `id` (UUID) | `space_id → spaces.id`, `client_id → users.id` |
| `ContractModel` | `contracts` | `id` (UUID) | `space_id → spaces.id`, `client_id → users.id`, `owner_id → users.id` |
| `PrivateVisitModel` | `private_visits` | `id` (UUID) | `space_id → spaces.id`, `client_id → users.id`, `sales_rep_id → users.id` |
| `PaymentModel` | `payments` | `id` (UUID) | `contract_id → contracts.id`, `payer_id → users.id` |
| `NotificationModel` | `notifications` | `id` (UUID) | `user_id → users.id` |
| `RoleHierarchyConfigModel` | `role_hierarchy_config` | `id` (UUID) | - |
| `UserRoleHierarchyModel` | `user_role_hierarchy` | `id` (UUID) | `parent_user_id → users.id`, `child_user_id → users.id`, `hierarchy_config_id → role_hierarchy_config.id` |

### Common Patterns

**Pagination Pattern:**
```typescript
// Controller
const { cursor, limit = 20 } = req.query;
const result = await ModelService.list({ cursor, limit });
res.json({ data: result.items, meta: { cursor: result.nextCursor, hasMore: result.hasMore } });
```

**Authorization Pattern:**
```typescript
// Middleware
if (req.user.role !== 'OWNER' || req.user.id !== building.ownerId) {
  throw new ForbiddenError('Not authorized');
}
```

**Service Call Pattern:**
```typescript
// Controller
try {
  const result = await BidService.createBid(spaceId, userId, bidData);
  res.status(201).json({ data: result });
} catch (error) {
  if (error instanceof ServiceError) {
    res.status(error.statusCode).json({ error: { code: error.code, message: error.message } });
  } else {
    res.status(500).json({ error: { message: 'Internal server error' } });
  }
}
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-02  
**Related Documents:** [Software Requirements Specification](../Final%20Requirements/SRS-Complete.md), [Application Workflow](./Application-Workflow.md)


