# Consistency Analysis Report

## Overview
This report identifies inconsistencies across the requirement documents:
- 3.Core Functionalities & Modules.md
- 5.Entity Relationship Diagram.md
- 7.Database Schema.sql
- 8.Technical Plan.md
- 2.Property Hierarchy Structure & Functions.md

## Critical Issues

### 1. Missing Tables in Database Schema

The following tables are referenced in other documents but are **NOT defined** in `7.Database Schema.sql`:

#### Core Tables
- **`documents`** - Referenced in:
  - Core Functionalities (line 578): Document Management module
  - Entity Media table has foreign key to `documents(id)` (line 506) but table doesn't exist
  - Technical Plan mentions it (line 172)
  - **Impact**: Entity Media foreign key will fail, document management functionality cannot be implemented

- **`audit_logs`** - Referenced in:
  - Core Functionalities (line 89): RBAC module
  - Technical Plan (line 127, 174, 182, 186): Audit logging strategy
  - **Impact**: Audit logging functionality cannot be implemented

#### Portfolio Management
- **`portfolio_properties`** - Referenced in:
  - Core Functionalities (line 128): For multi-portfolio assignment
  - Entity Relationship Diagram mentions multi-portfolio assignment
  - **Impact**: Properties cannot be assigned to multiple portfolios

#### Lease Management
- **`lease_amendments`** - Referenced in:
  - Core Functionalities (line 316): Lease amendments support
  - **Impact**: Lease amendment functionality cannot be implemented

- **`lease_terms`** - Referenced in:
  - Technical Plan (line 169): Lease management
  - **Impact**: Detailed lease terms cannot be stored separately

- **`lease_tenants`** - Referenced in:
  - Technical Plan (line 169): Lease management (suggests multiple tenants per lease)
  - **Impact**: Multi-tenant leases cannot be supported

#### Payment Management
- **`payment_schedules`** - Referenced in:
  - Core Functionalities (line 379): Recurring payments
  - Technical Plan (line 170): Financial tables
  - **Impact**: Recurring payment schedules cannot be implemented

- **`late_fees`** - Referenced in:
  - Core Functionalities (line 380): Late fee tracking
  - **Impact**: Late fee calculation and tracking cannot be implemented

- **`invoices`** - Referenced in:
  - Technical Plan (line 170): Financial tables
  - **Impact**: Invoice generation and tracking cannot be implemented

#### Tenant Management
- **`tenant_applications`** - Referenced in:
  - Core Functionalities (line 272): Application processing
  - **Impact**: Tenant application workflow cannot be implemented

- **`tenant_credit_scores`** - Referenced in:
  - Core Functionalities (line 273): Credit score tracking
  - **Impact**: Credit score history cannot be tracked

#### Maintenance Management
- **`maintenance_request_feedback`** - Referenced in:
  - Core Functionalities (line 469): Tenant feedback after completion
  - **Impact**: Feedback collection cannot be implemented

- **`work_order_approvals`** - Referenced in:
  - Core Functionalities (line 511): Approval workflows for high-cost items
  - **Impact**: Work order approval workflow cannot be implemented

#### Communication & Notifications
- **`messages`** - Referenced in:
  - Core Functionalities (line 671): In-app messaging
  - **Impact**: Messaging functionality cannot be implemented

- **`message_attachments`** - Referenced in:
  - Core Functionalities (line 672): File attachments in messages
  - **Impact**: Message attachments cannot be implemented

- **`notifications`** - Referenced in:
  - Core Functionalities (line 673): Notification system
  - **Impact**: Notification system cannot be implemented

- **`notification_preferences`** - Referenced in:
  - Core Functionalities (line 674): User notification preferences
  - **Impact**: Notification preferences cannot be managed

- **`email_templates`** - Referenced in:
  - Core Functionalities (line 675): Email template management
  - **Impact**: Email templates cannot be managed

#### Tenant Portal
- **`tenant_portal_sessions`** - Referenced in:
  - Core Functionalities (line 725): Tenant portal authentication
  - **Impact**: Tenant portal session management cannot be implemented

#### Reporting & Analytics
- **`report_templates`** - Referenced in:
  - Core Functionalities (line 795): Report template management
  - **Impact**: Report templates cannot be stored

- **`saved_reports`** - Referenced in:
  - Core Functionalities (line 796): Saved report configurations
  - **Impact**: Saved reports cannot be stored

- **`scheduled_reports`** - Referenced in:
  - Core Functionalities (line 797): Scheduled report generation
  - **Impact**: Scheduled reports cannot be implemented

- **`dashboards`** - Referenced in:
  - Core Functionalities (line 798): Dashboard configurations
  - **Impact**: Custom dashboards cannot be stored

#### Sales & Visits
- **`sales_reps`** - Referenced in:
  - Core Functionalities (line 934): Sales representative management
  - **Impact**: Sales rep management cannot be implemented

- **`property_visits`** - Referenced in:
  - Core Functionalities (line 935): Property visit scheduling
  - **Impact**: Visit scheduling cannot be implemented

- **`sales_rep_leave`** - Referenced in:
  - Core Functionalities (line 936): Leave tracking
  - **Impact**: Leave management cannot be implemented

- **`client_property_interest`** - Referenced in:
  - Core Functionalities (line 937): Client interest tracking
  - **Impact**: Client interest tracking cannot be implemented

#### Canteen Management
- **`canteens`** - Referenced in:
  - Core Functionalities (line 981): Canteen space management
  - **Impact**: Canteen management cannot be implemented

- **`canteen_agreements`** - Referenced in:
  - Core Functionalities (line 982): Canteen agreement management
  - **Impact**: Canteen agreements cannot be implemented

#### System Administration
- **`system_settings`** - Referenced in:
  - Core Functionalities (line 1025): System configuration
  - **Impact**: System settings cannot be stored

- **`feature_flags`** - Referenced in:
  - Core Functionalities (line 1026): Feature flag management
  - Technical Plan (line 392): Feature flags for gradual rollouts
  - **Impact**: Feature flags cannot be managed

### 2. Field Name Inconsistencies

#### Tenants Table
- **Core Functionalities** (line 271) lists: `ssn_tax_id`
- **Database Schema** (lines 252-253) has: `ssn` and `tax_id` (separate fields)
- **Status**: Schema is more detailed (correct), but Core Functionalities documentation is inaccurate

- **Core Functionalities** (line 271) lists: `emergency_contact`
- **Database Schema** (lines 257-258) has: `emergency_contact_name` and `emergency_contact_phone` (separate fields)
- **Status**: Schema is more detailed (correct), but Core Functionalities documentation is inaccurate

#### Properties Table
- **Core Functionalities** (line 170) lists: `address fields` (vague)
- **Database Schema** (lines 172-177) has: `address_line1`, `address_line2`, `city`, `state`, `postal_code`, `country`
- **Status**: Schema is correct, Core Functionalities should be more specific

### 3. Relationship Inconsistencies

#### Portfolio-Property Relationship
- **Core Functionalities** (line 128): Mentions `portfolio_properties` table for multi-portfolio assignment
- **Database Schema** (line 167): Properties table has `portfolio_id` (single portfolio only)
- **Entity Relationship Diagram**: Mentions multi-portfolio assignment possibility
- **Status**: Schema supports single portfolio only, but documentation suggests multi-portfolio support needed

#### Lease-Tenant Relationship
- **Technical Plan** (line 169): Mentions `lease_tenants` table (suggests many-to-many)
- **Database Schema** (line 281): Leases table has `tenant_id` (single tenant only)
- **Status**: Schema supports single tenant per lease, but Technical Plan suggests multi-tenant leases

### 4. Technical Plan vs Schema Inconsistencies

#### Database Engine
- **Technical Plan**: Mentions PostgreSQL 15+ (line 20)
- **Database Schema**: Uses MySQL syntax (InnoDB engine, AUTO_INCREMENT, etc.)
- **Status**: **CRITICAL** - Schema is MySQL but Technical Plan specifies PostgreSQL

#### Multi-Tenant Column Name
- **Technical Plan** (line 104): Uses `tenant_id` for multi-tenancy
- **Database Schema**: Uses `organization_id` consistently
- **Technical Plan** (line 127): Audit logs table uses `tenant_id`
- **Status**: Terminology inconsistency - should be `organization_id` throughout

### 5. Missing Foreign Key Constraints

The following relationships are mentioned but foreign keys are missing or incomplete:

- `entity_media.document_id` → `documents.id` (foreign key exists but `documents` table doesn't exist)
- `work_orders.assigned_to_vendor_id` → No vendor table exists
- Various communication tables have no foreign keys defined

### 6. Enum Value Inconsistencies

#### Lease Status
- **Core Functionalities** (line 288): `'draft', 'pending_signature', 'active', 'expired', 'terminated', 'renewed'`
- **Database Schema** (line 288): Same values - **CONSISTENT**

#### Payment Status
- **Core Functionalities** (line 330): `'pending', 'completed', 'failed', 'refunded'`
- **Database Schema** (line 330): `'pending', 'paid', 'partial', 'failed', 'refunded', 'voided'`
- **Status**: Schema has additional values (`'paid'`, `'partial'`, `'voided'`) - Schema is more complete

### 7. Index Inconsistencies

#### Missing Indexes Mentioned in Technical Plan
- **Technical Plan** (line 180): `(organization_id, status, created_at DESC)` on `maintenance_requests`
- **Database Schema** (lines 383-388): Has separate indexes but not the composite one mentioned
- **Status**: Composite index would improve query performance

## Recommendations

### Priority 1: Critical Fixes

1. **Add missing core tables to schema:**
   - `documents` (required for entity_media foreign key)
   - `audit_logs` (required for audit functionality)
   - `messages`, `notifications`, `notification_preferences` (required for communication)

2. **Fix database engine mismatch:**
   - Either update Technical Plan to specify MySQL
   - Or convert schema to PostgreSQL syntax

3. **Clarify multi-tenant terminology:**
   - Standardize on `organization_id` throughout all documents
   - Update Technical Plan audit_logs reference from `tenant_id` to `organization_id`

### Priority 2: Important Additions

4. **Add missing functional tables:**
   - `portfolio_properties` (if multi-portfolio assignment is required)
   - `lease_amendments`, `payment_schedules`, `late_fees`
   - `tenant_applications`, `tenant_credit_scores`
   - `maintenance_request_feedback`, `work_order_approvals`
   - Communication tables (messages, notifications, etc.)
   - Reporting tables (report_templates, saved_reports, etc.)
   - Sales & visits tables
   - System administration tables

5. **Update Core Functionalities documentation:**
   - Fix tenant table field names (`ssn_tax_id` → `ssn`, `tax_id`)
   - Fix tenant table field names (`emergency_contact` → `emergency_contact_name`, `emergency_contact_phone`)
   - Specify property address fields explicitly

### Priority 3: Enhancements

6. **Add missing indexes:**
   - Composite indexes mentioned in Technical Plan
   - Indexes for frequently queried fields

7. **Clarify relationships:**
   - Decide on multi-portfolio assignment (add `portfolio_properties` table or keep single portfolio)
   - Decide on multi-tenant leases (add `lease_tenants` table or keep single tenant)

## Summary Statistics

- **Total Missing Tables**: 25+
- **Field Name Inconsistencies**: 3
- **Relationship Inconsistencies**: 2
- **Critical Issues**: 3 (database engine mismatch, missing core tables, terminology)

## Next Steps

1. Review and prioritize which missing tables are required for MVP
2. Create database migration scripts for missing tables
3. Update documentation to match actual schema
4. Resolve database engine decision (MySQL vs PostgreSQL)
5. Standardize terminology across all documents

