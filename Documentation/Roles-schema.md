# Roles Schema Documentation
## Neorem Property Management Platform

**Version:** 1.0  
**Date:** 2025-12-05  
**Database:** PostgreSQL 14+

---

## Table of Contents

1. [Overview](#1-overview)
2. [Role Definitions](#2-role-definitions)
3. [Core Roles Enum](#3-core-roles-enum)
4. [Role Profile Tables](#4-role-profile-tables)
5. [Role Permissions](#5-role-permissions)
6. [Role Hierarchy](#6-role-hierarchy)
7. [Indexes Summary](#7-indexes-summary)
8. [Relationships](#8-relationships)

---

## 1. Overview

### 1.1 Purpose

This document defines the comprehensive database schema for all 15 user roles in the Neorem Property Management Platform. Each role has a dedicated profile table containing role-specific attributes.

### 1.2 Design Principles

- **UUID Primary Keys:** All tables use `gen_random_uuid()` for primary keys
- **Audit Trail:** All tables include `created_at`, `updated_at`, `created_by`, `updated_by`
- **Soft Deletes:** All tables include `deleted_at`, `deleted_by` for recycle bin functionality
- **Foreign Keys:** Enforced with appropriate CASCADE/RESTRICT rules
- **JSONB Fields:** Used for flexible, structured data (arrays, nested objects)

### 1.3 Standard Audit Fields

All profile tables include these audit fields:

```sql
-- Audit fields (required for all tables)
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
created_by UUID REFERENCES users(id),
updated_by UUID REFERENCES users(id),
-- Soft delete fields
deleted_at TIMESTAMP WITH TIME ZONE,
deleted_by UUID REFERENCES users(id)
```

---

## 2. Role Definitions

| # | Role | Description |
|---|------|-------------|
| 1 | Super Admin | Full control over system configuration and user management |
| 2 | Individual Property Owner | Self-managing property owner handling all operations directly |
| 3 | Property Owner/Investor (Managed) | Property owner with management company oversight |
| 4 | Real Estate Investor | Tracks and analyzes multiple property investments |
| 5 | CEO | Company-wide operations oversight and executive reporting |
| 6 | CFO | Financial oversight, budgeting, and compliance |
| 7 | Portfolio Manager | Manages groups of properties or regions |
| 8 | Property Manager | Handles daily operations for assigned properties |
| 9 | Property Administrator | Administrative support for property managers |
| 10 | Maintenance Coordinator | Assigns and tracks maintenance work orders |
| 11 | Maintenance Technician | Completes assigned maintenance work |
| 12 | Maintenance Vendor/Contractor | Third-party maintenance services |
| 13 | Financial & Accounting Teams | Financial transactions and reconciliations |
| 14 | Tenant (Residential) | Residential tenant self-service |
| 15 | Tenant (Commercial) | Commercial tenant with business features |

---

## 3. Core Roles Enum

### 3.1 Updated Users Table Role Constraint

```sql
-- Alter users table to support all 15 roles
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN (
    'SUPER_ADMIN',
    'INDIVIDUAL_OWNER',
    'MANAGED_OWNER',
    'INVESTOR',
    'CEO',
    'CFO',
    'PORTFOLIO_MANAGER',
    'PROPERTY_MANAGER',
    'PROPERTY_ADMIN',
    'MAINTENANCE_COORDINATOR',
    'MAINTENANCE_TECHNICIAN',
    'MAINTENANCE_VENDOR',
    'FINANCE_ACCOUNTING',
    'TENANT_RESIDENTIAL',
    'TENANT_COMMERCIAL'
));
```

### 3.2 Role Type Enum (Alternative)

```sql
-- Create enum type for roles
CREATE TYPE user_role AS ENUM (
    'SUPER_ADMIN',
    'INDIVIDUAL_OWNER',
    'MANAGED_OWNER',
    'INVESTOR',
    'CEO',
    'CFO',
    'PORTFOLIO_MANAGER',
    'PROPERTY_MANAGER',
    'PROPERTY_ADMIN',
    'MAINTENANCE_COORDINATOR',
    'MAINTENANCE_TECHNICIAN',
    'MAINTENANCE_VENDOR',
    'FINANCE_ACCOUNTING',
    'TENANT_RESIDENTIAL',
    'TENANT_COMMERCIAL'
);
```

---

## 4. Role Profile Tables

### 4.1 super_admin_profiles

Stores extended profile data for Super Admin users with full system access.

```sql
CREATE TABLE super_admin_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Access Control
    access_level INTEGER DEFAULT 10 CHECK (access_level BETWEEN 1 AND 10),
    can_manage_tenants BOOLEAN DEFAULT TRUE,
    can_manage_integrations BOOLEAN DEFAULT TRUE,
    can_manage_billing BOOLEAN DEFAULT TRUE,
    can_manage_organizations BOOLEAN DEFAULT TRUE,
    
    -- System Access
    system_config_access BOOLEAN DEFAULT TRUE,
    audit_log_access BOOLEAN DEFAULT TRUE,
    can_impersonate_users BOOLEAN DEFAULT FALSE,
    can_access_all_data BOOLEAN DEFAULT TRUE,
    
    -- Security Settings
    ip_whitelist JSONB DEFAULT '[]'::JSONB, -- ["192.168.1.1", "10.0.0.0/24"]
    mfa_enforced BOOLEAN DEFAULT TRUE,
    session_timeout_minutes INTEGER DEFAULT 30,
    max_concurrent_sessions INTEGER DEFAULT 3,
    
    -- Activity Tracking
    last_system_action TIMESTAMP WITH TIME ZONE,
    last_config_change TIMESTAMP WITH TIME ZONE,
    total_actions_count INTEGER DEFAULT 0,
    
    -- Notifications
    receive_system_alerts BOOLEAN DEFAULT TRUE,
    receive_security_alerts BOOLEAN DEFAULT TRUE,
    alert_email VARCHAR(255),
    alert_phone VARCHAR(20),
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_super_admin_profiles_user_id ON super_admin_profiles(user_id);
CREATE INDEX idx_super_admin_profiles_access_level ON super_admin_profiles(access_level);
CREATE INDEX idx_super_admin_profiles_deleted_at ON super_admin_profiles(deleted_at) WHERE deleted_at IS NULL;
```

---

### 4.2 owner_profiles

Stores profile data for Individual Property Owners and Managed Property Owners.

```sql
CREATE TABLE owner_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Owner Type Classification
    owner_type VARCHAR(20) NOT NULL CHECK (owner_type IN ('SELF_MANAGING', 'MANAGED')),
    
    -- Business Information
    tax_id VARCHAR(50),
    business_name VARCHAR(255),
    business_type VARCHAR(50) CHECK (business_type IN (
        'INDIVIDUAL', 'LLC', 'CORPORATION', 'PARTNERSHIP', 'TRUST', 'OTHER'
    )),
    registration_number VARCHAR(100),
    business_address JSONB, -- {street, city, state, country, postal_code}
    
    -- Portfolio Summary (Computed/Cached)
    total_properties INTEGER DEFAULT 0,
    total_units INTEGER DEFAULT 0,
    total_sqft DECIMAL(12, 2) DEFAULT 0,
    portfolio_value DECIMAL(15, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Financial Information
    bank_account_info JSONB, -- {bank_name, account_number, routing_number, account_type}
    payment_preferences VARCHAR(20) DEFAULT 'BANK_TRANSFER' CHECK (payment_preferences IN (
        'BANK_TRANSFER', 'CHECK', 'WIRE', 'ACH'
    )),
    default_payment_terms INTEGER DEFAULT 30, -- Days
    
    -- Management Company (for MANAGED type)
    preferred_management_company_id UUID,
    management_contract_id UUID,
    contract_with_management BOOLEAN DEFAULT FALSE,
    management_fee_percentage DECIMAL(5, 2),
    management_start_date DATE,
    
    -- Reporting Preferences
    receives_monthly_reports BOOLEAN DEFAULT TRUE,
    receives_financial_statements BOOLEAN DEFAULT TRUE,
    receives_occupancy_reports BOOLEAN DEFAULT TRUE,
    report_delivery_method VARCHAR(20) DEFAULT 'EMAIL' CHECK (report_delivery_method IN (
        'EMAIL', 'PORTAL', 'BOTH'
    )),
    fiscal_year_end_month INTEGER DEFAULT 12 CHECK (fiscal_year_end_month BETWEEN 1 AND 12),
    
    -- Contact Information
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_email VARCHAR(255),
    emergency_contact_relationship VARCHAR(50),
    
    -- Preferences
    preferred_contact_method VARCHAR(20) DEFAULT 'EMAIL' CHECK (preferred_contact_method IN (
        'EMAIL', 'PHONE', 'SMS', 'PORTAL'
    )),
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    
    -- Verification Status
    identity_verified BOOLEAN DEFAULT FALSE,
    identity_verified_at TIMESTAMP WITH TIME ZONE,
    tax_id_verified BOOLEAN DEFAULT FALSE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_owner_profiles_user_id ON owner_profiles(user_id);
CREATE INDEX idx_owner_profiles_owner_type ON owner_profiles(owner_type);
CREATE INDEX idx_owner_profiles_tax_id ON owner_profiles(tax_id);
CREATE INDEX idx_owner_profiles_management_company ON owner_profiles(preferred_management_company_id);
CREATE INDEX idx_owner_profiles_deleted_at ON owner_profiles(deleted_at) WHERE deleted_at IS NULL;
```

---

### 4.3 investor_profiles

Stores profile data for Real Estate Investors tracking multiple investments.

```sql
CREATE TABLE investor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Investor Classification
    investor_type VARCHAR(20) NOT NULL CHECK (investor_type IN (
        'INDIVIDUAL', 'INSTITUTIONAL', 'REIT', 'FUND', 'FAMILY_OFFICE'
    )),
    accredited_investor BOOLEAN DEFAULT FALSE,
    accreditation_verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Entity Information
    investment_entity_name VARCHAR(255),
    tax_id VARCHAR(50),
    registration_number VARCHAR(100),
    entity_type VARCHAR(50) CHECK (entity_type IN (
        'INDIVIDUAL', 'LLC', 'LP', 'CORPORATION', 'TRUST', 'REIT', 'OTHER'
    )),
    entity_address JSONB, -- {street, city, state, country, postal_code}
    formation_date DATE,
    jurisdiction VARCHAR(100),
    
    -- Portfolio Summary
    total_investments INTEGER DEFAULT 0,
    active_investments INTEGER DEFAULT 0,
    portfolio_value DECIMAL(15, 2) DEFAULT 0,
    total_invested DECIMAL(15, 2) DEFAULT 0,
    total_returns DECIMAL(15, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Investment Parameters
    target_roi DECIMAL(5, 2), -- Percentage
    minimum_investment DECIMAL(15, 2),
    maximum_investment DECIMAL(15, 2),
    investment_strategy VARCHAR(20) CHECK (investment_strategy IN (
        'GROWTH', 'INCOME', 'BALANCED', 'VALUE', 'OPPORTUNISTIC'
    )),
    risk_tolerance VARCHAR(10) CHECK (risk_tolerance IN ('LOW', 'MEDIUM', 'HIGH')),
    investment_horizon_years INTEGER,
    
    -- Investment Preferences
    preferred_property_types JSONB DEFAULT '[]'::JSONB, -- ["COMMERCIAL", "RESIDENTIAL", "MIXED_USE"]
    preferred_locations JSONB DEFAULT '[]'::JSONB, -- [{city, state, country}]
    preferred_asset_classes JSONB DEFAULT '[]'::JSONB, -- ["OFFICE", "RETAIL", "INDUSTRIAL"]
    excluded_sectors JSONB DEFAULT '[]'::JSONB,
    
    -- Financial Information
    bank_account_info JSONB, -- {bank_name, account_number, routing_number}
    dividend_preferences VARCHAR(20) DEFAULT 'REINVEST' CHECK (dividend_preferences IN (
        'REINVEST', 'DISTRIBUTE', 'ACCUMULATE'
    )),
    distribution_frequency VARCHAR(20) DEFAULT 'QUARTERLY' CHECK (distribution_frequency IN (
        'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL'
    )),
    
    -- Advisor Information
    advisor_name VARCHAR(255),
    advisor_company VARCHAR(255),
    advisor_contact VARCHAR(255),
    advisor_email VARCHAR(255),
    
    -- Reporting Preferences
    receives_quarterly_reports BOOLEAN DEFAULT TRUE,
    receives_annual_reports BOOLEAN DEFAULT TRUE,
    receives_tax_documents BOOLEAN DEFAULT TRUE,
    receives_market_updates BOOLEAN DEFAULT TRUE,
    report_format VARCHAR(10) DEFAULT 'PDF' CHECK (report_format IN ('PDF', 'EXCEL', 'BOTH')),
    
    -- KYC/AML
    kyc_status VARCHAR(20) DEFAULT 'PENDING' CHECK (kyc_status IN (
        'PENDING', 'IN_PROGRESS', 'VERIFIED', 'REJECTED', 'EXPIRED'
    )),
    kyc_verified_at TIMESTAMP WITH TIME ZONE,
    kyc_expiry_date DATE,
    aml_check_status VARCHAR(20) DEFAULT 'PENDING',
    aml_check_date TIMESTAMP WITH TIME ZONE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_investor_profiles_user_id ON investor_profiles(user_id);
CREATE INDEX idx_investor_profiles_investor_type ON investor_profiles(investor_type);
CREATE INDEX idx_investor_profiles_tax_id ON investor_profiles(tax_id);
CREATE INDEX idx_investor_profiles_investment_strategy ON investor_profiles(investment_strategy);
CREATE INDEX idx_investor_profiles_kyc_status ON investor_profiles(kyc_status);
CREATE INDEX idx_investor_profiles_deleted_at ON investor_profiles(deleted_at) WHERE deleted_at IS NULL;
```

---

### 4.4 executive_profiles

Stores profile data for CEO and CFO roles with executive-level access.

```sql
CREATE TABLE executive_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Executive Role
    executive_role VARCHAR(10) NOT NULL CHECK (executive_role IN ('CEO', 'CFO')),
    
    -- Employment Information
    department VARCHAR(100),
    title VARCHAR(255) NOT NULL,
    employment_start_date DATE,
    employment_type VARCHAR(20) DEFAULT 'FULL_TIME' CHECK (employment_type IN (
        'FULL_TIME', 'PART_TIME', 'CONTRACT', 'INTERIM'
    )),
    employee_id VARCHAR(50),
    
    -- Authorization Levels
    authorization_level INTEGER DEFAULT 10 CHECK (authorization_level BETWEEN 1 AND 10),
    signature_authority_limit DECIMAL(15, 2), -- Maximum amount can approve
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Approval Permissions
    can_approve_budgets BOOLEAN DEFAULT TRUE,
    budget_approval_limit DECIMAL(15, 2),
    can_approve_contracts BOOLEAN DEFAULT TRUE,
    contract_approval_limit DECIMAL(15, 2),
    can_approve_vendors BOOLEAN DEFAULT TRUE,
    vendor_approval_limit DECIMAL(15, 2),
    can_approve_hires BOOLEAN DEFAULT TRUE,
    can_approve_terminations BOOLEAN DEFAULT TRUE,
    can_approve_salary_changes BOOLEAN DEFAULT TRUE,
    
    -- Dashboard Access
    reporting_dashboard_access BOOLEAN DEFAULT TRUE,
    financial_dashboard_access BOOLEAN DEFAULT TRUE,
    operations_dashboard_access BOOLEAN DEFAULT TRUE,
    hr_dashboard_access BOOLEAN DEFAULT TRUE,
    analytics_dashboard_access BOOLEAN DEFAULT TRUE,
    
    -- Equity & Compensation
    board_member BOOLEAN DEFAULT FALSE,
    board_position VARCHAR(100),
    equity_holder BOOLEAN DEFAULT FALSE,
    equity_percentage DECIMAL(5, 2),
    equity_vesting_schedule JSONB, -- {start_date, end_date, cliff_months, vesting_months}
    compensation_details JSONB, -- {base_salary, bonus_target, benefits}
    
    -- Delegation
    assistant_user_id UUID REFERENCES users(id),
    delegate_user_id UUID REFERENCES users(id),
    delegation_start_date DATE,
    delegation_end_date DATE,
    delegation_permissions JSONB DEFAULT '[]'::JSONB,
    
    -- Office & Contact
    office_location VARCHAR(255),
    office_phone VARCHAR(20),
    office_extension VARCHAR(10),
    executive_assistant_name VARCHAR(255),
    executive_assistant_email VARCHAR(255),
    executive_assistant_phone VARCHAR(20),
    
    -- Organizational
    direct_reports_count INTEGER DEFAULT 0,
    organization_id UUID,
    reports_to_user_id UUID REFERENCES users(id),
    
    -- Preferences
    preferred_meeting_times JSONB, -- [{day, start_time, end_time}]
    timezone VARCHAR(50) DEFAULT 'UTC',
    out_of_office_message TEXT,
    out_of_office_start DATE,
    out_of_office_end DATE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_executive_profiles_user_id ON executive_profiles(user_id);
CREATE INDEX idx_executive_profiles_executive_role ON executive_profiles(executive_role);
CREATE INDEX idx_executive_profiles_authorization_level ON executive_profiles(authorization_level);
CREATE INDEX idx_executive_profiles_organization ON executive_profiles(organization_id);
CREATE INDEX idx_executive_profiles_deleted_at ON executive_profiles(deleted_at) WHERE deleted_at IS NULL;
```

---

### 4.5 portfolio_manager_profiles

Stores profile data for Portfolio Managers overseeing groups of properties.

```sql
CREATE TABLE portfolio_manager_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Portfolio Assignment
    managed_portfolio_ids JSONB DEFAULT '[]'::JSONB, -- [uuid, uuid, ...]
    managed_property_ids JSONB DEFAULT '[]'::JSONB,
    
    -- Portfolio Metrics (Cached)
    total_properties_managed INTEGER DEFAULT 0,
    total_units_managed INTEGER DEFAULT 0,
    total_sqft_managed DECIMAL(15, 2) DEFAULT 0,
    total_value_managed DECIMAL(15, 2) DEFAULT 0,
    average_occupancy_rate DECIMAL(5, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Region & Specialization
    region_assignments JSONB DEFAULT '[]'::JSONB, -- [{region, city, state, country}]
    specialization VARCHAR(20) CHECK (specialization IN (
        'COMMERCIAL', 'RESIDENTIAL', 'MIXED', 'INDUSTRIAL', 'RETAIL'
    )),
    asset_class_focus JSONB DEFAULT '[]'::JSONB, -- ["OFFICE", "RETAIL"]
    
    -- Performance Targets
    kpi_targets JSONB, -- {occupancy_target, noi_target, collections_target}
    performance_bonus_eligible BOOLEAN DEFAULT TRUE,
    bonus_structure JSONB, -- {target_percentage, metrics, thresholds}
    performance_review_date DATE,
    
    -- Credentials
    certifications JSONB DEFAULT '[]'::JSONB, -- [{name, issuer, issue_date, expiry_date}]
    license_number VARCHAR(100),
    license_state VARCHAR(50),
    license_expiry DATE,
    education JSONB, -- [{degree, institution, year}]
    years_experience INTEGER,
    
    -- Compensation
    reports_to_user_id UUID REFERENCES users(id),
    commission_rate DECIMAL(5, 2), -- Percentage
    base_salary DECIMAL(12, 2),
    salary_currency VARCHAR(3) DEFAULT 'USD',
    
    -- Approval Authority
    can_approve_leases BOOLEAN DEFAULT TRUE,
    lease_approval_limit DECIMAL(12, 2),
    can_approve_capex BOOLEAN DEFAULT TRUE,
    capex_approval_limit DECIMAL(12, 2),
    approval_limit DECIMAL(12, 2),
    escalation_threshold DECIMAL(12, 2),
    
    -- Communication
    preferred_contact_method VARCHAR(20) DEFAULT 'EMAIL',
    office_phone VARCHAR(20),
    mobile_phone VARCHAR(20),
    office_location VARCHAR(255),
    
    -- Availability
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (availability_status IN (
        'AVAILABLE', 'BUSY', 'ON_LEAVE', 'OUT_OF_OFFICE'
    )),
    working_hours JSONB, -- {start_time, end_time, timezone}
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_portfolio_manager_profiles_user_id ON portfolio_manager_profiles(user_id);
CREATE INDEX idx_portfolio_manager_profiles_specialization ON portfolio_manager_profiles(specialization);
CREATE INDEX idx_portfolio_manager_profiles_reports_to ON portfolio_manager_profiles(reports_to_user_id);
CREATE INDEX idx_portfolio_manager_profiles_deleted_at ON portfolio_manager_profiles(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_portfolio_manager_profiles_portfolios ON portfolio_manager_profiles USING GIN (managed_portfolio_ids);
```

---

### 4.6 property_manager_profiles

Stores profile data for Property Managers handling daily operations.

```sql
CREATE TABLE property_manager_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Property Assignment
    assigned_property_ids JSONB DEFAULT '[]'::JSONB, -- [uuid, uuid, ...]
    primary_property_id UUID,
    
    -- Portfolio Metrics (Cached)
    total_properties INTEGER DEFAULT 0,
    total_units INTEGER DEFAULT 0,
    total_sqft DECIMAL(12, 2) DEFAULT 0,
    current_occupancy_rate DECIMAL(5, 2),
    occupancy_target DECIMAL(5, 2) DEFAULT 95.00,
    
    -- Specialization
    specialization VARCHAR(20) CHECK (specialization IN (
        'COMMERCIAL', 'RESIDENTIAL', 'MIXED', 'INDUSTRIAL', 'RETAIL', 'HOSPITALITY'
    )),
    property_types_experience JSONB DEFAULT '[]'::JSONB,
    years_experience INTEGER,
    
    -- Credentials
    certifications JSONB DEFAULT '[]'::JSONB, -- [{name, issuer, issue_date, expiry_date}]
    license_number VARCHAR(100),
    license_state VARCHAR(50),
    license_expiry DATE,
    continuing_education_credits INTEGER DEFAULT 0,
    ce_due_date DATE,
    
    -- Reporting Structure
    reports_to_user_id UUID REFERENCES users(id),
    portfolio_manager_id UUID REFERENCES users(id),
    team_lead BOOLEAN DEFAULT FALSE,
    team_members JSONB DEFAULT '[]'::JSONB, -- [user_id, ...]
    
    -- Compensation
    commission_rate DECIMAL(5, 2),
    bonus_structure JSONB, -- {metrics, targets, percentages}
    base_salary DECIMAL(12, 2),
    salary_currency VARCHAR(3) DEFAULT 'USD',
    
    -- Approval Permissions
    can_approve_maintenance BOOLEAN DEFAULT TRUE,
    maintenance_approval_limit DECIMAL(10, 2),
    can_approve_leases BOOLEAN DEFAULT TRUE,
    lease_approval_limit DECIMAL(12, 2),
    can_approve_vendors BOOLEAN DEFAULT FALSE,
    vendor_approval_limit DECIMAL(10, 2),
    can_waive_fees BOOLEAN DEFAULT FALSE,
    fee_waiver_limit DECIMAL(8, 2),
    
    -- Operational Responsibilities
    handles_move_in BOOLEAN DEFAULT TRUE,
    handles_move_out BOOLEAN DEFAULT TRUE,
    handles_inspections BOOLEAN DEFAULT TRUE,
    handles_lease_renewals BOOLEAN DEFAULT TRUE,
    handles_rent_collection BOOLEAN DEFAULT TRUE,
    handles_tenant_relations BOOLEAN DEFAULT TRUE,
    handles_vendor_coordination BOOLEAN DEFAULT TRUE,
    
    -- Emergency Contact
    emergency_contact_priority INTEGER DEFAULT 1, -- 1 = Primary
    on_call_schedule JSONB, -- [{day, start_time, end_time}]
    backup_manager_id UUID REFERENCES users(id),
    
    -- Contact Information
    office_phone VARCHAR(20),
    mobile_phone VARCHAR(20),
    office_location VARCHAR(255),
    preferred_contact_method VARCHAR(20) DEFAULT 'EMAIL',
    
    -- Availability
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (availability_status IN (
        'AVAILABLE', 'BUSY', 'ON_LEAVE', 'OUT_OF_OFFICE'
    )),
    working_hours JSONB, -- {start_time, end_time, timezone}
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Performance Metrics
    tenant_satisfaction_score DECIMAL(3, 2),
    response_time_avg_hours DECIMAL(5, 2),
    maintenance_completion_rate DECIMAL(5, 2),
    lease_renewal_rate DECIMAL(5, 2),
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_property_manager_profiles_user_id ON property_manager_profiles(user_id);
CREATE INDEX idx_property_manager_profiles_specialization ON property_manager_profiles(specialization);
CREATE INDEX idx_property_manager_profiles_reports_to ON property_manager_profiles(reports_to_user_id);
CREATE INDEX idx_property_manager_profiles_availability ON property_manager_profiles(availability_status);
CREATE INDEX idx_property_manager_profiles_deleted_at ON property_manager_profiles(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_property_manager_profiles_properties ON property_manager_profiles USING GIN (assigned_property_ids);
```

---

### 4.7 property_admin_profiles

Stores profile data for Property Administrators providing administrative support.

```sql
CREATE TABLE property_admin_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Assignment
    assigned_property_ids JSONB DEFAULT '[]'::JSONB, -- [uuid, uuid, ...]
    primary_property_id UUID,
    
    -- Reporting Structure
    reports_to_manager_id UUID REFERENCES users(id),
    department VARCHAR(100),
    team_name VARCHAR(100),
    employee_id VARCHAR(50),
    
    -- Document Permissions
    can_update_records BOOLEAN DEFAULT TRUE,
    can_process_documents BOOLEAN DEFAULT TRUE,
    can_update_units BOOLEAN DEFAULT TRUE,
    can_update_tenant_info BOOLEAN DEFAULT TRUE,
    can_upload_documents BOOLEAN DEFAULT TRUE,
    can_delete_documents BOOLEAN DEFAULT FALSE,
    
    -- Reporting Permissions
    can_generate_reports BOOLEAN DEFAULT TRUE,
    report_types_access JSONB DEFAULT '[]'::JSONB, -- ["OCCUPANCY", "FINANCIAL", "MAINTENANCE"]
    can_export_data BOOLEAN DEFAULT TRUE,
    export_formats JSONB DEFAULT '["PDF", "EXCEL"]'::JSONB,
    
    -- Communication Permissions
    can_send_communications BOOLEAN DEFAULT TRUE,
    can_send_mass_communications BOOLEAN DEFAULT FALSE,
    communication_templates_access JSONB DEFAULT '[]'::JSONB,
    
    -- System Access
    document_access_level VARCHAR(20) DEFAULT 'STANDARD' CHECK (document_access_level IN (
        'LIMITED', 'STANDARD', 'FULL'
    )),
    compliance_tracking_access BOOLEAN DEFAULT TRUE,
    financial_data_access BOOLEAN DEFAULT FALSE,
    sensitive_data_access BOOLEAN DEFAULT FALSE,
    
    -- Skills & Certifications
    certifications JSONB DEFAULT '[]'::JSONB, -- [{name, issuer, expiry_date}]
    software_proficiencies JSONB DEFAULT '[]'::JSONB, -- [{software, skill_level}]
    languages JSONB DEFAULT '["English"]'::JSONB,
    typing_speed_wpm INTEGER,
    
    -- Schedule
    shift_schedule JSONB, -- {shift_type, start_time, end_time, days}
    overtime_eligible BOOLEAN DEFAULT TRUE,
    max_overtime_hours INTEGER DEFAULT 10,
    
    -- Contact Information
    desk_phone VARCHAR(20),
    extension VARCHAR(10),
    mobile_phone VARCHAR(20),
    preferred_contact_method VARCHAR(20) DEFAULT 'EMAIL',
    
    -- Availability
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (availability_status IN (
        'AVAILABLE', 'BUSY', 'ON_LEAVE', 'OUT_OF_OFFICE'
    )),
    working_hours JSONB,
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Performance
    tasks_completed_count INTEGER DEFAULT 0,
    accuracy_score DECIMAL(5, 2),
    last_performance_review DATE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_property_admin_profiles_user_id ON property_admin_profiles(user_id);
CREATE INDEX idx_property_admin_profiles_reports_to ON property_admin_profiles(reports_to_manager_id);
CREATE INDEX idx_property_admin_profiles_department ON property_admin_profiles(department);
CREATE INDEX idx_property_admin_profiles_deleted_at ON property_admin_profiles(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_property_admin_profiles_properties ON property_admin_profiles USING GIN (assigned_property_ids);
```

---

### 4.8 maintenance_coordinator_profiles

Stores profile data for Maintenance Coordinators managing work orders and scheduling.

```sql
CREATE TABLE maintenance_coordinator_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Assignment
    assigned_property_ids JSONB DEFAULT '[]'::JSONB, -- [uuid, uuid, ...]
    assigned_regions JSONB DEFAULT '[]'::JSONB, -- [{region, city, state}]
    
    -- Reporting Structure
    reports_to_user_id UUID REFERENCES users(id),
    department VARCHAR(100) DEFAULT 'Maintenance',
    team_name VARCHAR(100),
    employee_id VARCHAR(50),
    
    -- Work Order Permissions
    can_assign_work_orders BOOLEAN DEFAULT TRUE,
    can_prioritize_tasks BOOLEAN DEFAULT TRUE,
    can_schedule_vendors BOOLEAN DEFAULT TRUE,
    can_close_work_orders BOOLEAN DEFAULT TRUE,
    can_reopen_work_orders BOOLEAN DEFAULT TRUE,
    can_escalate_work_orders BOOLEAN DEFAULT TRUE,
    
    -- Vendor Management
    vendor_management_access BOOLEAN DEFAULT TRUE,
    can_approve_vendors BOOLEAN DEFAULT FALSE,
    can_rate_vendors BOOLEAN DEFAULT TRUE,
    preferred_vendors JSONB DEFAULT '[]'::JSONB, -- [vendor_id, ...]
    
    -- Inventory Management
    inventory_management_access BOOLEAN DEFAULT TRUE,
    can_order_supplies BOOLEAN DEFAULT TRUE,
    can_approve_purchase_orders BOOLEAN DEFAULT FALSE,
    
    -- Budget & Spending
    budget_allocation DECIMAL(12, 2),
    spending_limit DECIMAL(10, 2),
    purchase_order_limit DECIMAL(8, 2),
    monthly_budget_used DECIMAL(12, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Skills & Certifications
    specializations JSONB DEFAULT '[]'::JSONB, -- ["HVAC", "PLUMBING", "ELECTRICAL"]
    certifications JSONB DEFAULT '[]'::JSONB, -- [{name, issuer, expiry_date}]
    safety_training_completed BOOLEAN DEFAULT FALSE,
    safety_training_expiry DATE,
    
    -- Performance Metrics
    average_response_time_hours DECIMAL(5, 2),
    work_orders_assigned_count INTEGER DEFAULT 0,
    work_orders_completed_count INTEGER DEFAULT 0,
    on_time_completion_rate DECIMAL(5, 2),
    kpi_targets JSONB, -- {response_time_target, completion_rate_target}
    
    -- Emergency Handling
    emergency_escalation_contact VARCHAR(255),
    emergency_escalation_phone VARCHAR(20),
    on_call_rotation JSONB, -- [{week_number, start_date, end_date}]
    is_currently_on_call BOOLEAN DEFAULT FALSE,
    
    -- Contact Information
    office_phone VARCHAR(20),
    mobile_phone VARCHAR(20),
    radio_channel VARCHAR(20),
    preferred_contact_method VARCHAR(20) DEFAULT 'PHONE',
    
    -- Availability
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (availability_status IN (
        'AVAILABLE', 'BUSY', 'ON_LEAVE', 'OUT_OF_OFFICE', 'ON_CALL'
    )),
    working_hours JSONB,
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_maintenance_coordinator_profiles_user_id ON maintenance_coordinator_profiles(user_id);
CREATE INDEX idx_maintenance_coordinator_profiles_reports_to ON maintenance_coordinator_profiles(reports_to_user_id);
CREATE INDEX idx_maintenance_coordinator_profiles_on_call ON maintenance_coordinator_profiles(is_currently_on_call);
CREATE INDEX idx_maintenance_coordinator_profiles_deleted_at ON maintenance_coordinator_profiles(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_maintenance_coordinator_profiles_properties ON maintenance_coordinator_profiles USING GIN (assigned_property_ids);
```

---

### 4.9 maintenance_technician_profiles

Stores profile data for Maintenance Technicians performing repairs and maintenance.

```sql
CREATE TABLE maintenance_technician_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Employment Information
    employee_id VARCHAR(50),
    employment_type VARCHAR(20) DEFAULT 'FULL_TIME' CHECK (employment_type IN (
        'FULL_TIME', 'PART_TIME', 'CONTRACT', 'SEASONAL'
    )),
    hire_date DATE,
    
    -- Reporting Structure
    reports_to_coordinator_id UUID REFERENCES users(id),
    team_id UUID,
    team_name VARCHAR(100),
    
    -- Skills & Specializations
    skill_set JSONB DEFAULT '[]'::JSONB, -- [{skill, proficiency_level}]
    primary_specialization VARCHAR(30) CHECK (primary_specialization IN (
        'PLUMBING', 'ELECTRICAL', 'HVAC', 'CARPENTRY', 'PAINTING', 
        'APPLIANCE_REPAIR', 'LANDSCAPING', 'GENERAL', 'FLOORING', 'ROOFING'
    )),
    secondary_specializations JSONB DEFAULT '[]'::JSONB,
    
    -- Certifications & Licenses
    certifications JSONB DEFAULT '[]'::JSONB, -- [{name, issuer, issue_date, expiry_date, number}]
    license_numbers JSONB DEFAULT '[]'::JSONB, -- [{type, number, state, expiry_date}]
    epa_certification BOOLEAN DEFAULT FALSE,
    epa_certification_type VARCHAR(50),
    epa_expiry_date DATE,
    
    -- Assignment
    assigned_property_ids JSONB DEFAULT '[]'::JSONB,
    service_regions JSONB DEFAULT '[]'::JSONB, -- [{region, zip_codes}]
    max_daily_work_orders INTEGER DEFAULT 8,
    
    -- Compensation
    hourly_rate DECIMAL(8, 2),
    overtime_rate DECIMAL(8, 2),
    on_call_rate DECIMAL(8, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Availability
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (availability_status IN (
        'AVAILABLE', 'BUSY', 'ON_JOB', 'ON_BREAK', 'ON_LEAVE', 'OFF_DUTY', 'ON_CALL'
    )),
    current_location JSONB, -- {latitude, longitude, last_updated}
    shift_schedule JSONB, -- {shift_type, start_time, end_time, days}
    
    -- Equipment & Vehicle
    tools_assigned JSONB DEFAULT '[]'::JSONB, -- [{tool_id, name, serial_number}]
    vehicle_assigned BOOLEAN DEFAULT FALSE,
    vehicle_id VARCHAR(50),
    vehicle_type VARCHAR(50),
    vehicle_license_plate VARCHAR(20),
    
    -- Performance Metrics
    average_completion_time_hours DECIMAL(5, 2),
    quality_rating DECIMAL(3, 2), -- 1.00 to 5.00
    jobs_completed INTEGER DEFAULT 0,
    jobs_completed_this_month INTEGER DEFAULT 0,
    first_time_fix_rate DECIMAL(5, 2),
    customer_satisfaction_score DECIMAL(3, 2),
    
    -- Mobile App & Permissions
    can_upload_photos BOOLEAN DEFAULT TRUE,
    can_update_status BOOLEAN DEFAULT TRUE,
    can_order_parts BOOLEAN DEFAULT FALSE,
    mobile_app_enabled BOOLEAN DEFAULT TRUE,
    last_app_login TIMESTAMP WITH TIME ZONE,
    
    -- Safety & Training
    uniform_size VARCHAR(10),
    safety_training_completed BOOLEAN DEFAULT FALSE,
    safety_training_date DATE,
    training_expiry DATE,
    incident_count INTEGER DEFAULT 0,
    last_incident_date DATE,
    
    -- Contact Information
    mobile_phone VARCHAR(20) NOT NULL,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    preferred_contact_method VARCHAR(20) DEFAULT 'SMS',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_maintenance_technician_profiles_user_id ON maintenance_technician_profiles(user_id);
CREATE INDEX idx_maintenance_technician_profiles_coordinator ON maintenance_technician_profiles(reports_to_coordinator_id);
CREATE INDEX idx_maintenance_technician_profiles_specialization ON maintenance_technician_profiles(primary_specialization);
CREATE INDEX idx_maintenance_technician_profiles_availability ON maintenance_technician_profiles(availability_status);
CREATE INDEX idx_maintenance_technician_profiles_deleted_at ON maintenance_technician_profiles(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_maintenance_technician_profiles_properties ON maintenance_technician_profiles USING GIN (assigned_property_ids);
CREATE INDEX idx_maintenance_technician_profiles_skills ON maintenance_technician_profiles USING GIN (skill_set);
```

---

### 4.10 maintenance_vendor_profiles

Stores profile data for external Maintenance Vendors and Contractors.

```sql
CREATE TABLE maintenance_vendor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Company Information
    company_name VARCHAR(255) NOT NULL,
    dba_name VARCHAR(255), -- Doing Business As
    business_registration_number VARCHAR(100),
    tax_id VARCHAR(50),
    business_type VARCHAR(50) CHECK (business_type IN (
        'SOLE_PROPRIETOR', 'LLC', 'CORPORATION', 'PARTNERSHIP', 'OTHER'
    )),
    year_established INTEGER,
    number_of_employees INTEGER,
    
    -- Insurance Information
    insurance_policy_number VARCHAR(100),
    insurance_provider VARCHAR(255),
    insurance_coverage_amount DECIMAL(12, 2),
    insurance_expiry DATE,
    insurance_verified BOOLEAN DEFAULT FALSE,
    insurance_verified_at TIMESTAMP WITH TIME ZONE,
    liability_insurance BOOLEAN DEFAULT FALSE,
    workers_comp_insurance BOOLEAN DEFAULT FALSE,
    workers_comp_policy_number VARCHAR(100),
    workers_comp_expiry DATE,
    
    -- Licenses & Certifications
    license_numbers JSONB DEFAULT '[]'::JSONB, -- [{type, number, state, expiry_date}]
    certifications JSONB DEFAULT '[]'::JSONB, -- [{name, issuer, expiry_date}]
    bonded BOOLEAN DEFAULT FALSE,
    bond_amount DECIMAL(12, 2),
    bond_expiry DATE,
    
    -- Services Offered
    service_categories JSONB DEFAULT '[]'::JSONB, -- ["PLUMBING", "ELECTRICAL", "HVAC"]
    specializations JSONB DEFAULT '[]'::JSONB, -- More specific services
    emergency_services_available BOOLEAN DEFAULT FALSE,
    after_hours_available BOOLEAN DEFAULT FALSE,
    weekend_available BOOLEAN DEFAULT FALSE,
    
    -- Service Area
    service_areas JSONB DEFAULT '[]'::JSONB, -- [{city, state, zip_codes}]
    service_radius_miles INTEGER,
    headquarters_address JSONB, -- {street, city, state, zip, country}
    
    -- Pricing
    hourly_rate DECIMAL(8, 2),
    emergency_rate DECIMAL(8, 2),
    after_hours_rate DECIMAL(8, 2),
    minimum_charge DECIMAL(8, 2),
    trip_charge DECIMAL(8, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Payment Information
    payment_terms VARCHAR(50) DEFAULT 'NET_30' CHECK (payment_terms IN (
        'DUE_ON_RECEIPT', 'NET_15', 'NET_30', 'NET_45', 'NET_60'
    )),
    bank_account_info JSONB, -- {bank_name, account_number, routing_number}
    accepts_credit_cards BOOLEAN DEFAULT FALSE,
    accepts_ach BOOLEAN DEFAULT TRUE,
    
    -- Primary Contact
    contact_person VARCHAR(255),
    contact_title VARCHAR(100),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    contact_mobile VARCHAR(20),
    
    -- Secondary Contact
    secondary_contact_name VARCHAR(255),
    secondary_contact_phone VARCHAR(20),
    secondary_contact_email VARCHAR(255),
    
    -- Performance Metrics
    average_rating DECIMAL(3, 2), -- 1.00 to 5.00
    total_jobs_completed INTEGER DEFAULT 0,
    jobs_completed_this_year INTEGER DEFAULT 0,
    response_time_hours DECIMAL(5, 2),
    on_time_completion_rate DECIMAL(5, 2),
    callback_rate DECIMAL(5, 2), -- Percentage of jobs requiring callback
    
    -- Vendor Status
    preferred_vendor BOOLEAN DEFAULT FALSE,
    approved_vendor BOOLEAN DEFAULT FALSE,
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    vendor_tier VARCHAR(20) CHECK (vendor_tier IN ('STANDARD', 'PREFERRED', 'PREMIUM')),
    
    -- Contract Information
    contract_start_date DATE,
    contract_end_date DATE,
    contract_document_url VARCHAR(500),
    auto_renew BOOLEAN DEFAULT FALSE,
    
    -- Compliance
    background_check_completed BOOLEAN DEFAULT FALSE,
    background_check_date DATE,
    drug_test_required BOOLEAN DEFAULT FALSE,
    last_drug_test_date DATE,
    w9_on_file BOOLEAN DEFAULT FALSE,
    w9_received_date DATE,
    
    -- Communication Preferences
    preferred_contact_method VARCHAR(20) DEFAULT 'EMAIL' CHECK (preferred_contact_method IN (
        'EMAIL', 'PHONE', 'SMS', 'PORTAL'
    )),
    notification_preferences JSONB DEFAULT '{"new_work_orders": true, "payment_received": true}'::JSONB,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_maintenance_vendor_profiles_user_id ON maintenance_vendor_profiles(user_id);
CREATE INDEX idx_maintenance_vendor_profiles_company ON maintenance_vendor_profiles(company_name);
CREATE INDEX idx_maintenance_vendor_profiles_tax_id ON maintenance_vendor_profiles(tax_id);
CREATE INDEX idx_maintenance_vendor_profiles_preferred ON maintenance_vendor_profiles(preferred_vendor) WHERE preferred_vendor = TRUE;
CREATE INDEX idx_maintenance_vendor_profiles_approved ON maintenance_vendor_profiles(approved_vendor) WHERE approved_vendor = TRUE;
CREATE INDEX idx_maintenance_vendor_profiles_deleted_at ON maintenance_vendor_profiles(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_maintenance_vendor_profiles_services ON maintenance_vendor_profiles USING GIN (service_categories);
CREATE INDEX idx_maintenance_vendor_profiles_areas ON maintenance_vendor_profiles USING GIN (service_areas);
```

---

### 4.11 finance_profiles

Stores profile data for Financial and Accounting Team members.

```sql
CREATE TABLE finance_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Employment Information
    department VARCHAR(50) NOT NULL CHECK (department IN (
        'ACCOUNTING', 'FINANCE', 'AUDIT', 'TAX', 'TREASURY', 'PAYROLL'
    )),
    title VARCHAR(255) NOT NULL,
    employee_id VARCHAR(50),
    hire_date DATE,
    
    -- Reporting Structure
    reports_to_user_id UUID REFERENCES users(id),
    team_name VARCHAR(100),
    is_team_lead BOOLEAN DEFAULT FALSE,
    
    -- Payment Processing Permissions
    can_process_payments BOOLEAN DEFAULT TRUE,
    can_approve_payments BOOLEAN DEFAULT FALSE,
    payment_approval_limit DECIMAL(12, 2),
    can_void_payments BOOLEAN DEFAULT FALSE,
    can_issue_refunds BOOLEAN DEFAULT FALSE,
    refund_limit DECIMAL(10, 2),
    
    -- Account Permissions
    can_reconcile_accounts BOOLEAN DEFAULT TRUE,
    can_create_journal_entries BOOLEAN DEFAULT FALSE,
    can_approve_journal_entries BOOLEAN DEFAULT FALSE,
    journal_entry_limit DECIMAL(12, 2),
    can_close_periods BOOLEAN DEFAULT FALSE,
    
    -- Reporting Permissions
    can_generate_reports BOOLEAN DEFAULT TRUE,
    report_access_level VARCHAR(20) DEFAULT 'STANDARD' CHECK (report_access_level IN (
        'LIMITED', 'STANDARD', 'FULL', 'EXECUTIVE'
    )),
    can_export_financial_data BOOLEAN DEFAULT TRUE,
    
    -- Invoice Permissions
    can_create_invoices BOOLEAN DEFAULT TRUE,
    can_approve_invoices BOOLEAN DEFAULT FALSE,
    invoice_approval_limit DECIMAL(12, 2),
    can_write_off_invoices BOOLEAN DEFAULT FALSE,
    write_off_limit DECIMAL(10, 2),
    
    -- Tax & Compliance
    can_access_tax_docs BOOLEAN DEFAULT TRUE,
    can_file_taxes BOOLEAN DEFAULT FALSE,
    can_prepare_1099s BOOLEAN DEFAULT FALSE,
    can_audit BOOLEAN DEFAULT FALSE,
    audit_access_level VARCHAR(20) CHECK (audit_access_level IN (
        'NONE', 'VIEW_ONLY', 'STANDARD', 'FULL'
    )),
    
    -- System Access Levels
    ledger_access_level VARCHAR(20) DEFAULT 'READ' CHECK (ledger_access_level IN (
        'NONE', 'READ', 'WRITE', 'FULL'
    )),
    bank_access_level VARCHAR(20) DEFAULT 'NONE' CHECK (bank_access_level IN (
        'NONE', 'VIEW', 'RECONCILE', 'FULL'
    )),
    payroll_access BOOLEAN DEFAULT FALSE,
    budget_access BOOLEAN DEFAULT FALSE,
    
    -- Certifications
    certifications JSONB DEFAULT '[]'::JSONB, -- [{type: "CPA", number, state, expiry}]
    primary_certification VARCHAR(20) CHECK (primary_certification IN (
        'CPA', 'CFA', 'CMA', 'CIA', 'CFE', 'EA', 'OTHER', 'NONE'
    )),
    license_number VARCHAR(100),
    license_state VARCHAR(50),
    license_expiry DATE,
    continuing_education_credits INTEGER DEFAULT 0,
    ce_due_date DATE,
    
    -- Signature Authority
    signature_authority BOOLEAN DEFAULT FALSE,
    signature_title VARCHAR(100),
    check_signing_limit DECIMAL(12, 2),
    wire_transfer_limit DECIMAL(12, 2),
    ach_transfer_limit DECIMAL(12, 2),
    requires_dual_approval_above DECIMAL(12, 2),
    
    -- Software Access
    software_access JSONB DEFAULT '[]'::JSONB, -- [{name, access_level}]
    erp_access_level VARCHAR(20),
    banking_portal_access BOOLEAN DEFAULT FALSE,
    
    -- System Permissions
    system_permissions JSONB DEFAULT '{}'::JSONB, -- {module: access_level}
    
    -- Contact Information
    office_phone VARCHAR(20),
    extension VARCHAR(10),
    mobile_phone VARCHAR(20),
    preferred_contact_method VARCHAR(20) DEFAULT 'EMAIL',
    
    -- Availability
    availability_status VARCHAR(20) DEFAULT 'AVAILABLE',
    working_hours JSONB,
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Performance
    transactions_processed_count INTEGER DEFAULT 0,
    accuracy_rate DECIMAL(5, 2),
    last_performance_review DATE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_finance_profiles_user_id ON finance_profiles(user_id);
CREATE INDEX idx_finance_profiles_department ON finance_profiles(department);
CREATE INDEX idx_finance_profiles_reports_to ON finance_profiles(reports_to_user_id);
CREATE INDEX idx_finance_profiles_certification ON finance_profiles(primary_certification);
CREATE INDEX idx_finance_profiles_deleted_at ON finance_profiles(deleted_at) WHERE deleted_at IS NULL;
```

---

### 4.12 tenant_residential_profiles

Stores profile data for Residential Tenants.

```sql
CREATE TABLE tenant_residential_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Tenant Classification
    tenant_type VARCHAR(20) NOT NULL CHECK (tenant_type IN (
        'INDIVIDUAL', 'FAMILY', 'ROOMMATES', 'STUDENT', 'SENIOR', 'CORPORATE'
    )),
    
    -- Current Lease Information
    current_lease_id UUID,
    current_unit_id UUID,
    current_property_id UUID,
    move_in_date DATE,
    lease_start_date DATE,
    lease_end_date DATE,
    monthly_rent DECIMAL(10, 2),
    security_deposit DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Employment Information
    employment_status VARCHAR(20) CHECK (employment_status IN (
        'EMPLOYED', 'SELF_EMPLOYED', 'UNEMPLOYED', 'STUDENT', 'RETIRED', 'OTHER'
    )),
    employer_name VARCHAR(255),
    employer_address JSONB,
    employer_phone VARCHAR(20),
    employer_contact VARCHAR(255),
    job_title VARCHAR(255),
    employment_start_date DATE,
    employment_verified BOOLEAN DEFAULT FALSE,
    employment_verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Income Verification
    annual_income DECIMAL(12, 2),
    monthly_income DECIMAL(10, 2),
    income_source VARCHAR(50),
    additional_income DECIMAL(10, 2),
    additional_income_source VARCHAR(100),
    income_verified BOOLEAN DEFAULT FALSE,
    income_verified_at TIMESTAMP WITH TIME ZONE,
    income_to_rent_ratio DECIMAL(4, 2),
    
    -- Credit & Background
    credit_score INTEGER,
    credit_checked_date DATE,
    credit_report_id VARCHAR(100),
    background_check_status VARCHAR(20) CHECK (background_check_status IN (
        'PENDING', 'IN_PROGRESS', 'PASSED', 'FAILED', 'CONDITIONAL', 'WAIVED'
    )),
    background_check_date DATE,
    background_check_provider VARCHAR(100),
    criminal_record BOOLEAN DEFAULT FALSE,
    eviction_history BOOLEAN DEFAULT FALSE,
    
    -- References
    references JSONB DEFAULT '[]'::JSONB, -- [{name, relationship, phone, email, verified}]
    previous_landlord_name VARCHAR(255),
    previous_landlord_phone VARCHAR(20),
    previous_landlord_verified BOOLEAN DEFAULT FALSE,
    previous_address JSONB,
    reason_for_moving VARCHAR(255),
    
    -- Emergency Contacts
    emergency_contacts JSONB DEFAULT '[]'::JSONB, -- [{name, relationship, phone, email, is_primary}]
    
    -- Authorized Occupants
    authorized_occupants JSONB DEFAULT '[]'::JSONB, -- [{name, relationship, dob, is_adult}]
    total_occupants INTEGER DEFAULT 1,
    adults_count INTEGER DEFAULT 1,
    children_count INTEGER DEFAULT 0,
    
    -- Pets
    has_pets BOOLEAN DEFAULT FALSE,
    pet_info JSONB DEFAULT '[]'::JSONB, -- [{type, breed, name, weight, vaccinated, pet_deposit}]
    pet_deposit_paid DECIMAL(8, 2),
    pet_rent_monthly DECIMAL(6, 2),
    
    -- Vehicles
    has_vehicles BOOLEAN DEFAULT FALSE,
    vehicle_info JSONB DEFAULT '[]'::JSONB, -- [{make, model, year, color, license_plate, state}]
    parking_space_id UUID,
    parking_permit_number VARCHAR(50),
    
    -- Communication Preferences
    preferred_contact_method VARCHAR(20) DEFAULT 'EMAIL' CHECK (preferred_contact_method IN (
        'EMAIL', 'PHONE', 'SMS', 'PORTAL', 'MAIL'
    )),
    communication_preferences JSONB DEFAULT '{
        "rent_reminders": true,
        "maintenance_updates": true,
        "community_announcements": true,
        "lease_renewal_notices": true
    }'::JSONB,
    preferred_language VARCHAR(10) DEFAULT 'en',
    
    -- Payment Information
    autopay_enabled BOOLEAN DEFAULT FALSE,
    autopay_day INTEGER CHECK (autopay_day BETWEEN 1 AND 28),
    payment_method_id UUID,
    default_payment_method VARCHAR(20) CHECK (default_payment_method IN (
        'BANK_TRANSFER', 'CREDIT_CARD', 'DEBIT_CARD', 'CHECK', 'CASH', 'MONEY_ORDER'
    )),
    billing_address JSONB, -- {street, city, state, zip, country}
    billing_same_as_unit BOOLEAN DEFAULT TRUE,
    
    -- Payment History
    payment_history_score DECIMAL(3, 2), -- 0.00 to 5.00
    on_time_payment_rate DECIMAL(5, 2),
    late_payments_count INTEGER DEFAULT 0,
    total_late_fees_paid DECIMAL(10, 2) DEFAULT 0,
    
    -- Maintenance
    maintenance_request_count INTEGER DEFAULT 0,
    open_maintenance_requests INTEGER DEFAULT 0,
    
    -- Lease Renewal
    lease_renewal_interest VARCHAR(20) CHECK (lease_renewal_interest IN (
        'INTERESTED', 'NOT_INTERESTED', 'UNDECIDED', 'NOT_ASKED'
    )),
    renewal_reminder_sent BOOLEAN DEFAULT FALSE,
    renewal_reminder_date DATE,
    preferred_lease_term INTEGER, -- Months
    
    -- Move-out Information
    notice_given BOOLEAN DEFAULT FALSE,
    notice_date DATE,
    expected_move_out_date DATE,
    move_out_reason VARCHAR(255),
    forwarding_address JSONB,
    
    -- Tenant Portal
    portal_last_login TIMESTAMP WITH TIME ZONE,
    portal_setup_completed BOOLEAN DEFAULT FALSE,
    document_upload_enabled BOOLEAN DEFAULT TRUE,
    
    -- Special Accommodations
    accessibility_needs JSONB DEFAULT '[]'::JSONB,
    special_instructions TEXT,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_tenant_residential_profiles_user_id ON tenant_residential_profiles(user_id);
CREATE INDEX idx_tenant_residential_profiles_lease ON tenant_residential_profiles(current_lease_id);
CREATE INDEX idx_tenant_residential_profiles_unit ON tenant_residential_profiles(current_unit_id);
CREATE INDEX idx_tenant_residential_profiles_property ON tenant_residential_profiles(current_property_id);
CREATE INDEX idx_tenant_residential_profiles_tenant_type ON tenant_residential_profiles(tenant_type);
CREATE INDEX idx_tenant_residential_profiles_deleted_at ON tenant_residential_profiles(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_tenant_residential_profiles_lease_end ON tenant_residential_profiles(lease_end_date);
CREATE INDEX idx_tenant_residential_profiles_payment_score ON tenant_residential_profiles(payment_history_score);
```

---

### 4.13 tenant_commercial_profiles

Stores profile data for Commercial Tenants with business-specific features.

```sql
CREATE TABLE tenant_commercial_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    
    -- Tenant Classification
    tenant_type VARCHAR(20) NOT NULL CHECK (tenant_type IN (
        'SMALL_BUSINESS', 'ENTERPRISE', 'FRANCHISE', 'GOVERNMENT', 'NON_PROFIT'
    )),
    
    -- Company Information
    company_name VARCHAR(255) NOT NULL,
    dba_name VARCHAR(255), -- Doing Business As
    business_type VARCHAR(50) CHECK (business_type IN (
        'LLC', 'CORPORATION', 'PARTNERSHIP', 'SOLE_PROPRIETOR', 'NON_PROFIT', 'GOVERNMENT', 'OTHER'
    )),
    registration_number VARCHAR(100),
    tax_id VARCHAR(50),
    state_of_incorporation VARCHAR(50),
    date_incorporated DATE,
    
    -- Business Details
    industry VARCHAR(100),
    naics_code VARCHAR(10),
    sic_code VARCHAR(10),
    company_size VARCHAR(20) CHECK (company_size IN (
        'MICRO', 'SMALL', 'MEDIUM', 'LARGE', 'ENTERPRISE'
    )),
    employee_count INTEGER,
    years_in_business INTEGER,
    website_url VARCHAR(500),
    
    -- Current Lease Information
    current_lease_id UUID,
    current_unit_id UUID,
    current_property_id UUID,
    move_in_date DATE,
    lease_start_date DATE,
    lease_end_date DATE,
    leased_sqft DECIMAL(10, 2),
    monthly_base_rent DECIMAL(12, 2),
    security_deposit DECIMAL(12, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Contacts
    primary_contact_id UUID REFERENCES users(id),
    primary_contact_name VARCHAR(255),
    primary_contact_title VARCHAR(100),
    primary_contact_phone VARCHAR(20),
    primary_contact_email VARCHAR(255),
    
    billing_contact_id UUID REFERENCES users(id),
    billing_contact_name VARCHAR(255),
    billing_contact_email VARCHAR(255),
    billing_contact_phone VARCHAR(20),
    
    -- Authorized Users (Multi-user accounts)
    authorized_users JSONB DEFAULT '[]'::JSONB, -- [{user_id, name, role, permissions}]
    max_authorized_users INTEGER DEFAULT 5,
    
    -- Financial Information
    annual_revenue DECIMAL(15, 2),
    annual_revenue_verified BOOLEAN DEFAULT FALSE,
    credit_rating VARCHAR(10), -- AAA, AA, A, BBB, etc.
    duns_number VARCHAR(20),
    financial_statements_on_file BOOLEAN DEFAULT FALSE,
    last_financial_review_date DATE,
    
    -- Insurance
    insurance_policy_number VARCHAR(100),
    insurance_provider VARCHAR(255),
    insurance_coverage_amount DECIMAL(12, 2),
    insurance_expiry DATE,
    insurance_verified BOOLEAN DEFAULT FALSE,
    liability_coverage DECIMAL(12, 2),
    property_coverage DECIMAL(12, 2),
    business_interruption_coverage BOOLEAN DEFAULT FALSE,
    
    -- CAM (Common Area Maintenance)
    cam_reconciliation_enabled BOOLEAN DEFAULT TRUE,
    cam_percentage DECIMAL(5, 4), -- e.g., 0.0523 for 5.23%
    cam_cap DECIMAL(10, 2), -- Maximum CAM amount
    cam_base_year INTEGER,
    pro_rata_share DECIMAL(5, 4),
    
    -- Lease Terms
    lease_type VARCHAR(20) CHECK (lease_type IN (
        'GROSS', 'NET', 'DOUBLE_NET', 'TRIPLE_NET', 'MODIFIED_GROSS'
    )),
    lease_terms JSONB, -- {escalation_rate, escalation_frequency, options}
    renewal_options JSONB DEFAULT '[]'::JSONB, -- [{term_months, notice_required_days}]
    expansion_rights BOOLEAN DEFAULT FALSE,
    first_right_of_refusal BOOLEAN DEFAULT FALSE,
    
    -- Special Provisions
    special_provisions JSONB DEFAULT '[]'::JSONB, -- [{provision, details}]
    tenant_improvements_allowance DECIMAL(12, 2),
    ti_allowance_remaining DECIMAL(12, 2),
    free_rent_months INTEGER DEFAULT 0,
    rent_abatement_details JSONB,
    
    -- Building Access & Rights
    signage_rights BOOLEAN DEFAULT FALSE,
    signage_details JSONB,
    exclusive_use_rights BOOLEAN DEFAULT FALSE,
    exclusive_use_details TEXT,
    roof_rights BOOLEAN DEFAULT FALSE,
    antenna_rights BOOLEAN DEFAULT FALSE,
    
    -- Parking
    parking_allocation INTEGER DEFAULT 0,
    reserved_parking_spaces INTEGER DEFAULT 0,
    parking_spaces_ids JSONB DEFAULT '[]'::JSONB,
    additional_parking_rate DECIMAL(8, 2),
    
    -- Operating Hours
    operating_hours JSONB, -- {monday: {open, close}, ...}
    after_hours_access BOOLEAN DEFAULT TRUE,
    after_hours_hvac_rate DECIMAL(8, 2),
    holiday_access BOOLEAN DEFAULT TRUE,
    
    -- Communication Preferences
    preferred_contact_method VARCHAR(20) DEFAULT 'EMAIL' CHECK (preferred_contact_method IN (
        'EMAIL', 'PHONE', 'PORTAL', 'MAIL'
    )),
    communication_preferences JSONB DEFAULT '{
        "rent_invoices": true,
        "cam_reconciliation": true,
        "maintenance_updates": true,
        "building_announcements": true,
        "lease_renewal_notices": true
    }'::JSONB,
    
    -- Payment Information
    autopay_enabled BOOLEAN DEFAULT FALSE,
    autopay_day INTEGER CHECK (autopay_day BETWEEN 1 AND 28),
    payment_method_id UUID,
    default_payment_method VARCHAR(20) CHECK (default_payment_method IN (
        'ACH', 'WIRE', 'CHECK', 'CREDIT_CARD'
    )),
    billing_address JSONB,
    accounts_payable_email VARCHAR(255),
    purchase_order_required BOOLEAN DEFAULT FALSE,
    
    -- Payment History
    payment_history_score DECIMAL(3, 2),
    on_time_payment_rate DECIMAL(5, 2),
    late_payments_count INTEGER DEFAULT 0,
    total_late_fees_paid DECIMAL(10, 2) DEFAULT 0,
    
    -- Escalation Contacts
    escalation_contacts JSONB DEFAULT '[]'::JSONB, -- [{name, title, phone, email, level}]
    
    -- Compliance
    business_license_number VARCHAR(100),
    business_license_expiry DATE,
    certificate_of_occupancy BOOLEAN DEFAULT FALSE,
    health_permit_required BOOLEAN DEFAULT FALSE,
    health_permit_number VARCHAR(100),
    health_permit_expiry DATE,
    
    -- Tenant Portal
    portal_last_login TIMESTAMP WITH TIME ZONE,
    portal_setup_completed BOOLEAN DEFAULT FALSE,
    document_upload_enabled BOOLEAN DEFAULT TRUE,
    api_access_enabled BOOLEAN DEFAULT FALSE,
    api_key VARCHAR(255),
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id)
);

-- Indexes
CREATE INDEX idx_tenant_commercial_profiles_user_id ON tenant_commercial_profiles(user_id);
CREATE INDEX idx_tenant_commercial_profiles_company ON tenant_commercial_profiles(company_name);
CREATE INDEX idx_tenant_commercial_profiles_tax_id ON tenant_commercial_profiles(tax_id);
CREATE INDEX idx_tenant_commercial_profiles_lease ON tenant_commercial_profiles(current_lease_id);
CREATE INDEX idx_tenant_commercial_profiles_unit ON tenant_commercial_profiles(current_unit_id);
CREATE INDEX idx_tenant_commercial_profiles_property ON tenant_commercial_profiles(current_property_id);
CREATE INDEX idx_tenant_commercial_profiles_tenant_type ON tenant_commercial_profiles(tenant_type);
CREATE INDEX idx_tenant_commercial_profiles_industry ON tenant_commercial_profiles(industry);
CREATE INDEX idx_tenant_commercial_profiles_deleted_at ON tenant_commercial_profiles(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_tenant_commercial_profiles_lease_end ON tenant_commercial_profiles(lease_end_date);
```

---

## 5. Role Permissions

### 5.1 role_permissions Table

Maps roles to specific system capabilities and permissions.

```sql
CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Role Information
    role VARCHAR(30) NOT NULL CHECK (role IN (
        'SUPER_ADMIN', 'INDIVIDUAL_OWNER', 'MANAGED_OWNER', 'INVESTOR',
        'CEO', 'CFO', 'PORTFOLIO_MANAGER', 'PROPERTY_MANAGER', 'PROPERTY_ADMIN',
        'MAINTENANCE_COORDINATOR', 'MAINTENANCE_TECHNICIAN', 'MAINTENANCE_VENDOR',
        'FINANCE_ACCOUNTING', 'TENANT_RESIDENTIAL', 'TENANT_COMMERCIAL'
    )),
    
    -- Permission Details
    permission_code VARCHAR(100) NOT NULL, -- e.g., "users.create", "properties.view"
    permission_name VARCHAR(255) NOT NULL,
    permission_description TEXT,
    
    -- Permission Scope
    module VARCHAR(50) NOT NULL, -- e.g., "users", "properties", "maintenance"
    action VARCHAR(20) NOT NULL CHECK (action IN (
        'CREATE', 'READ', 'UPDATE', 'DELETE', 'APPROVE', 'EXPORT', 'IMPORT', 'MANAGE'
    )),
    
    -- Access Level
    access_level VARCHAR(20) DEFAULT 'FULL' CHECK (access_level IN (
        'NONE', 'OWN', 'TEAM', 'DEPARTMENT', 'ORGANIZATION', 'FULL'
    )),
    
    -- Conditions
    conditions JSONB DEFAULT '{}'::JSONB, -- Additional conditions for permission
    requires_approval BOOLEAN DEFAULT FALSE,
    approval_role VARCHAR(30),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id),
    
    -- Unique constraint
    UNIQUE(role, permission_code)
);

-- Indexes
CREATE INDEX idx_role_permissions_role ON role_permissions(role);
CREATE INDEX idx_role_permissions_module ON role_permissions(module);
CREATE INDEX idx_role_permissions_permission_code ON role_permissions(permission_code);
CREATE INDEX idx_role_permissions_active ON role_permissions(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_role_permissions_deleted_at ON role_permissions(deleted_at) WHERE deleted_at IS NULL;
```

### 5.2 Default Permissions Matrix

```sql
-- Insert default permissions for each role
-- Example: Super Admin permissions
INSERT INTO role_permissions (role, permission_code, permission_name, module, action, access_level) VALUES
-- Super Admin - Full Access
('SUPER_ADMIN', 'system.manage', 'Manage System Configuration', 'system', 'MANAGE', 'FULL'),
('SUPER_ADMIN', 'users.manage', 'Manage All Users', 'users', 'MANAGE', 'FULL'),
('SUPER_ADMIN', 'properties.manage', 'Manage All Properties', 'properties', 'MANAGE', 'FULL'),
('SUPER_ADMIN', 'audit.read', 'View Audit Logs', 'audit', 'READ', 'FULL'),

-- Property Manager permissions
('PROPERTY_MANAGER', 'properties.read', 'View Assigned Properties', 'properties', 'READ', 'TEAM'),
('PROPERTY_MANAGER', 'properties.update', 'Update Assigned Properties', 'properties', 'UPDATE', 'TEAM'),
('PROPERTY_MANAGER', 'tenants.manage', 'Manage Tenants', 'tenants', 'MANAGE', 'TEAM'),
('PROPERTY_MANAGER', 'maintenance.manage', 'Manage Maintenance', 'maintenance', 'MANAGE', 'TEAM'),
('PROPERTY_MANAGER', 'leases.manage', 'Manage Leases', 'leases', 'MANAGE', 'TEAM'),

-- Tenant permissions
('TENANT_RESIDENTIAL', 'portal.access', 'Access Tenant Portal', 'portal', 'READ', 'OWN'),
('TENANT_RESIDENTIAL', 'payments.create', 'Make Payments', 'payments', 'CREATE', 'OWN'),
('TENANT_RESIDENTIAL', 'maintenance.create', 'Submit Maintenance Requests', 'maintenance', 'CREATE', 'OWN'),
('TENANT_RESIDENTIAL', 'lease.read', 'View Own Lease', 'leases', 'READ', 'OWN'),

('TENANT_COMMERCIAL', 'portal.access', 'Access Tenant Portal', 'portal', 'READ', 'OWN'),
('TENANT_COMMERCIAL', 'payments.create', 'Make Payments', 'payments', 'CREATE', 'OWN'),
('TENANT_COMMERCIAL', 'maintenance.create', 'Submit Maintenance Requests', 'maintenance', 'CREATE', 'OWN'),
('TENANT_COMMERCIAL', 'lease.read', 'View Own Lease', 'leases', 'READ', 'OWN'),
('TENANT_COMMERCIAL', 'cam.read', 'View CAM Reconciliation', 'cam', 'READ', 'OWN'),
('TENANT_COMMERCIAL', 'users.manage', 'Manage Authorized Users', 'users', 'MANAGE', 'OWN');
```

---

## 6. Role Hierarchy

### 6.1 role_hierarchy Table

Defines the reporting structure and hierarchy between roles.

```sql
CREATE TABLE role_hierarchy (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Hierarchy Definition
    parent_role VARCHAR(30) NOT NULL CHECK (parent_role IN (
        'SUPER_ADMIN', 'INDIVIDUAL_OWNER', 'MANAGED_OWNER', 'INVESTOR',
        'CEO', 'CFO', 'PORTFOLIO_MANAGER', 'PROPERTY_MANAGER', 'PROPERTY_ADMIN',
        'MAINTENANCE_COORDINATOR', 'MAINTENANCE_TECHNICIAN', 'MAINTENANCE_VENDOR',
        'FINANCE_ACCOUNTING', 'TENANT_RESIDENTIAL', 'TENANT_COMMERCIAL'
    )),
    child_role VARCHAR(30) NOT NULL CHECK (child_role IN (
        'SUPER_ADMIN', 'INDIVIDUAL_OWNER', 'MANAGED_OWNER', 'INVESTOR',
        'CEO', 'CFO', 'PORTFOLIO_MANAGER', 'PROPERTY_MANAGER', 'PROPERTY_ADMIN',
        'MAINTENANCE_COORDINATOR', 'MAINTENANCE_TECHNICIAN', 'MAINTENANCE_VENDOR',
        'FINANCE_ACCOUNTING', 'TENANT_RESIDENTIAL', 'TENANT_COMMERCIAL'
    )),
    
    -- Hierarchy Level
    hierarchy_level INTEGER NOT NULL, -- 1 = Direct report, 2 = Skip level, etc.
    
    -- Relationship Type
    relationship_type VARCHAR(20) DEFAULT 'REPORTS_TO' CHECK (relationship_type IN (
        'REPORTS_TO', 'SUPERVISED_BY', 'DOTTED_LINE', 'FUNCTIONAL'
    )),
    
    -- Permissions Inheritance
    can_view_data BOOLEAN DEFAULT TRUE,
    can_approve_actions BOOLEAN DEFAULT FALSE,
    can_manage_users BOOLEAN DEFAULT FALSE,
    inherits_permissions BOOLEAN DEFAULT FALSE,
    
    -- Organization Scope
    organization_id UUID, -- NULL for global, UUID for org-specific
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id),
    
    -- Constraints
    UNIQUE(parent_role, child_role, organization_id),
    CHECK (parent_role != child_role)
);

-- Indexes
CREATE INDEX idx_role_hierarchy_parent ON role_hierarchy(parent_role);
CREATE INDEX idx_role_hierarchy_child ON role_hierarchy(child_role);
CREATE INDEX idx_role_hierarchy_org ON role_hierarchy(organization_id);
CREATE INDEX idx_role_hierarchy_active ON role_hierarchy(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_role_hierarchy_deleted_at ON role_hierarchy(deleted_at) WHERE deleted_at IS NULL;
```

### 6.2 Default Role Hierarchy

```sql
-- Insert default role hierarchy
INSERT INTO role_hierarchy (parent_role, child_role, hierarchy_level, can_view_data, can_approve_actions, can_manage_users) VALUES
-- Executive Chain
('SUPER_ADMIN', 'CEO', 1, TRUE, TRUE, TRUE),
('SUPER_ADMIN', 'CFO', 1, TRUE, TRUE, TRUE),
('CEO', 'CFO', 1, TRUE, TRUE, FALSE),
('CEO', 'PORTFOLIO_MANAGER', 1, TRUE, TRUE, TRUE),
('CFO', 'FINANCE_ACCOUNTING', 1, TRUE, TRUE, TRUE),

-- Property Management Chain
('PORTFOLIO_MANAGER', 'PROPERTY_MANAGER', 1, TRUE, TRUE, TRUE),
('PROPERTY_MANAGER', 'PROPERTY_ADMIN', 1, TRUE, TRUE, FALSE),

-- Maintenance Chain
('PROPERTY_MANAGER', 'MAINTENANCE_COORDINATOR', 1, TRUE, TRUE, TRUE),
('MAINTENANCE_COORDINATOR', 'MAINTENANCE_TECHNICIAN', 1, TRUE, TRUE, FALSE),
('MAINTENANCE_COORDINATOR', 'MAINTENANCE_VENDOR', 1, TRUE, FALSE, FALSE),

-- Owner/Investor relationships
('INDIVIDUAL_OWNER', 'PROPERTY_MANAGER', 1, TRUE, TRUE, FALSE),
('MANAGED_OWNER', 'PORTFOLIO_MANAGER', 1, TRUE, FALSE, FALSE),
('INVESTOR', 'PORTFOLIO_MANAGER', 1, TRUE, FALSE, FALSE);
```

### 6.3 Role Hierarchy Diagram

```
                    ┌─────────────────┐
                    │   SUPER_ADMIN   │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌───────────────┐ ┌───────────────┐ ┌─────────────────────┐
    │      CEO      │ │      CFO      │ │ INDIVIDUAL_OWNER    │
    └───────┬───────┘ └───────┬───────┘ │ MANAGED_OWNER       │
            │                 │         │ INVESTOR            │
            │                 │         └─────────────────────┘
            │                 │
            ▼                 ▼
    ┌─────────────────┐ ┌─────────────────────┐
    │PORTFOLIO_MANAGER│ │  FINANCE_ACCOUNTING │
    └────────┬────────┘ └─────────────────────┘
             │
             ▼
    ┌─────────────────┐
    │PROPERTY_MANAGER │
    └────────┬────────┘
             │
    ┌────────┼────────┐
    │        │        │
    ▼        ▼        ▼
┌────────┐┌─────────┐┌──────────────────────┐
│PROPERTY││MAINT.   ││MAINTENANCE_COORDINATOR│
│ ADMIN  ││VENDOR   │└──────────┬───────────┘
└────────┘└─────────┘           │
                                ▼
                    ┌───────────────────────┐
                    │MAINTENANCE_TECHNICIAN │
                    └───────────────────────┘

    TENANT_RESIDENTIAL ◄───► TENANT_COMMERCIAL
         (Self-service portal users)
```

---

## 7. Indexes Summary

| Table | Index Name | Columns | Type |
|-------|------------|---------|------|
| super_admin_profiles | idx_super_admin_profiles_user_id | user_id | B-tree |
| owner_profiles | idx_owner_profiles_owner_type | owner_type | B-tree |
| investor_profiles | idx_investor_profiles_investor_type | investor_type | B-tree |
| executive_profiles | idx_executive_profiles_executive_role | executive_role | B-tree |
| portfolio_manager_profiles | idx_portfolio_manager_profiles_portfolios | managed_portfolio_ids | GIN |
| property_manager_profiles | idx_property_manager_profiles_properties | assigned_property_ids | GIN |
| property_admin_profiles | idx_property_admin_profiles_properties | assigned_property_ids | GIN |
| maintenance_coordinator_profiles | idx_maintenance_coordinator_profiles_on_call | is_currently_on_call | B-tree |
| maintenance_technician_profiles | idx_maintenance_technician_profiles_skills | skill_set | GIN |
| maintenance_vendor_profiles | idx_maintenance_vendor_profiles_services | service_categories | GIN |
| finance_profiles | idx_finance_profiles_department | department | B-tree |
| tenant_residential_profiles | idx_tenant_residential_profiles_lease_end | lease_end_date | B-tree |
| tenant_commercial_profiles | idx_tenant_commercial_profiles_industry | industry | B-tree |
| role_permissions | idx_role_permissions_role | role | B-tree |
| role_hierarchy | idx_role_hierarchy_parent | parent_role | B-tree |

---

## 8. Relationships

### 8.1 Profile Table Relationships

| Profile Table | Parent Table | Relationship | Cascade Rule |
|---------------|--------------|--------------|--------------|
| super_admin_profiles | users | 1:1 | CASCADE |
| owner_profiles | users | 1:1 | CASCADE |
| investor_profiles | users | 1:1 | CASCADE |
| executive_profiles | users | 1:1 | CASCADE |
| portfolio_manager_profiles | users | 1:1 | CASCADE |
| property_manager_profiles | users | 1:1 | CASCADE |
| property_admin_profiles | users | 1:1 | CASCADE |
| maintenance_coordinator_profiles | users | 1:1 | CASCADE |
| maintenance_technician_profiles | users | 1:1 | CASCADE |
| maintenance_vendor_profiles | users | 1:1 | CASCADE |
| finance_profiles | users | 1:1 | CASCADE |
| tenant_residential_profiles | users | 1:1 | CASCADE |
| tenant_commercial_profiles | users | 1:1 | CASCADE |

### 8.2 Cross-Profile Relationships

- `executive_profiles.assistant_user_id` → `users.id`
- `executive_profiles.delegate_user_id` → `users.id`
- `portfolio_manager_profiles.reports_to_user_id` → `users.id`
- `property_manager_profiles.reports_to_user_id` → `users.id`
- `property_manager_profiles.backup_manager_id` → `users.id`
- `property_admin_profiles.reports_to_manager_id` → `users.id`
- `maintenance_coordinator_profiles.reports_to_user_id` → `users.id`
- `maintenance_technician_profiles.reports_to_coordinator_id` → `users.id`
- `finance_profiles.reports_to_user_id` → `users.id`

---

**Last Updated:** 2025-12-05  
**Database Version:** PostgreSQL 14+  
**Schema Version:** 1.0

