-- ===============================
-- Database Schema - Phase 2: Core Data Model
-- Property Management System
-- PostgreSQL 15+
-- ===============================
-- 
-- Database: property_management
-- 
-- ===============================

-- Create database (run as superuser)
-- CREATE DATABASE property_management
--     WITH ENCODING 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8';

-- Connect to database
-- \c property_management;

-- ===============================
-- 1. Create Custom Types (ENUMs)
-- ===============================

CREATE TYPE organization_type AS ENUM ('property_management_company', 'property_owner', 'individual');
CREATE TYPE organization_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE auth_provider_type AS ENUM ('password', 'sso', 'oauth');
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE portfolio_status AS ENUM ('active', 'inactive', 'archived');
CREATE TYPE property_type_enum AS ENUM ('residential', 'commercial', 'mixed-use', 'industrial');
CREATE TYPE property_status AS ENUM ('active', 'inactive', 'renovation', 'for_sale', 'sold');
CREATE TYPE unit_type_enum AS ENUM ('residential', 'commercial', 'common', 'amenity', 'utility', 'parking', 'storage');
CREATE TYPE unit_status AS ENUM ('available', 'occupied', 'reserved', 'maintenance', 'unavailable', 'off_market');
CREATE TYPE tenant_type AS ENUM ('residential', 'commercial', 'corporate');
CREATE TYPE tenant_status AS ENUM ('prospect', 'active', 'former', 'blacklisted');
CREATE TYPE lease_status AS ENUM ('draft', 'pending_signature', 'active', 'expired', 'terminated', 'renewed');
CREATE TYPE billing_cycle AS ENUM ('monthly', 'weekly', 'biweekly', 'quarterly', 'yearly');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'partial', 'failed', 'refunded', 'voided');
CREATE TYPE payment_type_enum AS ENUM ('rent', 'deposit', 'late_fee', 'other');
CREATE TYPE payment_method AS ENUM ('card', 'ach', 'cash', 'check', 'money_order', 'other');
CREATE TYPE maintenance_priority AS ENUM ('emergency', 'urgent', 'routine', 'cosmetic');
CREATE TYPE maintenance_request_status AS ENUM ('submitted', 'acknowledged', 'assigned', 'in_progress', 'completed', 'closed', 'cancelled');
CREATE TYPE work_order_status AS ENUM ('draft', 'assigned', 'in_progress', 'completed', 'closed', 'cancelled');
CREATE TYPE access_level AS ENUM ('full', 'read_only');
CREATE TYPE media_type_enum AS ENUM ('image', 'video', 'document', 'other');
CREATE TYPE document_type_enum AS ENUM ('property', 'unit', 'lease', 'tenant', 'work_order', 'maintenance_request', 'payment', 'other');
CREATE TYPE notification_channel AS ENUM ('email', 'sms', 'whatsapp', 'push', 'in_app');
CREATE TYPE notification_status AS ENUM ('pending', 'sent', 'delivered', 'failed', 'read');
CREATE TYPE visit_status AS ENUM ('scheduled', 'completed', 'cancelled', 'postponed');
CREATE TYPE visit_type_enum AS ENUM ('showing', 'inspection', 'maintenance', 'other');
CREATE TYPE leave_type_enum AS ENUM ('vacation', 'sick', 'personal', 'other');
CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
CREATE TYPE interest_level AS ENUM ('low', 'medium', 'high', 'very_high');
CREATE TYPE agreement_type AS ENUM ('lease', 'contract', 'other');
CREATE TYPE canteen_status AS ENUM ('active', 'inactive', 'maintenance');

-- ===============================
-- 2. Core Tables
-- ===============================

-- Organizations (Multi-tenant support)
CREATE TABLE organizations (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    type organization_type NOT NULL,
    tax_id VARCHAR(50) NULL,
    address TEXT NULL,
    phone VARCHAR(20) NULL,
    email VARCHAR(255) NULL,
    status organization_status NOT NULL DEFAULT 'active',
    subscription_tier VARCHAR(50) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_organizations_code ON organizations(code);
CREATE INDEX idx_organizations_status ON organizations(status);

-- Users
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NULL,
    password_hash VARCHAR(255) NULL,
    auth_provider auth_provider_type NOT NULL DEFAULT 'password',
    two_factor_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    two_factor_secret VARCHAR(255) NULL,
    status user_status NOT NULL DEFAULT 'active',
    last_login_at TIMESTAMP NULL,
    email_verified_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE (organization_id, email)
);

CREATE INDEX idx_users_organization ON users(organization_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- Roles
CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NULL,
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_roles_organization ON roles(organization_id);
CREATE INDEX idx_roles_code ON roles(code);

-- Permissions
CREATE TABLE permissions (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(100) NOT NULL UNIQUE,
    resource_type VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_permissions_code ON permissions(code);
CREATE INDEX idx_permissions_resource ON permissions(resource_type, action);

-- User Roles (Join Table)
CREATE TABLE user_roles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by BIGINT NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE (user_id, role_id)
);

CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role_id);

-- Role Permissions (Join Table)
CREATE TABLE role_permissions (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    UNIQUE (role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission ON role_permissions(permission_id);

-- Portfolios
CREATE TABLE portfolios (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NULL,
    description TEXT NULL,
    owner_id BIGINT NOT NULL,
    portfolio_manager_id BIGINT NULL,
    status portfolio_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (portfolio_manager_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_portfolios_organization ON portfolios(organization_id);
CREATE INDEX idx_portfolios_owner ON portfolios(owner_id);
CREATE INDEX idx_portfolios_status ON portfolios(status);
CREATE INDEX idx_portfolios_org_status ON portfolios(organization_id, status);

-- Portfolio Properties (for multi-portfolio assignment)
CREATE TABLE portfolio_properties (
    id BIGSERIAL PRIMARY KEY,
    portfolio_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(id) ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE RESTRICT,
    UNIQUE (portfolio_id, property_id)
);

CREATE INDEX idx_portfolio_properties_portfolio ON portfolio_properties(portfolio_id);
CREATE INDEX idx_portfolio_properties_property ON portfolio_properties(property_id);

-- Properties
CREATE TABLE properties (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    portfolio_id BIGINT NOT NULL,
    owner_id BIGINT NOT NULL,
    property_manager_id BIGINT NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255) NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'USA',
    latitude DECIMAL(10, 8) NULL,
    longitude DECIMAL(11, 8) NULL,
    property_type property_type_enum NOT NULL,
    property_classification VARCHAR(100) NULL,
    status property_status NOT NULL DEFAULT 'active',
    ownership_entity VARCHAR(255) NULL,
    tax_id VARCHAR(50) NULL,
    parcel_number VARCHAR(50) NULL,
    year_built INTEGER NULL,
    total_sqft DECIMAL(12, 2) NULL,
    total_units INTEGER NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(id) ON DELETE RESTRICT,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_manager_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_properties_organization ON properties(organization_id);
CREATE INDEX idx_properties_portfolio ON properties(portfolio_id);
CREATE INDEX idx_properties_owner ON properties(owner_id);
CREATE INDEX idx_properties_status ON properties(status);
CREATE INDEX idx_properties_org_portfolio ON properties(organization_id, portfolio_id);
CREATE INDEX idx_properties_org_status ON properties(organization_id, status);

-- Units
CREATE TABLE units (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    building_id BIGINT NULL,
    floor_id BIGINT NULL,
    unit_number VARCHAR(50) NOT NULL,
    unit_type unit_type_enum NOT NULL,
    residential_type VARCHAR(50) NULL,
    bedrooms SMALLINT NULL,
    bathrooms DECIMAL(3, 1) NULL,
    half_baths SMALLINT NULL,
    sqft DECIMAL(10, 2) NULL,
    rentable_sqft DECIMAL(10, 2) NULL,
    status unit_status NOT NULL DEFAULT 'available',
    floor_number INTEGER NULL,
    market_rent_amount DECIMAL(10, 2) NULL,
    current_rent_amount DECIMAL(10, 2) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_units_organization ON units(organization_id);
CREATE INDEX idx_units_property ON units(property_id);
CREATE INDEX idx_units_status ON units(status);
CREATE INDEX idx_units_org_property ON units(organization_id, property_id);
CREATE INDEX idx_units_property_status ON units(property_id, status);

-- Tenants
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    phone_secondary VARCHAR(20) NULL,
    date_of_birth DATE NULL,
    ssn VARCHAR(11) NULL,
    tax_id VARCHAR(50) NULL,
    type tenant_type NOT NULL,
    status tenant_status NOT NULL DEFAULT 'prospect',
    current_address TEXT NULL,
    emergency_contact_name VARCHAR(255) NULL,
    emergency_contact_phone VARCHAR(20) NULL,
    communication_preferences JSONB NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE (organization_id, email)
);

CREATE INDEX idx_tenants_organization ON tenants(organization_id);
CREATE INDEX idx_tenants_email ON tenants(email);
CREATE INDEX idx_tenants_status ON tenants(status);
CREATE INDEX idx_tenants_type ON tenants(type);
CREATE INDEX idx_tenants_org_status ON tenants(organization_id, status);

-- Tenant Applications
CREATE TABLE tenant_applications (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    unit_id BIGINT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    application_date DATE NOT NULL DEFAULT CURRENT_DATE,
    approved_at TIMESTAMP NULL,
    rejected_at TIMESTAMP NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE CASCADE
);

CREATE INDEX idx_tenant_applications_tenant ON tenant_applications(tenant_id);
CREATE INDEX idx_tenant_applications_unit ON tenant_applications(unit_id);
CREATE INDEX idx_tenant_applications_status ON tenant_applications(status);

-- Tenant Credit Scores
CREATE TABLE tenant_credit_scores (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    score INTEGER NOT NULL,
    provider VARCHAR(100) NOT NULL,
    report_date DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_tenant_credit_scores_tenant ON tenant_credit_scores(tenant_id);
CREATE INDEX idx_tenant_credit_scores_date ON tenant_credit_scores(report_date);

-- Leases
CREATE TABLE leases (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    unit_id BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    rent_amount DECIMAL(10, 2) NOT NULL,
    deposit_amount DECIMAL(10, 2) NULL,
    pet_deposit_amount DECIMAL(10, 2) NULL,
    status lease_status NOT NULL DEFAULT 'draft',
    billing_cycle billing_cycle NOT NULL DEFAULT 'monthly',
    payment_due_day SMALLINT NOT NULL,
    late_fee_amount DECIMAL(10, 2) NULL,
    late_fee_percentage DECIMAL(5, 2) NULL,
    renewal_options JSONB NULL,
    signed_at TIMESTAMP NULL,
    signed_by_tenant_at TIMESTAMP NULL,
    signed_by_owner_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_lease_dates CHECK (end_date >= start_date)
);

CREATE INDEX idx_leases_organization ON leases(organization_id);
CREATE INDEX idx_leases_unit ON leases(unit_id);
CREATE INDEX idx_leases_tenant ON leases(tenant_id);
CREATE INDEX idx_leases_property ON leases(property_id);
CREATE INDEX idx_leases_status ON leases(status);
CREATE INDEX idx_leases_dates ON leases(start_date, end_date);
CREATE INDEX idx_leases_unit_status ON leases(unit_id, status);
CREATE INDEX idx_leases_tenant_status ON leases(tenant_id, status);

-- Lease Amendments
CREATE TABLE lease_amendments (
    id BIGSERIAL PRIMARY KEY,
    lease_id BIGINT NOT NULL,
    amendment_type VARCHAR(50) NOT NULL,
    effective_date DATE NOT NULL,
    changes JSONB NOT NULL,
    signed_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lease_id) REFERENCES leases(id) ON DELETE CASCADE
);

CREATE INDEX idx_lease_amendments_lease ON lease_amendments(lease_id);
CREATE INDEX idx_lease_amendments_effective_date ON lease_amendments(effective_date);

-- Payments
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    lease_id BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    unit_id BIGINT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    due_date DATE NOT NULL,
    paid_at TIMESTAMP NULL,
    status payment_status NOT NULL DEFAULT 'pending',
    payment_type payment_type_enum NOT NULL,
    method payment_method NULL,
    transaction_id VARCHAR(255) NULL,
    receipt_number VARCHAR(50) NULL UNIQUE,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (lease_id) REFERENCES leases(id) ON DELETE RESTRICT,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_payment_amount CHECK (amount > 0)
);

CREATE INDEX idx_payments_organization ON payments(organization_id);
CREATE INDEX idx_payments_lease ON payments(lease_id);
CREATE INDEX idx_payments_tenant ON payments(tenant_id);
CREATE INDEX idx_payments_property ON payments(property_id);
CREATE INDEX idx_payments_unit ON payments(unit_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_due_date ON payments(due_date);
CREATE INDEX idx_payments_tenant_status ON payments(tenant_id, status);
CREATE INDEX idx_payments_lease_status ON payments(lease_id, status);

-- Payment Schedules
CREATE TABLE payment_schedules (
    id BIGSERIAL PRIMARY KEY,
    lease_id BIGINT NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lease_id) REFERENCES leases(id) ON DELETE CASCADE
);

CREATE INDEX idx_payment_schedules_lease ON payment_schedules(lease_id);
CREATE INDEX idx_payment_schedules_date ON payment_schedules(payment_date);
CREATE INDEX idx_payment_schedules_status ON payment_schedules(status);

-- Late Fees
CREATE TABLE late_fees (
    id BIGSERIAL PRIMARY KEY,
    payment_id BIGINT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    calculated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    applied_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
);

CREATE INDEX idx_late_fees_payment ON late_fees(payment_id);
CREATE INDEX idx_late_fees_calculated_at ON late_fees(calculated_at);

-- Invoices
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    lease_id BIGINT NULL,
    tenant_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    unit_id BIGINT NULL,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) NULL DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    paid_at TIMESTAMP NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (lease_id) REFERENCES leases(id) ON DELETE SET NULL,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_invoices_organization ON invoices(organization_id);
CREATE INDEX idx_invoices_lease ON invoices(lease_id);
CREATE INDEX idx_invoices_tenant ON invoices(tenant_id);
CREATE INDEX idx_invoices_property ON invoices(property_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);

-- Maintenance Requests
CREATE TABLE maintenance_requests (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    unit_id BIGINT NULL,
    tenant_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority maintenance_priority NOT NULL DEFAULT 'routine',
    status maintenance_request_status NOT NULL DEFAULT 'submitted',
    submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_maintenance_requests_organization ON maintenance_requests(organization_id);
CREATE INDEX idx_maintenance_requests_property ON maintenance_requests(property_id);
CREATE INDEX idx_maintenance_requests_unit ON maintenance_requests(unit_id);
CREATE INDEX idx_maintenance_requests_tenant ON maintenance_requests(tenant_id);
CREATE INDEX idx_maintenance_requests_status ON maintenance_requests(status);
CREATE INDEX idx_maintenance_requests_priority ON maintenance_requests(priority);
CREATE INDEX idx_maintenance_requests_org_status_created ON maintenance_requests(organization_id, status, created_at DESC);

-- Maintenance Request Feedback
CREATE TABLE maintenance_request_feedback (
    id BIGSERIAL PRIMARY KEY,
    maintenance_request_id BIGINT NOT NULL,
    tenant_id BIGINT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comments TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (maintenance_request_id) REFERENCES maintenance_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_maintenance_request_feedback_request ON maintenance_request_feedback(maintenance_request_id);
CREATE INDEX idx_maintenance_request_feedback_tenant ON maintenance_request_feedback(tenant_id);

-- Work Orders
CREATE TABLE work_orders (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    maintenance_request_id BIGINT NULL,
    property_id BIGINT NOT NULL,
    unit_id BIGINT NULL,
    tenant_id BIGINT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority maintenance_priority NOT NULL DEFAULT 'routine',
    status work_order_status NOT NULL DEFAULT 'draft',
    assigned_to_user_id BIGINT NULL,
    assigned_to_vendor_id BIGINT NULL,
    scheduled_date DATE NULL,
    completed_at TIMESTAMP NULL,
    cost_amount DECIMAL(10, 2) NULL,
    invoice_number VARCHAR(50) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (maintenance_request_id) REFERENCES maintenance_requests(id) ON DELETE SET NULL,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_work_orders_organization ON work_orders(organization_id);
CREATE INDEX idx_work_orders_property ON work_orders(property_id);
CREATE INDEX idx_work_orders_unit ON work_orders(unit_id);
CREATE INDEX idx_work_orders_tenant ON work_orders(tenant_id);
CREATE INDEX idx_work_orders_status ON work_orders(status);
CREATE INDEX idx_work_orders_user ON work_orders(assigned_to_user_id);
CREATE INDEX idx_work_orders_vendor ON work_orders(assigned_to_vendor_id);
CREATE INDEX idx_work_orders_property_status ON work_orders(property_id, status);

-- Work Order Approvals
CREATE TABLE work_order_approvals (
    id BIGSERIAL PRIMARY KEY,
    work_order_id BIGINT NOT NULL,
    approver_id BIGINT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    comments TEXT NULL,
    approved_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (approver_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_work_order_approvals_work_order ON work_order_approvals(work_order_id);
CREATE INDEX idx_work_order_approvals_approver ON work_order_approvals(approver_id);
CREATE INDEX idx_work_order_approvals_status ON work_order_approvals(status);

-- User Property Assignments (Access Control)
CREATE TABLE user_property_assignments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    portfolio_id BIGINT NULL,
    access_level access_level NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by BIGINT NOT NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_user_property_assignments_user ON user_property_assignments(user_id);
CREATE INDEX idx_user_property_assignments_property ON user_property_assignments(property_id);
CREATE INDEX idx_user_property_assignments_portfolio ON user_property_assignments(portfolio_id);

-- Documents
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(1000) NOT NULL,
    file_size BIGINT NULL,
    mime_type VARCHAR(100) NULL,
    document_type document_type_enum NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,
    category VARCHAR(100) NULL,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMP NULL,
    uploaded_by BIGINT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_documents_organization ON documents(organization_id);
CREATE INDEX idx_documents_entity ON documents(entity_type, entity_id);
CREATE INDEX idx_documents_type ON documents(document_type);
CREATE INDEX idx_documents_category ON documents(category);

-- Document Versions
CREATE TABLE document_versions (
    id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    version_number INTEGER NOT NULL,
    file_path VARCHAR(1000) NOT NULL,
    changes TEXT NULL,
    created_by BIGINT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE (document_id, version_number)
);

CREATE INDEX idx_document_versions_document ON document_versions(document_id);

-- Document Shares
CREATE TABLE document_shares (
    id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL,
    share_token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NULL,
    access_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
);

CREATE INDEX idx_document_shares_document ON document_shares(document_id);
CREATE INDEX idx_document_shares_token ON document_shares(share_token);

-- Entity Media (Highly customizable image/media ordering and thumbnail management)
CREATE TABLE entity_media (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,
    document_id BIGINT NULL,
    file_name VARCHAR(255) NULL,
    file_path VARCHAR(500) NULL,
    file_url VARCHAR(1000) NULL,
    file_size BIGINT NULL,
    mime_type VARCHAR(100) NULL,
    media_type media_type_enum NOT NULL DEFAULT 'image',
    title VARCHAR(255) NULL,
    description TEXT NULL,
    alt_text VARCHAR(500) NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_thumbnail BOOLEAN NOT NULL DEFAULT FALSE,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    gallery_name VARCHAR(100) NULL,
    gallery_order INTEGER NULL,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB NULL,
    uploaded_by BIGINT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NULL,
    updated_by BIGINT NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE SET NULL,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_entity_media_display_order CHECK (display_order >= 0),
    CONSTRAINT chk_entity_media_gallery_order CHECK (
        (gallery_name IS NULL AND gallery_order IS NULL) OR
        (gallery_name IS NOT NULL AND gallery_order IS NOT NULL AND gallery_order >= 0)
    )
);

CREATE INDEX idx_entity_media_organization ON entity_media(organization_id);
CREATE INDEX idx_entity_media_entity ON entity_media(entity_type, entity_id);
CREATE INDEX idx_entity_media_document ON entity_media(document_id);
CREATE INDEX idx_entity_media_display_order ON entity_media(entity_type, entity_id, display_order);
CREATE INDEX idx_entity_media_thumbnail ON entity_media(entity_type, entity_id, is_thumbnail);
CREATE INDEX idx_entity_media_gallery ON entity_media(entity_type, entity_id, gallery_name, gallery_order);
CREATE INDEX idx_entity_media_active ON entity_media(is_active, deleted_at);
CREATE INDEX idx_entity_media_org_entity ON entity_media(organization_id, entity_type, entity_id);

-- Messages
CREATE TABLE messages (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    recipient_id BIGINT NOT NULL,
    recipient_type VARCHAR(50) NOT NULL,
    subject VARCHAR(255) NULL,
    body TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'sent',
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_messages_organization ON messages(organization_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_recipient ON messages(recipient_id, recipient_type);
CREATE INDEX idx_messages_status ON messages(status);

-- Message Attachments
CREATE TABLE message_attachments (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT NOT NULL,
    document_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
);

CREATE INDEX idx_message_attachments_message ON message_attachments(message_id);
CREATE INDEX idx_message_attachments_document ON message_attachments(document_id);

-- Notifications
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    user_id BIGINT NULL,
    tenant_id BIGINT NULL,
    type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    channel notification_channel NOT NULL,
    status notification_status NOT NULL DEFAULT 'pending',
    sent_at TIMESTAMP NULL,
    read_at TIMESTAMP NULL,
    metadata JSONB NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_organization ON notifications(organization_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_tenant ON notifications(tenant_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_channel ON notifications(channel);

-- Notification Preferences
CREATE TABLE notification_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NULL,
    tenant_id BIGINT NULL,
    notification_type VARCHAR(100) NOT NULL,
    channel notification_channel NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    UNIQUE (COALESCE(user_id, -1), COALESCE(tenant_id, -1), notification_type, channel)
);

CREATE INDEX idx_notification_preferences_user ON notification_preferences(user_id);
CREATE INDEX idx_notification_preferences_tenant ON notification_preferences(tenant_id);

-- Email Templates
CREATE TABLE email_templates (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    subject VARCHAR(500) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT
);

CREATE INDEX idx_email_templates_organization ON email_templates(organization_id);
CREATE INDEX idx_email_templates_type ON email_templates(type);

-- Tenant Portal Sessions
CREATE TABLE tenant_portal_sessions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_tenant_portal_sessions_tenant ON tenant_portal_sessions(tenant_id);
CREATE INDEX idx_tenant_portal_sessions_token ON tenant_portal_sessions(token);
CREATE INDEX idx_tenant_portal_sessions_expires ON tenant_portal_sessions(expires_at);

-- Report Templates
CREATE TABLE report_templates (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100) NOT NULL,
    configuration JSONB NOT NULL,
    created_by BIGINT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_report_templates_organization ON report_templates(organization_id);
CREATE INDEX idx_report_templates_type ON report_templates(type);

-- Saved Reports
CREATE TABLE saved_reports (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    template_id BIGINT NULL,
    filters JSONB NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES report_templates(id) ON DELETE SET NULL
);

CREATE INDEX idx_saved_reports_organization ON saved_reports(organization_id);
CREATE INDEX idx_saved_reports_user ON saved_reports(user_id);

-- Scheduled Reports
CREATE TABLE scheduled_reports (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    report_template_id BIGINT NOT NULL,
    schedule JSONB NOT NULL,
    recipients JSONB NOT NULL,
    last_run_at TIMESTAMP NULL,
    next_run_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (report_template_id) REFERENCES report_templates(id) ON DELETE CASCADE
);

CREATE INDEX idx_scheduled_reports_organization ON scheduled_reports(organization_id);
CREATE INDEX idx_scheduled_reports_template ON scheduled_reports(report_template_id);
CREATE INDEX idx_scheduled_reports_next_run ON scheduled_reports(next_run_at);

-- Dashboards
CREATE TABLE dashboards (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    widgets JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_dashboards_organization ON dashboards(organization_id);
CREATE INDEX idx_dashboards_user ON dashboards(user_id);

-- Audit Logs
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    user_id BIGINT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,
    changes JSONB NULL,
    before_state JSONB NULL,
    after_state JSONB NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_audit_logs_organization ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_org_entity_created ON audit_logs(organization_id, entity_type, created_at DESC);

-- Sales Reps
CREATE TABLE sales_reps (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    UNIQUE (organization_id, user_id)
);

CREATE INDEX idx_sales_reps_organization ON sales_reps(organization_id);
CREATE INDEX idx_sales_reps_user ON sales_reps(user_id);
CREATE INDEX idx_sales_reps_status ON sales_reps(status);

-- Sales Rep Leave
CREATE TABLE sales_rep_leave (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    sales_rep_id BIGINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    leave_type leave_type_enum NOT NULL,
    status leave_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (sales_rep_id) REFERENCES sales_reps(id) ON DELETE CASCADE,
    CONSTRAINT chk_leave_dates CHECK (end_date >= start_date)
);

CREATE INDEX idx_sales_rep_leave_organization ON sales_rep_leave(organization_id);
CREATE INDEX idx_sales_rep_leave_sales_rep ON sales_rep_leave(sales_rep_id);
CREATE INDEX idx_sales_rep_leave_dates ON sales_rep_leave(start_date, end_date);

-- Clients (for sales/visits - can be separate from tenants)
CREATE TABLE clients (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NULL,
    phone VARCHAR(20) NULL,
    company_name VARCHAR(255) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT
);

CREATE INDEX idx_clients_organization ON clients(organization_id);
CREATE INDEX idx_clients_email ON clients(email);

-- Property Visits
CREATE TABLE property_visits (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    unit_id BIGINT NULL,
    sales_rep_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    scheduled_date DATE NOT NULL,
    scheduled_time TIME NOT NULL,
    status visit_status NOT NULL DEFAULT 'scheduled',
    visit_type visit_type_enum NOT NULL DEFAULT 'showing',
    notes TEXT NULL,
    outcome TEXT NULL,
    feedback TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL,
    FOREIGN KEY (sales_rep_id) REFERENCES sales_reps(id) ON DELETE RESTRICT,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT
);

CREATE INDEX idx_property_visits_organization ON property_visits(organization_id);
CREATE INDEX idx_property_visits_property ON property_visits(property_id);
CREATE INDEX idx_property_visits_sales_rep ON property_visits(sales_rep_id);
CREATE INDEX idx_property_visits_client ON property_visits(client_id);
CREATE INDEX idx_property_visits_scheduled_date ON property_visits(scheduled_date);
CREATE INDEX idx_property_visits_status ON property_visits(status);

-- Client Property Interest
CREATE TABLE client_property_interest (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    interest_level interest_level NOT NULL DEFAULT 'medium',
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    UNIQUE (client_id, property_id)
);

CREATE INDEX idx_client_property_interest_organization ON client_property_interest(organization_id);
CREATE INDEX idx_client_property_interest_client ON client_property_interest(client_id);
CREATE INDEX idx_client_property_interest_property ON client_property_interest(property_id);

-- Canteens
CREATE TABLE canteens (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    capacity INTEGER NULL,
    status canteen_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT
);

CREATE INDEX idx_canteens_organization ON canteens(organization_id);
CREATE INDEX idx_canteens_property ON canteens(property_id);

-- Canteen Agreements
CREATE TABLE canteen_agreements (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL,
    canteen_id BIGINT NOT NULL,
    client_id BIGINT NULL,
    tenant_id BIGINT NULL,
    agreement_type agreement_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    fee_amount DECIMAL(10, 2) NULL,
    terms TEXT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (canteen_id) REFERENCES canteens(id) ON DELETE RESTRICT,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE SET NULL,
    CONSTRAINT chk_canteen_agreement_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_canteen_agreements_organization ON canteen_agreements(organization_id);
CREATE INDEX idx_canteen_agreements_canteen ON canteen_agreements(canteen_id);
CREATE INDEX idx_canteen_agreements_client ON canteen_agreements(client_id);
CREATE INDEX idx_canteen_agreements_tenant ON canteen_agreements(tenant_id);

-- System Settings
CREATE TABLE system_settings (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NULL,
    key VARCHAR(255) NOT NULL,
    value TEXT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    UNIQUE (COALESCE(organization_id, -1), key)
);

CREATE INDEX idx_system_settings_organization ON system_settings(organization_id);
CREATE INDEX idx_system_settings_key ON system_settings(key);

-- Feature Flags
CREATE TABLE feature_flags (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NULL,
    feature_name VARCHAR(255) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    rollout_percentage INTEGER NOT NULL DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    UNIQUE (COALESCE(organization_id, -1), feature_name)
);

CREATE INDEX idx_feature_flags_organization ON feature_flags(organization_id);
CREATE INDEX idx_feature_flags_feature_name ON feature_flags(feature_name);

-- ===============================
-- 3. Check Constraints
-- ===============================

ALTER TABLE units
    ADD CONSTRAINT chk_unit_bedrooms CHECK (bedrooms IS NULL OR (bedrooms >= 0 AND bedrooms <= 20));

ALTER TABLE units
    ADD CONSTRAINT chk_unit_bathrooms CHECK (bathrooms IS NULL OR (bathrooms >= 0 AND bathrooms <= 99.9));

ALTER TABLE properties
    ADD CONSTRAINT chk_property_latitude CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90));

ALTER TABLE properties
    ADD CONSTRAINT chk_property_longitude CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180));

ALTER TABLE leases
    ADD CONSTRAINT chk_lease_payment_due_day CHECK (
        (billing_cycle = 'monthly' AND payment_due_day >= 1 AND payment_due_day <= 31) OR
        (billing_cycle = 'weekly' AND payment_due_day >= 1 AND payment_due_day <= 7) OR
        (billing_cycle IN ('biweekly', 'quarterly', 'yearly'))
    );

-- ===============================
-- 4. Views (for common queries)
-- ===============================

-- Active Leases View
CREATE OR REPLACE VIEW v_active_leases AS
SELECT 
    l.id,
    l.organization_id,
    l.unit_id,
    l.tenant_id,
    l.property_id,
    l.start_date,
    l.end_date,
    l.rent_amount,
    l.status,
    u.unit_number,
    u.property_id AS unit_property_id,
    t.full_name AS tenant_name,
    t.email AS tenant_email,
    p.name AS property_name
FROM leases l
INNER JOIN units u ON l.unit_id = u.id
INNER JOIN tenants t ON l.tenant_id = t.id
INNER JOIN properties p ON l.property_id = p.id
WHERE l.status = 'active'
    AND l.deleted_at IS NULL
    AND u.deleted_at IS NULL
    AND t.deleted_at IS NULL
    AND p.deleted_at IS NULL;

-- Unit Occupancy View
CREATE OR REPLACE VIEW v_unit_occupancy AS
SELECT 
    u.id AS unit_id,
    u.unit_number,
    u.property_id,
    u.status AS unit_status,
    l.id AS lease_id,
    l.tenant_id,
    l.status AS lease_status,
    l.start_date,
    l.end_date,
    CASE 
        WHEN l.status = 'active' AND CURRENT_DATE BETWEEN l.start_date AND l.end_date THEN 'occupied'
        WHEN l.status = 'active' AND CURRENT_DATE < l.start_date THEN 'reserved'
        ELSE 'available'
    END AS occupancy_status
FROM units u
LEFT JOIN leases l ON u.id = l.unit_id AND l.status = 'active' AND l.deleted_at IS NULL
WHERE u.deleted_at IS NULL;

-- ===============================
-- 5. Functions (for complex operations)
-- ===============================

-- Function to check if unit has active lease
CREATE OR REPLACE FUNCTION sp_check_unit_active_lease(
    p_unit_id BIGINT,
    OUT p_has_active_lease BOOLEAN,
    OUT p_lease_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT 
        COUNT(*) > 0,
        COALESCE(MAX(id), 0)
    INTO 
        p_has_active_lease,
        p_lease_id
    FROM leases
    WHERE unit_id = p_unit_id
        AND status = 'active'
        AND CURRENT_DATE BETWEEN start_date AND end_date
        AND deleted_at IS NULL;
END;
$$;

-- ===============================
-- 6. Triggers (for updated_at timestamps)
-- ===============================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all tables with updated_at column
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_permissions_updated_at BEFORE UPDATE ON permissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_portfolios_updated_at BEFORE UPDATE ON portfolios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_properties_updated_at BEFORE UPDATE ON properties
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_units_updated_at BEFORE UPDATE ON units
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leases_updated_at BEFORE UPDATE ON leases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_requests_updated_at BEFORE UPDATE ON maintenance_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_work_orders_updated_at BEFORE UPDATE ON work_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_property_assignments_updated_at BEFORE UPDATE ON user_property_assignments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_entity_media_updated_at BEFORE UPDATE ON entity_media
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_preferences_updated_at BEFORE UPDATE ON notification_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_email_templates_updated_at BEFORE UPDATE ON email_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_report_templates_updated_at BEFORE UPDATE ON report_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dashboards_updated_at BEFORE UPDATE ON dashboards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_reps_updated_at BEFORE UPDATE ON sales_reps
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_rep_leave_updated_at BEFORE UPDATE ON sales_rep_leave
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_property_visits_updated_at BEFORE UPDATE ON property_visits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_client_property_interest_updated_at BEFORE UPDATE ON client_property_interest
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_canteens_updated_at BEFORE UPDATE ON canteens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_canteen_agreements_updated_at BEFORE UPDATE ON canteen_agreements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feature_flags_updated_at BEFORE UPDATE ON feature_flags
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================
-- Schema Summary
-- ===============================

-- Core Tables: 15
-- - organizations, users, roles, permissions
-- - portfolios, portfolio_properties, properties, units
-- - tenants, tenant_applications, tenant_credit_scores
-- - leases, lease_amendments
-- - payments, payment_schedules, late_fees, invoices
-- - maintenance_requests, maintenance_request_feedback
-- - work_orders, work_order_approvals
-- - user_roles, role_permissions, user_property_assignments
-- - documents, document_versions, document_shares
-- - entity_media
-- - messages, message_attachments
-- - notifications, notification_preferences
-- - email_templates
-- - tenant_portal_sessions
-- - report_templates, saved_reports, scheduled_reports
-- - dashboards
-- - audit_logs
-- - sales_reps, sales_rep_leave
-- - clients, property_visits, client_property_interest
-- - canteens, canteen_agreements
-- - system_settings, feature_flags

-- Total Tables: 40+
-- Indexes: Multiple indexes for performance
-- Foreign Keys: All relationships enforced
-- Constraints: Check constraints for data integrity
-- Views: 2 common query views
-- Functions: 1 utility function
-- Triggers: Automatic updated_at timestamp updates
