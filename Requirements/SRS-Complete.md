# Software Requirements Specification
## Neorem Platform

**Version:** 2.0  
**Date:** 2025-01-27  
**Document Type:** Software Requirements Specification  
**Target Audience:** Development Team

---

## Table of Contents

1. [Purpose](#1-purpose)
2. [Scope](#2-scope)
3. [Users & Roles](#3-users--roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Data Specifications](#6-data-specifications)
7. [Interface Requirements](#7-interface-requirements)
8. [Assumptions & Constraints](#8-assumptions--constraints)
9. [Acceptance Criteria](#9-acceptance-criteria)
10. [System Architecture](#10-system-architecture)

---

## 1. Purpose

### 1.1 Project Overview

Neorem is a cloud-based SaaS platform for managing multi-floor commercial and residential property leasing, renting, and sales. The system serves property owners, brokers, tenants, property managers, and administrators. The platform supports both commercial office spaces and residential housing units, with comprehensive parking management, flexible role hierarchies, and dynamic API capabilities.

### 1.2 Primary Objectives

- Streamline commercial real estate transactions from discovery to contract execution
- Optimize occupancy and revenue through pricing tools and availability management
- Enhance user experience with AI recommendations, virtual tours, and real-time updates
- Automate business processes including lease generation, payment tracking, and notifications
- Enable data-driven decisions through analytics, forecasting, and reporting

### 1.3 Key Capabilities

- Real-time bidding with WebSocket notifications
- AI-powered pricing and space recommendations
- Automated lease document generation
- Multi-building, multi-floor space management
- Payment schedule tracking and invoicing
- AR/VR virtual tours and 3D floor plans
- Advanced analytics dashboards
- Multi-channel notifications (email, WhatsApp, push, in-app)

---

## 2. Scope

### 2.1 In Scope

#### Core Leasing Operations
- Multi-building, multi-floor space management with real-time availability
- Support for commercial, residential, and mixed-use properties
- Support for leasable spaces (offices, residential units, canteens) and non-leasable spaces (restrooms, storage, corridors)
- Canteen management with contract-based or lent agreements (can be leased to third parties)
- Real-time bidding with WebSocket notifications
- Automated lease document generation
- Payment schedule tracking and invoicing (scheduled, due, overdue, paid)
- Support for lease, rental, and sale transaction types
- Parking space management with client/owner assignment tracking

#### User Management
- Multi-role access control (Owners, Clients, Brokers, Agents, Support, Super Admin)
- Authentication (email/password, OAuth2, biometric)
- User profiles with activity tracking
- Multi-tenant organization support

#### Property Management
- Building, floor, and space management with bulk operations
- Property type support: Commercial, Residential, Mixed-Use
- Automatic floor generation on building creation
- Advanced search and filtering (location, size, price, amenities, property type, ESG ratings)
- Parking space assignment and availability tracking
- AI-powered property recommendations (vector-based similarity matching only)
- Map integration with heatmaps and commute time calculator

#### Financial Tracking
- Payment schedule generation (EMI/installment plans)
- Multi-currency support for recorded amounts
- Track external payments (bank transfers, cheques, external gateways)
- Automated invoicing and receipts
- Integration with accounting/ERP systems (QuickBooks, Zoho, SAP)

#### Analytics and Reporting
- Real-time dashboards (occupancy, revenue, bid statistics)
- Occupancy heatmaps (building, floor, space level)
- Exportable reports (CSV, PDF, Excel)
- AI-powered pricing suggestions and occupancy forecasting

#### Communication
- Multi-channel notifications (email, WhatsApp, push, in-app)
- In-app messaging and chat
- Automated event notifications

#### Advanced Features (Phased)
- AR/VR virtual tours and 3D floor plans
- AI-powered space planning
- IoT integration for smart building sensors
- Multi-language and multi-currency support (Phase 3+)

### 2.2 Out of Scope

#### Payment Processing
- **No direct payment processing** — tracks payments made outside the platform only
- No credit card processing, payment gateways, or escrow management

#### Property Operations (Phase 1-2)
- No maintenance work orders, facility management, or vendor scheduling
- No tenant services portal

#### Marketing and CRM (Phase 1-2)
- No marketing automation, lead scoring, or CRM pipeline management
- No third-party listing syndication

#### Legal and Compliance (Phase 1-2)
- No automated legal compliance checking
- No jurisdiction-specific legal clause libraries
- No regulatory reporting

#### Advanced Features (Phase 1-3)
- No blockchain smart contracts
- No digital twin technology
- No sustainability/carbon footprint tracking
- No white-label options (Phase 1-2)

#### Technical Limitations
- No offline mode (Phase 1-2)
- No voice/gesture control
- No API marketplace (Phase 1-2)
- Manual data import only (no automatic legacy system integration)
- Limited real-time sync (polling/batch sync for some integrations)

### 2.3 Phase-Based Scope

**Phase 1 (MVP - 3-4 months):** Core foundation — Auth, Buildings, Spaces, Basic Dashboards, Search  
**Phase 2 (4-5 months):** Bidding, Leasing, Payment Tracking, Notifications  
**Phase 3 (3-4 months):** AI, CRM, Advanced Analytics, Multi-language/currency  
**Phase 4+ (Ongoing):** AR/VR, IoT, Enhanced features, Optional modules

**Note:** This scope is fixed for Phase 1. Features beyond Phase 1 are subject to approval and prioritization.

---

## 3. Users & Roles

### 3.1 Role Definitions

#### Client / Tenant
Search and lease office spaces. Capabilities: search/filter spaces, map view, space comparison, virtual tours, AI recommendations, book private visits (with automatic conflict detection), view scheduled visits, place/track bids, view leases and payment schedules, download contracts, rate and review.

#### Building Owner / Admin
Manage property portfolio and maximize occupancy/revenue. Capabilities: manage buildings/floors/spaces (bulk operations), set pricing with AI suggestions, view occupancy/revenue dashboards and heatmaps, approve/reject/counter bids, auto-generate leases, track metrics, delegate permissions, export reports.

#### Sales Representative / Broker
Manage client relationships and facilitate deals. Capabilities: manage leads and pipeline, conduct virtual tours, in-app messaging, process applications, track commissions, CRM tools, schedule private visits with conflict detection, manage assigned visits. Note: Reports to Assistant Manager when Assistant Manager exists, otherwise reports directly to Manager (enforced by configurable role hierarchy).

#### Manager (Property Manager)
Oversee day-to-day building operations and sales team. Capabilities: coordinate maintenance, manage tenant relationships, track service requests, monitor occupancy/utilization, coordinate vendors, oversee Sales Reps and Assistant Managers, approve visits (if hierarchy requires), view team performance metrics, manage visit schedules for subordinates. Reports to Owner. Can optionally create Assistant Manager based on operational needs.

#### Assistant Manager
Assist Property Manager with day-to-day operations. Capabilities: manage service requests (limited authority), view occupancy and utilization metrics, coordinate vendors (with manager approval), access building and space information (read-only for sensitive data), generate operational reports (limited scope). Reports to Manager. Optional role created based on Owner or Manager's need. When exists, oversees Sales Rep team directly; when not present, Sales Rep team reports to Manager.

#### Support / Agent
Assist users with inquiries and issues. Capabilities: client support, limited data access, manage communications and escalations, track tasks, view support metrics.

#### Financial Officer
Manage financial operations and reporting. Capabilities: track payment schedules and status, generate invoices/receipts, financial reports, multi-currency transactions, export to accounting systems, monitor trends.

#### System Administrator / Super Admin
Configure and maintain platform-wide settings. Capabilities: platform configuration, user/role/permission management, system monitoring, audit logs, multi-tenant management, integration configuration, global policies.

### 3.2 Access Control

Role-based access control (RBAC) enforces granular permissions ensuring users access only authorized features and data.

---

## 4. Functional Requirements

### 4.1 User Management & Authentication

**FR-1.1** The system shall allow users to register with email, password, name, role, and phone number.  
**FR-1.2** The system shall allow users to log in with email and password.  
**FR-1.3** The system shall allow users to reset their password via email.  
**FR-1.4** The system shall support OAuth2 authentication (Google, LinkedIn).  
**FR-1.5** The system shall support biometric authentication (FaceID/TouchID).  
**FR-1.6** The system shall require two-factor authentication when enabled.  
**FR-1.7** The system shall lock accounts after 5 failed login attempts for 15 minutes.  
**FR-1.8** The system shall allow users to view and update their profile information.  
**FR-1.9** The system shall assign users to one of the following roles: Super Admin, Owner, Client, Broker, Agent, Support, Manager, Assistant Manager, or Sales Rep.  
**FR-1.10** The system shall enforce role-based access control for all features.

### 4.2 Building & Floor Management

**FR-2.1** The system shall allow owners to create buildings with name, address, coordinates, total floors, and property type (COMMERCIAL, RESIDENTIAL, MIXED_USE).  
**FR-2.2** The system shall automatically create floor records (1 to N) when a building is created.  
**FR-2.3** The system shall allow owners to update building information including property type.  
**FR-2.4** The system shall allow owners to update floor square footage and amenities.  
**FR-2.5** The system shall calculate net leasable square footage as total square footage minus common area square footage.  
**FR-2.6** The system shall support leasable spaces (offices, residential units, canteens) and non-leasable spaces (restrooms, storage, corridors) in floor planning.  
**FR-2.7** The system shall support canteen spaces that can be leased to third parties (contract-based or lent agreements).  
**FR-2.8** The system shall allow parking space management with assignment to clients/owners or contracts.  
**FR-2.9** The system shall track parking availability and assignments separately from space availability.

### 4.3 Space Management

**FR-3.1** The system shall allow owners to create spaces with square footage, pricing, amenities, and usage type.  
**FR-3.2** The system shall allow owners to mark spaces as leasable or non-leasable.  
**FR-3.3** The system shall allow owners to upload images, videos, and 3D models for spaces.  
**FR-3.4** The system shall allow owners to update space information and pricing.  
**FR-3.5** The system shall allow owners to set space availability status (Available, Occupied, Maintenance, Reserved).  
**FR-3.6** The system shall exclude non-leasable spaces from client search results.

### 4.4 Search & Discovery

**FR-4.1** The system shall allow clients to search spaces by location, size, price, amenities, property type (COMMERCIAL, RESIDENTIAL, MIXED_USE), and availability.  
**FR-4.2** The system shall display spaces on an interactive map with property markers.  
**FR-4.3** The system shall allow clients to filter spaces by building, floor, square footage, price range, property type, amenities, and parking availability.  
**FR-4.4** The system shall allow clients to compare multiple spaces side-by-side.  
**FR-4.5** The system shall return only leasable spaces in client search results.  
**FR-4.6** The system shall use cursor-based pagination for all list endpoints.  
**FR-4.7** The system shall support dynamic field selection, filtering, and sorting via query parameters.

### 4.5 Private Visit Booking

**FR-5.1** The system shall allow clients to book private visits for spaces.  
**FR-5.2** The system shall prevent scheduling conflicts when two visits occur on the same day for the same space (no overlapping time ranges).  
**FR-5.3** The system shall detect and prevent time overlaps between visits scheduled for the same space on the same date.  
**FR-5.4** The system shall suggest alternative available time slots when a conflict is detected.  
**FR-5.5** The system shall allow sales representatives to book visits on behalf of clients.  
**FR-5.6** The system shall track visit status (SCHEDULED, CONFIRMED, COMPLETED, CANCELLED, NO_SHOW).  
**FR-5.7** The system shall support different visit types (PRIVATE, GROUP, VIRTUAL).  
**FR-5.8** The system shall send visit confirmation notifications to clients and assigned sales representatives.  
**FR-5.9** The system shall send visit reminder notifications (24 hours and 1 hour before scheduled time).  
**FR-5.10** The system shall allow clients to view their scheduled visits and visit history.  
**FR-5.11** The system shall allow sales representatives to view and manage visits assigned to them.  
**FR-5.12** The system shall allow managers to view all visits for their subordinate team members.  
**FR-5.13** The system shall automatically detect when a sales representative is on leave and postpone coordinated visits.  
**FR-5.14** The system shall automatically reschedule visits to the next available date/time for the same sales representative when they are on leave.  
**FR-5.15** The system shall notify clients about visit rescheduling due to sales representative unavailability.  
**FR-5.16** The system shall check sales representative availability before confirming visit bookings.  
**FR-5.17** The system shall track sales representative leave status and leave dates.  
**FR-5.18** The system shall restrict client access to visit details - clients can only see that they "were interested" in a property, not full visit management details.  
**FR-5.19** The system shall allow only Sales Reps, Managers, and Assistant Managers to see full visit details and management.  
**FR-5.20** The system shall show interest indicators on property details for clients instead of full visit information.

### 4.6 Parking Management

**FR-5.21** The system shall allow parking space creation and management per building.  
**FR-5.22** The system shall support parking space assignment to specific clients or owners.  
**FR-5.23** The system shall support parking space assignment linked to contracts/leases.  
**FR-5.24** The system shall track parking availability separately from space availability.  
**FR-5.25** The system shall support different parking types (STANDARD, RESERVED, HANDICAP, ELECTRIC_CHARGING).  
**FR-5.26** The system shall include parking information in property search filters.  
**FR-5.27** The system shall display parking assignments in property details.

### 4.7 Recycle Bin & Soft Delete System

**FR-5.28** The system shall implement soft delete for all database records (deleted_at, deleted_by fields).  
**FR-5.29** The system shall automatically exclude soft-deleted records from all queries by default.  
**FR-5.30** The system shall allow only Super Admin to access the recycle bin (view deleted records).  
**FR-5.31** The system shall allow only Super Admin to restore records from the recycle bin.  
**FR-5.32** The system shall allow only Super Admin to permanently delete records from the recycle bin.  
**FR-5.33** The system shall track who deleted each record and when (deleted_by, deleted_at).  
**FR-5.34** The system shall support bulk restore and bulk permanent delete operations (Super Admin only).  
**FR-5.35** The system shall implement automatic cleanup of deleted records after retention period (configurable, default 90 days).

### 4.8 Parent-Child Relationship Management

**FR-5.36** The system shall support parent-child relationships (buildings→floors→spaces, etc.).  
**FR-5.37** The system shall allow deletion strategy selection: detach (remove parent reference) or cascade (delete parent and children).  
**FR-5.38** The system shall prevent orphaned records when using detach strategy.  
**FR-5.39** The system shall show relationship warnings and confirmation dialogs before deletion.  
**FR-5.40** The system shall implement relationship integrity checks.

### 4.9 Dynamic API & Database Field Handling

**FR-5.41** The system shall support dynamic field selection via query parameters (fields=id,name,address.city).  
**FR-5.42** The system shall support dynamic filtering via query parameters (filter[property_type]=COMMERCIAL&filter[price][gte]=1000).  
**FR-5.43** The system shall support dynamic sorting via query parameters (sort=price:asc,created_at:desc).  
**FR-5.44** The system shall use database schema introspection for field validation.  
**FR-5.45** The system shall provide generic CRUD endpoints that adapt to schema changes without API modifications.  
**FR-5.46** The system shall provide schema endpoint to discover available fields and relations.  
**FR-5.47** The system shall validate requested fields against actual database schema.

### 4.10 Role Hierarchy & Management

**FR-5.48** The system shall support highly configurable role hierarchy relationships that adapt to each organization's structure.  
**FR-5.49** The system shall allow organizations to enable/disable roles per their needs (small companies may have only Owners, medium companies may have Owners + Managers, large companies may have multiple Managers, Assistant Managers, and Sales Reps).  
**FR-5.50** The system shall support multiple managers per organization.  
**FR-5.51** The system shall support multiple assistant managers per manager.  
**FR-5.52** The system shall support multiple sales reps per manager/assistant manager.  
**FR-5.53** The system shall provide organization-level role configuration UI.  
**FR-5.54** The system shall make hierarchy validation dynamic based on organization configuration.  
**FR-5.55** The system shall enforce hierarchical reporting structure: Owner → Manager → Assistant Manager (optional) → Sales Rep. Manager must always report to Owner. Assistant Manager is optional and reports to Manager when created. Sales Rep team reports to Assistant Manager when Assistant Manager exists, otherwise reports directly to Manager.  
**FR-5.56** The system shall allow enabling or disabling hierarchy rules per organization.  
**FR-5.57** The system shall support hierarchical approval workflows (e.g., Sales Rep actions requiring Manager or Assistant Manager approval based on hierarchy).  
**FR-5.58** The system shall allow managers and assistant managers to view and manage activities of subordinate team members (Sales Reps). Managers can view all subordinates including Assistant Managers and their Sales Rep teams.  
**FR-5.59** The system shall track hierarchical relationships between users in the `user_role_hierarchy` table.  
**FR-5.60** The system shall validate hierarchy rules when creating or assigning users to roles, implementing conditional logic to determine correct parent based on Assistant Manager existence.

### 4.11 Bidding & Negotiation

**FR-6.1** The system shall allow clients to place bids on available spaces.  
**FR-6.2** The system shall send real-time bid notifications to space owners via WebSockets.  
**FR-6.3** The system shall allow owners to approve, reject, or counter bids.  
**FR-6.4** The system shall track bid status (Pending, Approved, Rejected, Counter-Offered, Withdrawn).  
**FR-6.5** The system shall prevent duplicate bids from the same client on the same space.  
**FR-6.6** The system shall maintain bid history for each space and user.  
**FR-6.7** The system shall notify clients when their bid status changes.

### 4.12 Lease & Contract Management

**FR-7.1** The system shall automatically generate lease documents from approved bids.  
**FR-7.2** The system shall support lease, rental, and sale contract types.  
**FR-7.3** The system shall allow multi-party approval workflows for contracts.  
**FR-7.4** The system shall integrate with e-signature platforms (DocuSign, Adobe Sign).  
**FR-7.5** The system shall send lease expiration reminders (30, 60, 90 days before expiry).  
**FR-7.6** The system shall track contract status (Draft, Pending Signature, Active, Expired, Terminated).  
**FR-7.7** The system shall maintain contract versioning and audit logs.

### 4.13 Payment Tracking

**FR-8.1** The system shall generate payment schedules based on lease terms and EMI plans.  
**FR-8.2** The system shall track payment status (Scheduled, Due, Paid, Overdue, Cancelled).  
**FR-8.3** The system shall allow recording of payments made outside the platform (bank transfer, cheque, external gateway).  
**FR-8.4** The system shall generate invoices automatically based on recorded payments.  
**FR-8.5** The system shall support multi-currency payment tracking.  
**FR-8.6** The system shall track installment numbers and total installments for EMI plans.  
**FR-8.7** The system shall send payment due and overdue reminders.

### 4.14 Dashboards & Reporting

**FR-9.1** The system shall display owner dashboards with occupancy rates, revenue, active bids, and pending leases.  
**FR-9.2** The system shall display client dashboards with active bids, lease status, and upcoming payment schedule.  
**FR-9.3** The system shall display manager dashboards with team performance, visit statistics, and subordinate activities.  
**FR-9.4** The system shall show occupancy heatmaps at building, floor, and space levels.  
**FR-9.5** The system shall calculate and display upcoming income from scheduled payments.  
**FR-9.6** The system shall allow export of reports in CSV, PDF, and Excel formats.

### 4.15 Notifications

**FR-10.1** The system shall send notifications via email, WhatsApp, push, and in-app channels.  
**FR-10.2** The system shall send automated notifications for bid updates, lease milestones, payment events, and visit confirmations/reminders.  
**FR-10.3** The system shall allow users to configure notification preferences.  
**FR-10.4** The system shall mark notifications as read and unread.

### 4.12 AI & Analytics

**FR-11.1** The system shall provide AI-powered pricing suggestions for spaces.  
**FR-11.2** The system shall provide AI-powered space recommendations to clients based on preferences using vector similarity matching only.  
**FR-11.3** The system shall use pre-existing embedding models (OpenAI, Cohere, or open-source) for generating embeddings.  
**FR-11.4** The system shall store embeddings in a vector database (pgvector extension or external service like Pinecone/Weaviate).  
**FR-11.5** The system shall use cosine similarity or other vector distance metrics for recommendations.  
**FR-11.6** The system shall NOT create, train, or fine-tune new AI models.  
**FR-11.7** The system shall NOT implement custom ML pipelines or model training infrastructure.  
**FR-11.3** The system shall provide AI-suggested bid strategies to clients.  
**FR-11.4** The system shall calculate occupancy and revenue forecasts.  
**FR-11.5** The system shall calculate bid success probability scores.

### 4.13 Security & Compliance

**FR-12.1** The system shall encrypt data at rest using AES-256.  
**FR-12.2** The system shall encrypt data in transit using TLS 1.3.  
**FR-12.3** The system shall maintain audit logs for all user actions.  
**FR-12.4** The system shall track created_by and updated_by for all records.  
**FR-12.5** The system shall enforce session timeouts for inactive users.

### 4.14 Mobile Features

**FR-13.1** The system shall send push notifications to mobile devices.  
**FR-13.2** The system shall support QR code scanning for property details.  
**FR-13.3** The system shall support GPS-based property discovery.

### 4.15 Data Management

**FR-14.1** The system shall validate that gross square footage is greater than or equal to usable square footage.  
**FR-14.2** The system shall validate that floor numbers are unique per building.  
**FR-14.3** The system shall validate email format (RFC 5322 compliant).  
**FR-14.4** The system shall validate password strength (minimum 8 characters, 1 uppercase, 1 lowercase, 1 number).  
**FR-14.5** The system shall prevent duplicate email addresses during registration.

---

## 5. Non-Functional Requirements

### 5.1 Security

**NFR-1.1** The system shall encrypt all data at rest using AES-256 encryption.  
**NFR-1.2** The system shall encrypt all data in transit using TLS 1.3.  
**NFR-1.3** The system shall implement end-to-end encryption for sensitive communications.  
**NFR-1.4** The system shall enforce role-based access control (RBAC) for all features.  
**NFR-1.5** The system shall require two-factor authentication when enabled by users.  
**NFR-1.6** The system shall implement zero-trust security architecture.  
**NFR-1.7** The system shall perform regular security audits and penetration testing.  
**NFR-1.8** The system shall validate and sanitize all input on all API endpoints.  
**NFR-1.9** The system shall implement rate limiting on authentication, bidding, and payment-related endpoints.  
**NFR-1.10** The system shall store secrets in cloud-native secret stores (not in code or images).  
**NFR-1.11** The system shall enforce session timeouts for inactive users.  
**NFR-1.12** The system shall support IP whitelisting for administrative access.  
**NFR-1.13** The system shall perform regular access reviews and revocations.

### 5.2 Performance

**NFR-2.1** The system shall respond to API requests within 500ms for 95% of requests.  
**NFR-2.2** The system shall load pages within 2 seconds for 95% of requests.  
**NFR-2.3** The system shall return search results within 1 second.  
**NFR-2.4** The system shall deliver real-time updates with sub-100ms latency.  
**NFR-2.5** The system shall support 100,000+ concurrent users.  
**NFR-2.6** The system shall handle 10,000+ transactions per minute.  
**NFR-2.7** The system shall support 1 million+ property listings.  
**NFR-2.8** The system shall process 100,000+ daily active users.  
**NFR-2.9** The system shall implement cursor-based pagination on all list endpoints.  
**NFR-2.10** The system shall cache data at API and database levels.  
**NFR-2.11** The system shall use efficient database indexing and query design.

### 5.3 Reliability

**NFR-3.1** The system shall maintain 99.99% uptime (less than 8.76 hours downtime per year).  
**NFR-3.2** The system shall implement automated failover mechanisms.  
**NFR-3.3** The system shall implement database replication across availability zones.  
**NFR-3.4** The system shall implement circuit breaker patterns for external dependencies.  
**NFR-3.5** The system shall implement graceful degradation when non-critical features fail.  
**NFR-3.6** The system shall perform automated daily backups with 30-day retention.  
**NFR-3.7** The system shall support point-in-time recovery.  
**NFR-3.8** The system shall maintain a disaster recovery plan with RTO < 4 hours and RPO < 1 hour.  
**NFR-3.9** The system shall implement geographic redundancy across multiple regions.  
**NFR-3.10** The system shall implement health monitoring and alerting.  
**NFR-3.11** The system shall implement self-healing capabilities where possible.

### 5.4 Maintainability

**NFR-4.1** The system shall use a modular microservices architecture.  
**NFR-4.2** The system shall maintain 80%+ code coverage with unit and integration tests.  
**NFR-4.3** The system shall implement an automated CI/CD pipeline.  
**NFR-4.4** The system shall require code review for all changes.  
**NFR-4.5** The system shall provide OpenAPI/Swagger documentation for all external/public APIs.  
**NFR-4.6** The system shall implement structured, contextual logging with correlation IDs.  
**NFR-4.7** The system shall implement application performance monitoring (APM).  
**NFR-4.8** The system shall implement log aggregation and analysis.  
**NFR-4.9** The system shall implement real-time alerting for critical issues.  
**NFR-4.10** The system shall version all database migrations with rollback plans.  
**NFR-4.11** The system shall support blue/green or canary deployments for breaking changes.

### 5.5 Usability

**NFR-5.1** The system shall provide an intuitive interface requiring minimal training.  
**NFR-5.2** The system shall comply with WCAG 2.1 Level AA accessibility standards.  
**NFR-5.3** The system shall provide responsive design for all screen sizes.  
**NFR-5.4** The system shall support multi-language interfaces (initially 10 languages).  
**NFR-5.5** The system shall provide cultural localization including date and currency formats.  
**NFR-5.6** The system shall provide comprehensive user guides and video tutorials.  
**NFR-5.7** The system shall provide context-sensitive help within the application.  
**NFR-5.8** The system shall provide API documentation with examples.

### 5.6 Scalability

**NFR-6.1** The system shall support horizontal scaling capability.  
**NFR-6.2** The system shall implement auto-scaling based on demand.  
**NFR-6.3** The system shall support database sharding for large datasets.  
**NFR-6.4** The system shall use containerized microservices on managed platforms.

### 5.7 Compatibility

**NFR-7.1** The system shall support the latest two versions of Chrome, Firefox, Safari, and Edge.  
**NFR-7.2** The system shall provide Progressive Web App (PWA) capabilities.  
**NFR-7.3** The system shall provide graceful degradation for older browsers.  
**NFR-7.4** The system shall provide RESTful and GraphQL APIs.  
**NFR-7.5** The system shall support OAuth 2.0 for third-party integrations.  
**NFR-7.6** The system shall support webhooks for real-time notifications.

### 5.8 Compliance

**NFR-8.1** The system shall comply with GDPR for European users.  
**NFR-8.2** The system shall comply with CCPA for California users.  
**NFR-8.3** The system shall maintain SOC 2 Type II certification.  
**NFR-8.4** The system shall comply with PCI DSS for payment processing.  
**NFR-8.5** The system shall consider HIPAA requirements for health-related tenant data.  
**NFR-8.6** The system shall comply with ISO 27001 information security management standards.  
**NFR-8.7** The system shall comply with local data storage laws.  
**NFR-8.8** The system shall support on-premises deployment for regulated industries.  
**NFR-8.9** The system shall implement data sovereignty controls.  
**NFR-8.10** The system shall provide GDPR right to access, right to deletion, and data portability.

### 5.9 Audit & Logging

**NFR-9.1** The system shall maintain comprehensive audit logs for all system actions.  
**NFR-9.2** The system shall maintain tamper-proof audit logs.  
**NFR-9.3** The system shall implement retention policies based on regulatory requirements.  
**NFR-9.4** The system shall track created_by and updated_by for all records.  
**NFR-9.5** The system shall log all authentication attempts (success and failure).

### 5.10 Data Integrity

**NFR-10.1** The system shall enforce data integrity rules (e.g., at most one active lease per space).  
**NFR-10.2** The system shall perform regular data integrity checks.  
**NFR-10.3** The system shall implement foreign key constraints in the database.  
**NFR-10.4** The system shall implement check constraints for data validation.

---

## 6. Data Specifications

### 6.1 Database Overview

The system shall use PostgreSQL 14+ as the primary database with the following specifications:

- **Database Engine:** PostgreSQL 14+
- **Character Set:** UTF-8
- **Collation:** en_US.UTF-8
- **Primary Keys:** UUID (gen_random_uuid())
- **Timestamps:** TIMESTAMP WITH TIME ZONE (UTC)
- **Normalization:** Third Normal Form (3NF)
- **Audit Trail:** All tables include `created_at`, `updated_at`, `created_by`, `updated_by` fields

### 6.2 Core Data Entities

The system shall maintain the following core data entities:

#### 6.2.1 Users

**DS-1.1** The system shall store user accounts with the following attributes:
- Unique identifier (UUID)
- Email address (unique, RFC 5322 compliant)
- Password hash (encrypted)
- Name, phone number
- Role (SUPER_ADMIN, OWNER, CLIENT, BROKER, AGENT, SUPPORT, MANAGER, ASSISTANT_MANAGER, SALES_REP)
- Email verification status
- Two-factor authentication settings
- Account lock status and failed login attempts
- Leave management (leave_status, leave_start_date, leave_end_date) for sales reps
- Soft delete fields (deleted_at, deleted_by)

#### 6.2.2 Buildings

**DS-1.2** The system shall store building information with:
- Unique identifier (UUID)
- Owner reference (foreign key to users)
- Name, address (structured JSONB: street, city, state, country, postal_code)
- Geographic coordinates (latitude, longitude)
- Total floors count
- Property type (COMMERCIAL, RESIDENTIAL, MIXED_USE)
- Amenities (JSONB array)
- Soft delete fields (deleted_at, deleted_by)

#### 6.2.3 Floors

**DS-1.3** The system shall automatically create floor records when a building is created:
- Unique identifier (UUID)
- Building reference (foreign key, CASCADE delete)
- Floor number (unique per building)
- Total square footage, common area square footage
- Net leasable square footage (calculated: total - common area)
- Amenities and floor plan URL

#### 6.2.4 Spaces

**DS-1.4** The system shall store individual spaces within floors with:
- Unique identifier (UUID)
- Floor reference (foreign key, CASCADE delete)
- Name, gross square footage, usable square footage
- Usage type (OFFICE, CANTEEN, RESTROOM, STORAGE, CORRIDOR, JANITOR, OTHER)
- Leasable flag (boolean)
- Base price (monthly), currency
- Availability status (AVAILABLE, OCCUPIED, MAINTENANCE, RESERVED)
- Amenities, images (JSONB arrays)
- Constraint: usable_sqft <= gross_sqft

#### 6.2.5 Bids

**DS-1.5** The system shall store bids placed by clients with:
- Unique identifier (UUID)
- Space reference, client reference (foreign keys)
- Bid amount (positive decimal)
- Status (PENDING, APPROVED, REJECTED, COUNTER_OFFERED, WITHDRAWN)
- Counter offer amount (optional)
- Notes, timestamps
- Constraint: Only one pending bid per client per space

#### 6.2.6 Contracts

**DS-1.6** The system shall store lease, rental, and sale contracts with:
- Unique identifier (UUID)
- Bid reference (optional), space reference, client reference, owner reference
- Contract type (LEASE, RENTAL, SALE)
- Start date, end date (nullable for SALE)
- Status (DRAFT, PENDING_SIGNATURE, ACTIVE, EXPIRED, TERMINATED)
- Contract document URL
- Version number
- Constraint: Only one active contract per space

#### 6.2.7 Payments

**DS-1.7** The system shall store payment schedules and records with:
- Unique identifier (UUID)
- Contract reference, payer reference (foreign keys)
- Amount, currency
- Due date, paid date (optional)
- Installment number, total installments
- Status (SCHEDULED, DUE, PAID, OVERDUE, CANCELLED)
- External payment reference (optional)
- Invoice/receipt URLs

#### 6.2.8 Private Visits

**DS-1.8** The system shall store private visit bookings with:
- Unique identifier (UUID)
- Space reference, client reference, sales representative reference (foreign keys)
- Visit date, start time, end time
- Visit type (PRIVATE, GROUP, VIRTUAL)
- Status (SCHEDULED, CONFIRMED, COMPLETED, CANCELLED, NO_SHOW)
- Notes
- Constraint: No overlapping visits for same space on same date

#### 6.2.9 Role Hierarchy Configuration

**DS-1.9** The system shall store configurable role hierarchy rules with:
- Unique identifier (UUID)
- Organization identifier (NULL for global config)
- Parent role, child role
- Enabled flag, requires approval flag

#### 6.2.10 User Role Hierarchy

**DS-1.10** The system shall store actual hierarchical relationships between users with:
- Unique identifier (UUID)
- Parent user reference, child user reference (foreign keys)
- Hierarchy configuration reference
- Active status flag
- Constraint: Parent and child cannot be the same user

#### 6.2.11 Notifications

**DS-1.11** The system shall store notifications with:
- Unique identifier (UUID)
- User reference (foreign key, CASCADE delete)
- Notification type, channel
- Title, message, metadata (JSONB)
- Read status, read timestamp
- Priority level

#### 6.2.12 Audit Logs

**DS-1.12** The system shall maintain audit logs for all system actions with:
- Unique identifier (UUID)
- User reference (optional, SET NULL on delete)
- Action type, resource type, resource identifier
- IP address, user agent
- Request body, response status (JSONB)
- Timestamp

### 6.3 Data Relationships

**DS-2.1** The system shall maintain the following primary relationships:

| Parent Entity | Child Entity | Relationship Type | Delete Rule |
|--------------|--------------|-------------------|-------------|
| Users | Buildings | 1:N | RESTRICT |
| Buildings | Floors | 1:N | CASCADE |
| Floors | Spaces | 1:N | CASCADE |
| Spaces | Bids | 1:N | RESTRICT |
| Spaces | Contracts | 1:N | RESTRICT |
| Spaces | Private Visits | 1:N | RESTRICT |
| Contracts | Payments | 1:N | RESTRICT |
| Users | Notifications | 1:N | CASCADE |
| Users | Audit Logs | 1:N | SET NULL |
| Users | User Role Hierarchy (parent/child) | 1:N | CASCADE |

### 6.4 Data Constraints

**DS-3.1** The system shall enforce the following check constraints:
- User roles must be valid enum values
- Building total floors must be positive
- Floor numbers must be unique per building
- Space usable square footage must be <= gross square footage
- Bid amounts must be positive
- Contract end date must be > start date (if provided)
- Payment installment numbers must be valid (1 to total_installments)
- Visit end time must be > start time

**DS-3.2** The system shall enforce the following unique constraints:
- User email addresses must be unique
- One pending bid per client per space
- One active contract per space
- Unique parent-child role hierarchy relationships

**DS-3.3** The system shall enforce referential integrity through foreign key constraints with appropriate cascade rules:
- RESTRICT: Prevents deletion if child records exist (buildings, spaces, contracts)
- CASCADE: Deletes child records when parent is deleted (floors, spaces, notifications)
- SET NULL: Sets foreign key to NULL (audit_logs.user_id)

### 6.5 Data Validation Rules

**DS-4.1** The system shall validate:
- Email format: RFC 5322 compliant
- Password strength: Minimum 8 characters, 1 uppercase, 1 lowercase, 1 number
- Square footage: Positive decimal values
- Dates: Valid date ranges (end_date > start_date)
- Monetary amounts: Positive decimal values with appropriate precision
- Geographic coordinates: Valid latitude (-90 to 90) and longitude (-180 to 180)

### 6.6 Data Storage Requirements

**DS-5.1** The system shall support:
- JSONB fields for flexible structured data (addresses, amenities, metadata)
- Array storage for multiple values (amenities, images)
- File URL storage for documents, images, and floor plans
- Multi-currency support with ISO 4217 currency codes

### 6.7 Indexing Strategy

**DS-6.1** The system shall maintain indexes on:
- Primary keys (automatic UUID indexes)
- Foreign keys for join performance
- Searchable fields (email, role, status, availability)
- Composite indexes for common query patterns
- Conditional indexes for filtered queries (e.g., leasable spaces only)

**Note:** For detailed database schema, table definitions, and implementation specifics, refer to [Database Schema Documentation](../Documentation/Database-Schema.md).

---

## 7. Interface Requirements

### 7.1 API Interface Requirements

#### 7.1.1 API Base Configuration

**IR-1.1** The system shall provide a RESTful API with the following base configuration:
- Base URL: `https://api.example.com/api/v1`
- Content-Type: `application/json`
- Authentication via Bearer tokens in Authorization header
- Support for refresh tokens via custom header

**IR-1.2** The system shall use standard HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `429` - Too Many Requests (rate limited)
- `500` - Internal Server Error
- `503` - Service Unavailable

**IR-1.3** The system shall implement cursor-based pagination for all list endpoints:
- Query parameters: `?cursor={cursor}&limit={limit}`
- Default limit: 20 records
- Maximum limit: 100 records
- Response format: `{ data: [...], meta: { cursor, has_more, total? } }`

#### 7.1.2 Authentication Endpoints

**IR-2.1** The system shall provide the following authentication endpoints:
- `POST /api/v1/auth/register` - Register new user account
- `POST /api/v1/auth/login` - Authenticate user and receive tokens
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/password-reset` - Request password reset email
- `POST /api/v1/auth/password-reset/confirm` - Confirm password reset with token

**IR-2.2** Authentication endpoints shall:
- Accept email and password for login
- Return JWT access token and refresh token
- Validate email format (RFC 5322)
- Enforce password strength requirements
- Lock accounts after 5 failed login attempts (15 minutes)

#### 7.1.3 Building Management Endpoints

**IR-3.1** The system shall provide endpoints for building management:
- `GET /api/v1/buildings` - List buildings (paginated)
- `GET /api/v1/buildings/:id` - Get building details
- `POST /api/v1/buildings` - Create new building (Owner only)
- `PUT /api/v1/buildings/:id` - Update building (Owner only)
- `DELETE /api/v1/buildings/:id` - Delete building (Owner only, with restrictions)

#### 7.1.4 Space Management Endpoints

**IR-4.1** The system shall provide endpoints for space management:
- `GET /api/v1/spaces` - Search and list spaces (paginated, filters)
- `GET /api/v1/spaces/:id` - Get space details
- `POST /api/v1/spaces` - Create new space (Owner only)
- `PUT /api/v1/spaces/:id` - Update space (Owner only)
- `DELETE /api/v1/spaces/:id` - Delete space (Owner only, with restrictions)

**IR-4.2** Space search endpoints shall support filtering by:
- Location (city, state, coordinates)
- Size range (square footage)
- Price range
- Amenities
- Availability status
- Building or floor

#### 7.1.5 Bidding Endpoints

**IR-5.1** The system shall provide endpoints for bidding:
- `POST /api/v1/spaces/:id/bids` - Place bid on space (Client only)
- `GET /api/v1/bids` - List user's bids (paginated)
- `GET /api/v1/bids/:id` - Get bid details
- `PUT /api/v1/bids/:id/approve` - Approve bid (Owner only)
- `PUT /api/v1/bids/:id/reject` - Reject bid (Owner only)
- `PUT /api/v1/bids/:id/counter` - Make counter offer (Owner only)
- `PUT /api/v1/bids/:id/withdraw` - Withdraw bid (Client only)

#### 7.1.6 Contract Management Endpoints

**IR-6.1** The system shall provide endpoints for contract management:
- `GET /api/v1/contracts` - List contracts (role-based filtering)
- `GET /api/v1/contracts/:id` - Get contract details
- `GET /api/v1/contracts/:id/document` - Download contract document
- `POST /api/v1/contracts/:id/sign` - Initiate e-signature process

#### 7.1.7 Payment Tracking Endpoints

**IR-7.1** The system shall provide endpoints for payment tracking:
- `GET /api/v1/payments` - List payments (paginated, filters)
- `GET /api/v1/payments/:id` - Get payment details
- `POST /api/v1/payments` - Record external payment
- `GET /api/v1/payments/:id/invoice` - Download invoice
- `GET /api/v1/payments/:id/receipt` - Download receipt

#### 7.1.8 Visit Booking Endpoints

**IR-8.1** The system shall provide endpoints for visit booking:
- `POST /api/v1/spaces/:id/visits` - Book private visit (Client or Sales Rep)
- `GET /api/v1/visits` - List visits (role-based filtering, paginated)
- `GET /api/v1/visits/:id` - Get visit details
- `PUT /api/v1/visits/:id` - Update visit (authorized roles only)
- `DELETE /api/v1/visits/:id` - Cancel visit
- `GET /api/v1/visits/:id/conflicts` - Check for scheduling conflicts

#### 7.1.9 Dashboard Endpoints

**IR-9.1** The system shall provide dashboard endpoints:
- `GET /api/v1/dashboard/owner` - Owner dashboard data
- `GET /api/v1/dashboard/client` - Client dashboard data
- `GET /api/v1/dashboard/manager` - Manager dashboard data
- `GET /api/v1/dashboard/analytics` - Analytics data (role-based)

#### 7.1.10 WebSocket Interface

**IR-10.1** The system shall provide WebSocket connections for real-time updates:
- Connection endpoint: `wss://api.example.com/ws`
- Authentication via token in connection query parameter
- Support for multiple event types (bid updates, visit confirmations, notifications)

**IR-10.2** WebSocket events shall include:
- Bid status changes
- Visit confirmations and reminders
- Payment notifications
- Lease milestone notifications
- Real-time dashboard updates

### 7.2 User Interface Requirements

#### 7.2.1 Web Application Interface

**IR-11.1** The system shall provide a responsive web application interface that:
- Supports the latest two versions of Chrome, Firefox, Safari, and Edge
- Provides responsive design for desktop, tablet, and mobile screen sizes
- Implements Progressive Web App (PWA) capabilities
- Provides graceful degradation for older browsers

**IR-11.2** The web interface shall include:
- User authentication pages (login, registration, password reset)
- Role-based dashboards (Owner, Client, Manager, Sales Rep, etc.)
- Building and space management interfaces (Owner/Manager)
- Space search and discovery interface (Client)
- Bidding and negotiation interface
- Contract viewing and e-signature integration
- Payment tracking and invoicing interface
- Visit booking and management interface
- Analytics and reporting dashboards
- Notification center

**IR-11.3** The web interface shall provide:
- Interactive map view with property markers (Google Maps/Mapbox)
- Space comparison tool (side-by-side view)
- Image galleries and virtual tour integration
- Filter and search controls
- Export functionality (CSV, PDF, Excel)
- Real-time updates via WebSocket connections

#### 7.2.2 Mobile Application Interface

**IR-12.1** The system shall provide mobile applications for:
- iOS 14+ (native or cross-platform)
- Android 10+ (native or cross-platform)

**IR-12.2** The mobile interface shall support:
- All core features available in web interface
- Push notifications (iOS and Android)
- Biometric authentication (FaceID/TouchID, fingerprint)
- GPS-based property discovery
- QR code scanning for property details
- Offline viewing of previously loaded data (Phase 3+)

#### 7.2.3 User Interface Standards

**IR-13.1** The system shall comply with:
- WCAG 2.1 Level AA accessibility standards
- Responsive design principles for all screen sizes
- Consistent navigation and layout patterns
- Clear error messages and validation feedback
- Loading states and progress indicators
- Context-sensitive help and tooltips

**IR-13.2** The user interface shall support:
- Multi-language interfaces (initially 10 languages, Phase 3)
- Cultural localization (date formats, currency formats)
- Dark mode option (Phase 3)
- Customizable dashboard layouts (Phase 3)

### 7.3 Integration Interface Requirements

**IR-14.1** The system shall provide integration interfaces for:
- Email service providers (SMTP, SendGrid, AWS SES)
- WhatsApp Business API for notifications
- Mapping services (Google Maps API, Mapbox)
- E-signature platforms (DocuSign, Adobe Sign)
- Accounting/ERP systems (QuickBooks, Zoho, SAP) - API-based
- IoT sensors for smart building features (Phase 4)

**IR-14.2** Integration interfaces shall:
- Use RESTful APIs or webhooks where applicable
- Implement OAuth 2.0 for third-party authentication
- Provide webhook endpoints for real-time notifications
- Support retry mechanisms and circuit breakers
- Handle failures gracefully without impacting core functionality

### 7.4 API Documentation Requirements

**IR-15.1** The system shall provide comprehensive API documentation:
- OpenAPI/Swagger specification for all REST endpoints
- Request and response examples
- Authentication requirements
- Error code reference
- Rate limiting information
- Interactive API explorer

**IR-15.2** API documentation shall be:
- Accessible via web interface
- Version-controlled alongside code
- Updated with each API change
- Available in both human-readable and machine-readable formats

**Note:** For detailed API specifications, endpoint definitions, request/response schemas, and WebSocket event details, refer to [Technical Implementation Details](./Technical-Implementation-Details.md) Section 3: API Specifications.

---

## 8. Assumptions & Constraints

### 8.1 Technology Stack Constraints

**AC-1.1** The system shall use **PostgreSQL ONLY** as the database - no MongoDB or other NoSQL databases.

**AC-1.2** The system shall use **Google Cloud Storage ONLY** for file/resource storage - no AWS S3, no Azure Blob Storage.

**AC-1.3** The system shall use **Sequelize ONLY** as the ORM - no Prisma, no TypeORM.

**AC-1.4** The system shall use **Google Cloud Run ONLY** for containerized deployment - no AWS ECS/Fargate, no Azure Container Apps.

**AC-1.5** The system shall use **Google Cloud Platform services ONLY** for monitoring and logging:
- Google Cloud Logging (no ELK Stack, no CloudWatch)
- Google Cloud Monitoring (no Datadog, no New Relic)
- Google Cloud Trace (no Jaeger, no Zipkin)

**AC-1.6** The system shall **NOT** develop native mobile applications - web app only with Progressive Web App (PWA) capabilities.

**AC-1.7** The system shall use **TanStack Query (React Query)** for server state management, with Zustand or Context for client-only state. Redux only if complex global state management needed.

**AC-1.8** The system shall implement AI recommendations using **vector matching ONLY**:
- Use pre-existing embedding models (OpenAI, Cohere, or open-source)
- Store embeddings in vector database (pgvector or Pinecone/Weaviate)
- Use cosine similarity or vector distance metrics
- **NO** creation of new AI models
- **NO** training of machine learning models
- **NO** custom ML pipelines

### 8.2 Database Constraints

**AC-2.1** All tables shall include soft delete fields (`deleted_at`, `deleted_by`) for recycle bin functionality.

**AC-2.2** All queries shall exclude soft-deleted records by default.

**AC-2.3** Only Super Admin can access recycle bin and perform permanent deletions.

### 8.3 API Constraints

**AC-3.1** APIs shall work dynamically based on query/request parameters without hardcoded field mappings.

**AC-3.2** Frontend can request any fields via query parameters (`?fields=id,name,address.city`).

**AC-3.3** APIs shall support dynamic filtering, sorting, and field selection without requiring API modifications for database schema changes.

### 8.4 Role Hierarchy Constraints

**AC-4.1** Role hierarchy must be highly configurable to adapt to each organization's structure:
- Small companies: May have only Owners
- Medium companies: Owners + Managers
- Large companies: Multiple Managers, Assistant Managers, Sales Reps

**AC-4.2** System must support multiple managers, assistant managers, and sales reps per organization.

### 8.5 Access Control Constraints

**AC-5.1** Clients must NOT have access to visit details/management - only "interest" status on properties.

**AC-5.2** Only Sales Reps, Managers, and Assistant Managers can see full visit details.

### 8.6 Visit Scheduling Constraints

**AC-6.1** If Sales Rep is on leave, coordinated visits must be automatically postponed and rescheduled.

**AC-6.2** System must check sales rep availability before confirming visits.

### 8.7 Property Type Constraints

**AC-7.1** System must support COMMERCIAL, RESIDENTIAL, and MIXED_USE property types.

**AC-7.2** Search and filtering must accommodate all property types.

### 8.8 Canteen Management Constraints

**AC-8.1** Canteens can be lent or contract-based agreements (not just non-leasable spaces).

**AC-8.2** Canteens can be leased to third parties.

### 8.9 Parking Constraints

**AC-9.1** Parking spaces must be assignable to specific clients/owners.

**AC-9.2** Parking can be associated with leased spaces or standalone.

### 8.10 Parent-Child Relationship Constraints

**AC-10.1** System must support deletion strategies: detach (remove parent reference) or cascade (delete parent and children).

**AC-10.2** User must choose deletion behavior when deleting parent records with children.

## 8.11 Original Assumptions & Constraints

### 8.1 Technical Constraints

- Cloud infrastructure (Google Cloud Run, AWS, or Azure)
- PostgreSQL 14+, Redis 6+, Node.js 18+ (LTS)
- Latest two versions of Chrome, Firefox, Safari, Edge
- Mobile: iOS 14+ or Android 10+
- Subject to third-party API rate limits
- Internet connectivity required (no offline mode in Phase 1-2)
- Payment tracking only (no direct payment processing)

### 8.2 Business Constraints

- Budget constraints limit Phase 1 scope
- Regulatory compliance varies by jurisdiction
- Legacy system integration may face technical challenges
- Property data must be in structured format
- Multi-language/currency support from Phase 3
- AR/VR features require compatible devices (Phase 4+)

### 8.3 User Assumptions

- Reliable internet connectivity
- Modern web-standard compatible devices
- Willingness to adopt digital workflows
- Email access for registration, verification, and password reset
- Structured property data available
- Basic web/mobile application understanding

### 8.4 Data Assumptions

- Property data (buildings, floors, spaces) in structured format
- Accurate user data during registration
- Accurate payment information for external payments
- Geographic coordinates available or geocodable
- Consistent measurement units (square footage)

### 8.5 Integration Assumptions

- Third-party services (email, WhatsApp, maps, e-signature) remain available
- External accounting/ERP systems (QuickBooks, Zoho, SAP) support API integration
- Payment gateways maintain API compatibility
- IoT sensors provide standardized data formats

### 8.6 Operational Constraints

- 99.99% uptime SLA
- Automated daily backups (30-day retention)
- Disaster recovery: RTO < 4 hours, RPO < 1 hour
- Geographic redundancy across multiple regions
- Data residency law compliance
- Audit logs for all transactions

### 8.7 Security Constraints

- AES-256 encryption at rest, TLS 1.3 in transit
- GDPR (EU), CCPA (California) compliance
- SOC 2 Type II certification
- Secrets in cloud-native secret stores

### 8.8 Performance Constraints

- 100,000+ concurrent users
- 10,000+ transactions per minute
- 1 million+ property listings
- API response: 500ms (95th percentile)
- Page load: 2 seconds (95th percentile)

### 8.9 Development Constraints

- Phase 1 (MVP): 3-4 months
- 80%+ code coverage for business logic
- OpenAPI/Swagger documentation for all APIs
- Versioned database migrations with rollback plans
- Code review required for all changes

### 8.10 Feature Constraints

- No offline mode (Phase 1-2)
- No blockchain integration (Phase 1-3)
- No digital twin technology (Phase 1-3)
- No white-label options (Phase 1-2)
- No marketing automation (Phase 1-2)

---

## 9. Acceptance Criteria

### 9.1 User Management & Authentication

**Registration:** Users register with email, password, name, role, and phone. System validates email (RFC 5322), password strength (8+ chars, 1 uppercase, 1 lowercase, 1 number), and rejects duplicates. Verification email sent; login blocked until verified. JWT token returned on success.

**Login:** Email/password authentication with JWT token. Account locks after 5 failed attempts (15 minutes). Email notification on new device login. Token expires after 24 hours (configurable) with refresh mechanism.

**Password Reset:** Email-based reset with 1-hour expiration. Old password cannot be reused. Reset token invalidated after use. Confirmation email sent.

**Profile Management:** Users can view (GET /api/v1/users/me) and update name, phone, company details. Email cannot be changed via profile. Changes saved immediately with audit trail (updated_by, updated_at).

### 9.2 Building & Floor Management

**Create Building:** Owners create buildings with name, address (city, state, country, postal code), total floors, amenities (JSON), and coordinates. System auto-creates floor records (1 to N), validates address, associates with owner account. Building appears immediately in owner's list.

**View Building:** Owners view all buildings (GET /api/v1/buildings) with cursor-based pagination. Clients view public information. Details include name, address, floors, amenities, occupancy rate, floor list, space counts.

**Update Building:** Owners update name, address, amenities, and floor count (system auto-adjusts floor records). Changes saved immediately with audit trail. Existing spaces unaffected by floor changes.

**Manage Floors:** Owners update total_sqft and common_area_sqft. System auto-calculates net_leasable_sqft. Floor-specific amenities and floor plan images supported. Floor numbers unique per building.

### 9.3 Space Management

**Create Space:** Owners create spaces with name, gross_sqft, usable_sqft, usage_type, is_leasable flag, base_price_monthly, currency, availability_status (AVAILABLE, OCCUPIED, MAINTENANCE, RESERVED), amenities (JSON), and images. System validates gross_sqft >= usable_sqft and valid usage_type enum. Space appears immediately in owner's list.

**Browse Spaces:** Clients view available spaces (is_leasable = true only) with filters (building, floor, size, price, amenities) and location search. Results use cursor-based pagination, sorted by relevance (AI) or price. Each space shows name, size, price, location, status, thumbnail. Non-leasable spaces excluded.

**View Details:** Full space details include images, floor plan, amenities, pricing, availability calendar, location (building, floor, code), similar/recommended spaces, ratings/reviews. Images and floor plans display correctly. Spaces can be added to comparison list.

**Update Space:** Owners update name, pricing, availability, amenities, images, is_leasable flag, and usage_type. Changes saved immediately. Active bids notified if space becomes unavailable. Space removed from client search if marked non-leasable.

### 9.4 Bidding & Negotiation

**Place Bid:** Clients place bids on available spaces. System validates amount > 0, prevents duplicate bids from same client on same space. Bid status set to PENDING. Real-time WebSocket notification sent to owner. Bid appears in client history and owner dashboard.

**Approve/Reject:** Owners approve, reject, or counter bids. System updates status (APPROVED, REJECTED, COUNTER_OFFERED), sends real-time WebSocket notification to client. Approved bids auto-generate lease documents. Bid history maintained with status changes. Owners can add notes.

**Counter Offer:** Owners make counter-offers with different amounts. Status changes to COUNTER_OFFERED. Client notified and can accept, reject, or make new bid.

**Bid History:** Clients view all bids with status; owners view all bids for their spaces. History shows amount, status, timestamp, space details. Cursor-based pagination. History cannot be deleted.

### 9.5 Lease & Contract Management

**Generate Lease:** System auto-generates lease documents from approved bids including space, client, owner details, terms, and pricing. Status set to DRAFT, version to 1. Contract type (LEASE, RENTAL, SALE) set correctly. Document stored and accessible via URL.

**E-Signature:** Integration with e-signature platforms (DocuSign, Adobe Sign). Leases sent for signature to owner and client. System tracks signature status. Status changes to PENDING_SIGNATURE, then ACTIVE when all parties sign. Signed documents stored.

**Renewal:** System sends expiration reminders (30, 60, 90 days before expiry) to owner and client. Renewal workflow creates new lease with updated dates.

**Status Tracking:** System tracks status (DRAFT, PENDING_SIGNATURE, ACTIVE, EXPIRED, TERMINATED). Status changes logged in audit trail and trigger notifications.

### 9.6 Payment Tracking

**Payment Schedule:** System generates schedules based on lease terms supporting EMI/installment plans. Each payment includes amount, due_date, installment_number, total_installments. Status set to SCHEDULED. Schedule visible to owner and client.

**Record Payment:** System records external payments (bank, cheque, external gateway). Status changes to PAID with paid_date. Auto-generates invoice and receipt. Payments cannot be deleted once recorded.

**Status Tracking:** System tracks status (SCHEDULED, DUE, PAID, OVERDUE, CANCELLED). Auto-updates to DUE on due_date, OVERDUE after due_date passes. Reminders sent for DUE and OVERDUE payments.

**Invoicing:** Auto-generated invoices include space details, amount, due date, payment method. Downloadable as PDF. Invoice URL stored and accessible.

### 9.7 Dashboards & Reporting

**Owner Dashboard:** Displays total buildings/spaces, occupied/available spaces, active bids, pending leases, current month revenue, upcoming income (scheduled payments), occupancy rates (building/floor level), recent activity, and occupancy heatmaps. Data updates in real-time or near real-time.

**Client Dashboard:** Shows active bids (with status), pending/active leases, upcoming payment schedule (next 3), lease expiration alerts (30/60/90 days), AI-powered recommended spaces, and recent notifications. All data accurate and current.

**Export Reports:** Owners export reports (CSV, PDF, Excel) including occupancy, revenue, and bid statistics. Filterable by building, date range, status. Reports generate within 30 seconds. Files downloadable.

### 9.8 Notifications

**Send Notifications:** Multi-channel delivery (email, WhatsApp, push, in-app) for bid updates, lease milestones, payment events. Delivered within 5 seconds. Preferences respected. Delivery failures logged.

**Management:** Users view all notifications, mark as read/unread, mark all as read. Unread count displayed correctly. Cursor-based pagination.

### 9.9 Search & Discovery

**Advanced Search:** Results within 1 second. Filters (location, size, price, amenities) work correctly. Only leasable spaces included. Case-insensitive with special character handling. Cursor-based pagination.

**Map View:** Interactive map displays spaces with clickable markers showing details. Supports zoom/pan. Shows nearby amenities. Loads within 2 seconds.

**Space Comparison:** Clients add multiple spaces to comparison list. Side-by-side view shows price, size, amenities, location. Spaces removable. List persists across sessions.

### 9.10 Security & Compliance

**Data Encryption:** AES-256 at rest, TLS 1.3 in transit. Keys in cloud-native secret stores. No sensitive data in plain text logs.

**Access Control:** RBAC enforced on all endpoints. Users access only authorized data. Unauthorized attempts logged. Session timeout enforced.

**Audit Logging:** All actions logged (user_id, action, timestamp, IP). Logs tamper-proof, searchable, filterable. Retention per policy.

### 9.11 Performance

**API Response:** 95% of requests within 500ms. Search within 1 second. Real-time updates sub-100ms latency. Optimized queries with proper indexes.

**Page Load:** 95% of pages within 2 seconds. Optimized, lazy-loaded images. Heavy content loads asynchronously.

**Scalability:** Supports 100,000+ concurrent users, 10,000+ transactions/minute, 1 million+ listings. Horizontal scaling functional.

### 9.12 Data Validation

**Input Validation:** All API inputs validated. Invalid inputs return 400 with clear errors. SQL injection and XSS blocked. File uploads validated (type, size).

**Data Integrity:** Foreign key and check constraints enforced. At most one active lease per space. Gross sqft >= usable sqft. Floor numbers unique per building.

### 9.13 Integration

**Third-Party:** Email, WhatsApp Business API, maps (Google Maps/Mapbox), e-signature platforms integrated. Failures handled gracefully with retries. Circuit breakers prevent cascade failures.

**API Documentation:** All APIs documented with OpenAPI/Swagger. Documentation accessible, up-to-date, with request/response examples and authentication requirements.

### 9.14 Definition of Done

A feature is considered done when:
1. All acceptance criteria are met
2. Unit tests pass (80%+ coverage)
3. Integration tests pass
4. Code review is approved
5. API documentation is updated
6. No critical bugs remain
7. Performance requirements are met
8. Security requirements are met

---

## 10. System Architecture

### 10.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
├──────────────────┬──────────────────┬──────────────────────────┤
│   Web App        │   Mobile App     │   Admin Dashboard        │
│  (React/Next.js) │ (React Native)   │   (Next.js)              │
└────────┬─────────┴────────┬─────────┴──────────┬─────────────────┘
         │                   │                    │
         └───────────────────┴────────────────────┘
                            │
                            │ HTTPS / WebSocket
                            │
┌───────────────────────────▼───────────────────────────────────┐
│                    API GATEWAY / LOAD BALANCER                 │
│              (Authentication, Rate Limiting, Routing)          │
└───────────────────────────┬───────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                   │
┌────────▼────────┐  ┌─────▼──────┐  ┌────────▼─────────┐
│  Backend API    │  │  WebSocket  │  │   AI/ML Service   │
│  (Node.js/      │  │   Server    │  │   (Python)        │
│   Fastify)      │  │             │  │                   │
└────────┬────────┘  └─────────────┘  └─────────┬─────────┘
         │                                        │
         │                                        │
┌────────▼────────────────────────────────────────▼──────────────┐
│                      DATA LAYER                                │
├──────────────┬──────────────┬──────────────┬────────────────────┤
│ PostgreSQL   │   Redis      │  MongoDB    │  Object Storage    │
│ (Primary DB) │  (Cache)     │ (Analytics) │  (S3/Cloud Storage)│
└──────────────┴──────────────┴──────────────┴────────────────────┘
         │
         │
┌────────▼───────────────────────────────────────────────────────┐
│                    EXTERNAL INTEGRATIONS                       │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│ Payment      │ E-Signature  │ CRM/ERP      │ Mapping Services  │
│ Gateways     │ (DocuSign)   │ (Salesforce) │ (Google Maps)     │
│              │              │              │                   │
│ WhatsApp API │ Email Service │ IoT Sensors  │ CDN               │
└──────────────┴──────────────┴──────────────┴───────────────────┘
```

### 10.2 Module Dependency Flow

```
┌─────────────────┐
│  User Management│
│  (Authentication│
│   & Roles)      │
└────────┬─────────┘
         │
    ┌────▼──────────────────────────────┐
    │                                   │
┌───▼──────────────┐         ┌──────────▼──────────┐
│ Building & Floor │         │  Space & Listing    │
│   Management    │─────────▶│  (Search & Browse)  │
└──────────────────┘         └──────────┬──────────┘
                                        │
                              ┌─────────▼──────────────┐
                              │ Bidding & Negotiation │
                              │  (Real-time Bidding)  │
                              └─────────┬──────────────┘
                                        │
                              ┌─────────▼────────────────────┐
                              │ Lease & Contract Management  │
                              │  (Auto-generation & E-sign)  │
                              └─────────┬─────────────────────┘
                                        │
                              ┌─────────▼────────────────────┐
                              │ Payment Tracking & Financial │
                              │  (Schedules & Invoicing)     │
                              └─────────┬────────────────────┘
                                        │
                              ┌─────────▼──────────────┐
                              │ Dashboard & Reporting  │
                              │  (Analytics & Metrics)│
                              └───────────────────────┘
                                        ▲
                                        │
                              ┌─────────┴──────────┐
                              │  AI & Analytics   │
                              │   (Optional)      │
                              └───────────────────┘
```

### 10.3 Key Technical Decisions

- **Cursor-based pagination** for all list endpoints (performance at scale)
- **Payment tracking only** (not processing) - money movement happens outside platform
- **Support for non-leasable spaces** (canteens, restrooms, etc.) in floor planning
- **Multi-currency and multi-language support** from Phase 3
- **OpenAPI/Swagger documentation** for all APIs
- **Microservices architecture** for scalability and maintainability
- **WebSocket connections** for real-time bid notifications
- **Automated lease generation** from approved bids

---

## Document Control

**Version History:**
- v1.0 (2025-01-27): Initial SRS document created from requirements

**Related Documents:**
- Technical-Implementation-Details.md - Detailed technical specifications, database schema, API specifications, and implementation patterns

**Approval:**
- Prepared by: Development Team
- Reviewed by: [Pending]
- Approved by: [Pending]

**Distribution:**
- Development Team
- Product Management
- QA Team
- DevOps Team

---

**End of Document**

