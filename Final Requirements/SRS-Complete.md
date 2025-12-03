# Software Requirements Specification
## Enterprise Multi-Floor Commercial Office Leasing Platform

**Version:** 1.0  
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
6. [Assumptions & Constraints](#6-assumptions--constraints)
7. [Acceptance Criteria](#7-acceptance-criteria)
8. [System Architecture](#8-system-architecture)

---

## 1. Purpose

### 1.1 Project Overview

A cloud-based SaaS platform for managing multi-floor commercial office space leasing, renting, and sales. The system serves property owners, brokers, tenants, property managers, and administrators.

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
- Support for leasable (offices) and non-leasable spaces (canteens, restrooms, storage, corridors)
- Real-time bidding with WebSocket notifications
- Automated lease document generation
- Payment schedule tracking and invoicing (scheduled, due, overdue, paid)
- Support for lease, rental, and sale transaction types

#### User Management
- Multi-role access control (Owners, Clients, Brokers, Agents, Support, Super Admin)
- Authentication (email/password, OAuth2, biometric)
- User profiles with activity tracking
- Multi-tenant organization support

#### Property Management
- Building, floor, and space management with bulk operations
- Automatic floor generation on building creation
- Advanced search and filtering (location, size, price, amenities, ESG ratings)
- AI-powered property recommendations
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
Search and lease office spaces. Capabilities: search/filter spaces, map view, space comparison, virtual tours, AI recommendations, place/track bids, view leases and payment schedules, download contracts, rate and review.

#### Building Owner / Admin
Manage property portfolio and maximize occupancy/revenue. Capabilities: manage buildings/floors/spaces (bulk operations), set pricing with AI suggestions, view occupancy/revenue dashboards and heatmaps, approve/reject/counter bids, auto-generate leases, track metrics, delegate permissions, export reports.

#### Sales Representative / Broker
Manage client relationships and facilitate deals. Capabilities: manage leads and pipeline, conduct virtual tours, in-app messaging, process applications, track commissions, CRM tools, schedule viewings.

#### Support / Agent
Assist users with inquiries and issues. Capabilities: client support, limited data access, manage communications and escalations, track tasks, view support metrics.

#### Property Manager
Oversee day-to-day building operations. Capabilities: coordinate maintenance, manage tenant relationships, track service requests, monitor occupancy/utilization, coordinate vendors.

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
**FR-1.9** The system shall assign users to one of the following roles: Super Admin, Owner, Agent, Client, Broker, or Support.  
**FR-1.10** The system shall enforce role-based access control for all features.

### 4.2 Building & Floor Management

**FR-2.1** The system shall allow owners to create buildings with name, address, coordinates, and total floors.  
**FR-2.2** The system shall automatically create floor records (1 to N) when a building is created.  
**FR-2.3** The system shall allow owners to update building information.  
**FR-2.4** The system shall allow owners to update floor square footage and amenities.  
**FR-2.5** The system shall calculate net leasable square footage as total square footage minus common area square footage.  
**FR-2.6** The system shall support non-leasable spaces (canteens, restrooms, storage, corridors) in floor planning.

### 4.3 Space Management

**FR-3.1** The system shall allow owners to create spaces with square footage, pricing, amenities, and usage type.  
**FR-3.2** The system shall allow owners to mark spaces as leasable or non-leasable.  
**FR-3.3** The system shall allow owners to upload images, videos, and 3D models for spaces.  
**FR-3.4** The system shall allow owners to update space information and pricing.  
**FR-3.5** The system shall allow owners to set space availability status (Available, Occupied, Maintenance, Reserved).  
**FR-3.6** The system shall exclude non-leasable spaces from client search results.

### 4.4 Search & Discovery

**FR-4.1** The system shall allow clients to search spaces by location, size, price, amenities, and availability.  
**FR-4.2** The system shall display spaces on an interactive map with property markers.  
**FR-4.3** The system shall allow clients to filter spaces by building, floor, square footage, price range, and amenities.  
**FR-4.4** The system shall allow clients to compare multiple spaces side-by-side.  
**FR-4.5** The system shall return only leasable spaces in client search results.  
**FR-4.6** The system shall use cursor-based pagination for all list endpoints.

### 4.5 Bidding & Negotiation

**FR-5.1** The system shall allow clients to place bids on available spaces.  
**FR-5.2** The system shall send real-time bid notifications to space owners via WebSockets.  
**FR-5.3** The system shall allow owners to approve, reject, or counter bids.  
**FR-5.4** The system shall track bid status (Pending, Approved, Rejected, Counter-Offered, Withdrawn).  
**FR-5.5** The system shall prevent duplicate bids from the same client on the same space.  
**FR-5.6** The system shall maintain bid history for each space and user.  
**FR-5.7** The system shall notify clients when their bid status changes.

### 4.6 Lease & Contract Management

**FR-6.1** The system shall automatically generate lease documents from approved bids.  
**FR-6.2** The system shall support lease, rental, and sale contract types.  
**FR-6.3** The system shall allow multi-party approval workflows for contracts.  
**FR-6.4** The system shall integrate with e-signature platforms (DocuSign, Adobe Sign).  
**FR-6.5** The system shall send lease expiration reminders (30, 60, 90 days before expiry).  
**FR-6.6** The system shall track contract status (Draft, Pending Signature, Active, Expired, Terminated).  
**FR-6.7** The system shall maintain contract versioning and audit logs.

### 4.7 Payment Tracking

**FR-7.1** The system shall generate payment schedules based on lease terms and EMI plans.  
**FR-7.2** The system shall track payment status (Scheduled, Due, Paid, Overdue, Cancelled).  
**FR-7.3** The system shall allow recording of payments made outside the platform (bank transfer, cheque, external gateway).  
**FR-7.4** The system shall generate invoices automatically based on recorded payments.  
**FR-7.5** The system shall support multi-currency payment tracking.  
**FR-7.6** The system shall track installment numbers and total installments for EMI plans.  
**FR-7.7** The system shall send payment due and overdue reminders.

### 4.8 Dashboards & Reporting

**FR-8.1** The system shall display owner dashboards with occupancy rates, revenue, active bids, and pending leases.  
**FR-8.2** The system shall display client dashboards with active bids, lease status, and upcoming payment schedule.  
**FR-8.3** The system shall show occupancy heatmaps at building, floor, and space levels.  
**FR-8.4** The system shall calculate and display upcoming income from scheduled payments.  
**FR-8.5** The system shall allow export of reports in CSV, PDF, and Excel formats.

### 4.9 Notifications

**FR-9.1** The system shall send notifications via email, WhatsApp, push, and in-app channels.  
**FR-9.2** The system shall send automated notifications for bid updates, lease milestones, and payment events.  
**FR-9.3** The system shall allow users to configure notification preferences.  
**FR-9.4** The system shall mark notifications as read and unread.

### 4.10 AI & Analytics

**FR-10.1** The system shall provide AI-powered pricing suggestions for spaces.  
**FR-10.2** The system shall provide AI-powered space recommendations to clients based on preferences.  
**FR-10.3** The system shall provide AI-suggested bid strategies to clients.  
**FR-10.4** The system shall calculate occupancy and revenue forecasts.  
**FR-10.5** The system shall calculate bid success probability scores.

### 4.11 Security & Compliance

**FR-11.1** The system shall encrypt data at rest using AES-256.  
**FR-11.2** The system shall encrypt data in transit using TLS 1.3.  
**FR-11.3** The system shall maintain audit logs for all user actions.  
**FR-11.4** The system shall track created_by and updated_by for all records.  
**FR-11.5** The system shall enforce session timeouts for inactive users.

### 4.12 Mobile Features

**FR-12.1** The system shall send push notifications to mobile devices.  
**FR-12.2** The system shall support QR code scanning for property details.  
**FR-12.3** The system shall support GPS-based property discovery.

### 4.13 Data Management

**FR-13.1** The system shall validate that gross square footage is greater than or equal to usable square footage.  
**FR-13.2** The system shall validate that floor numbers are unique per building.  
**FR-13.3** The system shall validate email format (RFC 5322 compliant).  
**FR-13.4** The system shall validate password strength (minimum 8 characters, 1 uppercase, 1 lowercase, 1 number).  
**FR-13.5** The system shall prevent duplicate email addresses during registration.

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

## 6. Assumptions & Constraints

### 6.1 Technical Constraints

- Cloud infrastructure (Google Cloud Run, AWS, or Azure)
- PostgreSQL 14+, Redis 6+, Node.js 18+ (LTS)
- Latest two versions of Chrome, Firefox, Safari, Edge
- Mobile: iOS 14+ or Android 10+
- Subject to third-party API rate limits
- Internet connectivity required (no offline mode in Phase 1-2)
- Payment tracking only (no direct payment processing)

### 6.2 Business Constraints

- Budget constraints limit Phase 1 scope
- Regulatory compliance varies by jurisdiction
- Legacy system integration may face technical challenges
- Property data must be in structured format
- Multi-language/currency support from Phase 3
- AR/VR features require compatible devices (Phase 4+)

### 6.3 User Assumptions

- Reliable internet connectivity
- Modern web-standard compatible devices
- Willingness to adopt digital workflows
- Email access for registration, verification, and password reset
- Structured property data available
- Basic web/mobile application understanding

### 6.4 Data Assumptions

- Property data (buildings, floors, spaces) in structured format
- Accurate user data during registration
- Accurate payment information for external payments
- Geographic coordinates available or geocodable
- Consistent measurement units (square footage)

### 6.5 Integration Assumptions

- Third-party services (email, WhatsApp, maps, e-signature) remain available
- External accounting/ERP systems (QuickBooks, Zoho, SAP) support API integration
- Payment gateways maintain API compatibility
- IoT sensors provide standardized data formats

### 6.6 Operational Constraints

- 99.99% uptime SLA
- Automated daily backups (30-day retention)
- Disaster recovery: RTO < 4 hours, RPO < 1 hour
- Geographic redundancy across multiple regions
- Data residency law compliance
- Audit logs for all transactions

### 6.7 Security Constraints

- AES-256 encryption at rest, TLS 1.3 in transit
- GDPR (EU), CCPA (California) compliance
- SOC 2 Type II certification
- Secrets in cloud-native secret stores

### 6.8 Performance Constraints

- 100,000+ concurrent users
- 10,000+ transactions per minute
- 1 million+ property listings
- API response: 500ms (95th percentile)
- Page load: 2 seconds (95th percentile)

### 6.9 Development Constraints

- Phase 1 (MVP): 3-4 months
- 80%+ code coverage for business logic
- OpenAPI/Swagger documentation for all APIs
- Versioned database migrations with rollback plans
- Code review required for all changes

### 6.10 Feature Constraints

- No offline mode (Phase 1-2)
- No blockchain integration (Phase 1-3)
- No digital twin technology (Phase 1-3)
- No white-label options (Phase 1-2)
- No marketing automation (Phase 1-2)

---

## 7. Acceptance Criteria

### 7.1 User Management & Authentication

**Registration:** Users register with email, password, name, role, and phone. System validates email (RFC 5322), password strength (8+ chars, 1 uppercase, 1 lowercase, 1 number), and rejects duplicates. Verification email sent; login blocked until verified. JWT token returned on success.

**Login:** Email/password authentication with JWT token. Account locks after 5 failed attempts (15 minutes). Email notification on new device login. Token expires after 24 hours (configurable) with refresh mechanism.

**Password Reset:** Email-based reset with 1-hour expiration. Old password cannot be reused. Reset token invalidated after use. Confirmation email sent.

**Profile Management:** Users can view (GET /api/v1/users/me) and update name, phone, company details. Email cannot be changed via profile. Changes saved immediately with audit trail (updated_by, updated_at).

### 7.2 Building & Floor Management

**Create Building:** Owners create buildings with name, address (city, state, country, postal code), total floors, amenities (JSON), and coordinates. System auto-creates floor records (1 to N), validates address, associates with owner account. Building appears immediately in owner's list.

**View Building:** Owners view all buildings (GET /api/v1/buildings) with cursor-based pagination. Clients view public information. Details include name, address, floors, amenities, occupancy rate, floor list, space counts.

**Update Building:** Owners update name, address, amenities, and floor count (system auto-adjusts floor records). Changes saved immediately with audit trail. Existing spaces unaffected by floor changes.

**Manage Floors:** Owners update total_sqft and common_area_sqft. System auto-calculates net_leasable_sqft. Floor-specific amenities and floor plan images supported. Floor numbers unique per building.

### 7.3 Space Management

**Create Space:** Owners create spaces with name, gross_sqft, usable_sqft, usage_type, is_leasable flag, base_price_monthly, currency, availability_status (AVAILABLE, OCCUPIED, MAINTENANCE, RESERVED), amenities (JSON), and images. System validates gross_sqft >= usable_sqft and valid usage_type enum. Space appears immediately in owner's list.

**Browse Spaces:** Clients view available spaces (is_leasable = true only) with filters (building, floor, size, price, amenities) and location search. Results use cursor-based pagination, sorted by relevance (AI) or price. Each space shows name, size, price, location, status, thumbnail. Non-leasable spaces excluded.

**View Details:** Full space details include images, floor plan, amenities, pricing, availability calendar, location (building, floor, code), similar/recommended spaces, ratings/reviews. Images and floor plans display correctly. Spaces can be added to comparison list.

**Update Space:** Owners update name, pricing, availability, amenities, images, is_leasable flag, and usage_type. Changes saved immediately. Active bids notified if space becomes unavailable. Space removed from client search if marked non-leasable.

### 7.4 Bidding & Negotiation

**Place Bid:** Clients place bids on available spaces. System validates amount > 0, prevents duplicate bids from same client on same space. Bid status set to PENDING. Real-time WebSocket notification sent to owner. Bid appears in client history and owner dashboard.

**Approve/Reject:** Owners approve, reject, or counter bids. System updates status (APPROVED, REJECTED, COUNTER_OFFERED), sends real-time WebSocket notification to client. Approved bids auto-generate lease documents. Bid history maintained with status changes. Owners can add notes.

**Counter Offer:** Owners make counter-offers with different amounts. Status changes to COUNTER_OFFERED. Client notified and can accept, reject, or make new bid.

**Bid History:** Clients view all bids with status; owners view all bids for their spaces. History shows amount, status, timestamp, space details. Cursor-based pagination. History cannot be deleted.

### 7.5 Lease & Contract Management

**Generate Lease:** System auto-generates lease documents from approved bids including space, client, owner details, terms, and pricing. Status set to DRAFT, version to 1. Contract type (LEASE, RENTAL, SALE) set correctly. Document stored and accessible via URL.

**E-Signature:** Integration with e-signature platforms (DocuSign, Adobe Sign). Leases sent for signature to owner and client. System tracks signature status. Status changes to PENDING_SIGNATURE, then ACTIVE when all parties sign. Signed documents stored.

**Renewal:** System sends expiration reminders (30, 60, 90 days before expiry) to owner and client. Renewal workflow creates new lease with updated dates.

**Status Tracking:** System tracks status (DRAFT, PENDING_SIGNATURE, ACTIVE, EXPIRED, TERMINATED). Status changes logged in audit trail and trigger notifications.

### 7.6 Payment Tracking

**Payment Schedule:** System generates schedules based on lease terms supporting EMI/installment plans. Each payment includes amount, due_date, installment_number, total_installments. Status set to SCHEDULED. Schedule visible to owner and client.

**Record Payment:** System records external payments (bank, cheque, external gateway). Status changes to PAID with paid_date. Auto-generates invoice and receipt. Payments cannot be deleted once recorded.

**Status Tracking:** System tracks status (SCHEDULED, DUE, PAID, OVERDUE, CANCELLED). Auto-updates to DUE on due_date, OVERDUE after due_date passes. Reminders sent for DUE and OVERDUE payments.

**Invoicing:** Auto-generated invoices include space details, amount, due date, payment method. Downloadable as PDF. Invoice URL stored and accessible.

### 7.7 Dashboards & Reporting

**Owner Dashboard:** Displays total buildings/spaces, occupied/available spaces, active bids, pending leases, current month revenue, upcoming income (scheduled payments), occupancy rates (building/floor level), recent activity, and occupancy heatmaps. Data updates in real-time or near real-time.

**Client Dashboard:** Shows active bids (with status), pending/active leases, upcoming payment schedule (next 3), lease expiration alerts (30/60/90 days), AI-powered recommended spaces, and recent notifications. All data accurate and current.

**Export Reports:** Owners export reports (CSV, PDF, Excel) including occupancy, revenue, and bid statistics. Filterable by building, date range, status. Reports generate within 30 seconds. Files downloadable.

### 7.8 Notifications

**Send Notifications:** Multi-channel delivery (email, WhatsApp, push, in-app) for bid updates, lease milestones, payment events. Delivered within 5 seconds. Preferences respected. Delivery failures logged.

**Management:** Users view all notifications, mark as read/unread, mark all as read. Unread count displayed correctly. Cursor-based pagination.

### 7.9 Search & Discovery

**Advanced Search:** Results within 1 second. Filters (location, size, price, amenities) work correctly. Only leasable spaces included. Case-insensitive with special character handling. Cursor-based pagination.

**Map View:** Interactive map displays spaces with clickable markers showing details. Supports zoom/pan. Shows nearby amenities. Loads within 2 seconds.

**Space Comparison:** Clients add multiple spaces to comparison list. Side-by-side view shows price, size, amenities, location. Spaces removable. List persists across sessions.

### 7.10 Security & Compliance

**Data Encryption:** AES-256 at rest, TLS 1.3 in transit. Keys in cloud-native secret stores. No sensitive data in plain text logs.

**Access Control:** RBAC enforced on all endpoints. Users access only authorized data. Unauthorized attempts logged. Session timeout enforced.

**Audit Logging:** All actions logged (user_id, action, timestamp, IP). Logs tamper-proof, searchable, filterable. Retention per policy.

### 7.11 Performance

**API Response:** 95% of requests within 500ms. Search within 1 second. Real-time updates sub-100ms latency. Optimized queries with proper indexes.

**Page Load:** 95% of pages within 2 seconds. Optimized, lazy-loaded images. Heavy content loads asynchronously.

**Scalability:** Supports 100,000+ concurrent users, 10,000+ transactions/minute, 1 million+ listings. Horizontal scaling functional.

### 7.12 Data Validation

**Input Validation:** All API inputs validated. Invalid inputs return 400 with clear errors. SQL injection and XSS blocked. File uploads validated (type, size).

**Data Integrity:** Foreign key and check constraints enforced. At most one active lease per space. Gross sqft >= usable sqft. Floor numbers unique per building.

### 7.13 Integration

**Third-Party:** Email, WhatsApp Business API, maps (Google Maps/Mapbox), e-signature platforms integrated. Failures handled gracefully with retries. Circuit breakers prevent cascade failures.

**API Documentation:** All APIs documented with OpenAPI/Swagger. Documentation accessible, up-to-date, with request/response examples and authentication requirements.

### 7.14 Definition of Done

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

## 8. System Architecture

### 8.1 High-Level Architecture

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

### 8.2 Module Dependency Flow

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

### 8.3 Key Technical Decisions

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

