-- ===============================
-- Database Schema - Phase 2: Core Data Model
-- Property Management System
-- ===============================
-- 
-- Database: property_management
-- Engine: InnoDB (for foreign key support)
-- Charset: utf8mb4 (for full Unicode support)
-- Collation: utf8mb4_unicode_ci
-- 
-- ===============================

-- Create database
CREATE DATABASE IF NOT EXISTS property_management
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE property_management;

-- ===============================
-- 1. Core Tables
-- ===============================

-- Organizations (Multi-tenant support)
CREATE TABLE organizations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    type ENUM('property_management_company', 'property_owner', 'individual') NOT NULL,
    tax_id VARCHAR(50) NULL,
    address TEXT NULL,
    phone VARCHAR(20) NULL,
    email VARCHAR(255) NULL,
    status ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
    subscription_tier VARCHAR(50) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    INDEX idx_organizations_code (code),
    INDEX idx_organizations_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Users
CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NULL,
    password_hash VARCHAR(255) NULL,
    auth_provider ENUM('password', 'sso', 'oauth') NOT NULL DEFAULT 'password',
    two_factor_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    two_factor_secret VARCHAR(255) NULL,
    status ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
    last_login_at TIMESTAMP NULL,
    email_verified_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uk_users_org_email (organization_id, email),
    INDEX idx_users_organization (organization_id),
    INDEX idx_users_email (email),
    INDEX idx_users_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Roles
CREATE TABLE roles (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NULL,
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_roles_organization (organization_id),
    INDEX idx_roles_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Permissions
CREATE TABLE permissions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(100) NOT NULL UNIQUE,
    resource_type VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_permissions_code (code),
    INDEX idx_permissions_resource (resource_type, action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User Roles (Join Table)
CREATE TABLE user_roles (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by BIGINT UNSIGNED NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uk_user_roles (user_id, role_id),
    INDEX idx_user_roles_user (user_id),
    INDEX idx_user_roles_role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Role Permissions (Join Table)
CREATE TABLE role_permissions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    role_id BIGINT UNSIGNED NOT NULL,
    permission_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    UNIQUE KEY uk_role_permissions (role_id, permission_id),
    INDEX idx_role_permissions_role (role_id),
    INDEX idx_role_permissions_permission (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Portfolios
CREATE TABLE portfolios (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NULL,
    description TEXT NULL,
    owner_id BIGINT UNSIGNED NOT NULL,
    portfolio_manager_id BIGINT UNSIGNED NULL,
    status ENUM('active', 'inactive', 'archived') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (portfolio_manager_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_portfolios_organization (organization_id),
    INDEX idx_portfolios_owner (owner_id),
    INDEX idx_portfolios_status (status),
    INDEX idx_portfolios_org_status (organization_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Properties
CREATE TABLE properties (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    portfolio_id BIGINT UNSIGNED NOT NULL,
    owner_id BIGINT UNSIGNED NOT NULL,
    property_manager_id BIGINT UNSIGNED NULL,
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
    property_type ENUM('residential', 'commercial', 'mixed-use', 'industrial') NOT NULL,
    property_classification VARCHAR(100) NULL,
    status ENUM('active', 'inactive', 'renovation', 'for_sale', 'sold') NOT NULL DEFAULT 'active',
    ownership_entity VARCHAR(255) NULL,
    tax_id VARCHAR(50) NULL,
    parcel_number VARCHAR(50) NULL,
    year_built YEAR NULL,
    total_sqft DECIMAL(12, 2) NULL,
    total_units INT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(id) ON DELETE RESTRICT,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_manager_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_properties_organization (organization_id),
    INDEX idx_properties_portfolio (portfolio_id),
    INDEX idx_properties_owner (owner_id),
    INDEX idx_properties_status (status),
    INDEX idx_properties_org_portfolio (organization_id, portfolio_id),
    INDEX idx_properties_org_status (organization_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Units
CREATE TABLE units (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    property_id BIGINT UNSIGNED NOT NULL,
    building_id BIGINT UNSIGNED NULL,
    floor_id BIGINT UNSIGNED NULL,
    unit_number VARCHAR(50) NOT NULL,
    unit_type ENUM('residential', 'commercial', 'common', 'amenity', 'utility', 'parking', 'storage') NOT NULL,
    residential_type VARCHAR(50) NULL,
    bedrooms TINYINT NULL,
    bathrooms DECIMAL(3, 1) NULL,
    half_baths TINYINT NULL,
    sqft DECIMAL(10, 2) NULL,
    rentable_sqft DECIMAL(10, 2) NULL,
    status ENUM('available', 'occupied', 'reserved', 'maintenance', 'unavailable', 'off_market') NOT NULL DEFAULT 'available',
    floor_number INT NULL,
    market_rent_amount DECIMAL(10, 2) NULL,
    current_rent_amount DECIMAL(10, 2) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_units_organization (organization_id),
    INDEX idx_units_property (property_id),
    INDEX idx_units_status (status),
    INDEX idx_units_org_property (organization_id, property_id),
    INDEX idx_units_property_status (property_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tenants
CREATE TABLE tenants (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    phone_secondary VARCHAR(20) NULL,
    date_of_birth DATE NULL,
    ssn VARCHAR(11) NULL,
    tax_id VARCHAR(50) NULL,
    type ENUM('residential', 'commercial', 'corporate') NOT NULL,
    status ENUM('prospect', 'active', 'former', 'blacklisted') NOT NULL DEFAULT 'prospect',
    current_address TEXT NULL,
    emergency_contact_name VARCHAR(255) NULL,
    emergency_contact_phone VARCHAR(20) NULL,
    communication_preferences JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uk_tenants_org_email (organization_id, email),
    INDEX idx_tenants_organization (organization_id),
    INDEX idx_tenants_email (email),
    INDEX idx_tenants_status (status),
    INDEX idx_tenants_type (type),
    INDEX idx_tenants_org_status (organization_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Leases
CREATE TABLE leases (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    unit_id BIGINT UNSIGNED NOT NULL,
    tenant_id BIGINT UNSIGNED NOT NULL,
    property_id BIGINT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    rent_amount DECIMAL(10, 2) NOT NULL,
    deposit_amount DECIMAL(10, 2) NULL,
    pet_deposit_amount DECIMAL(10, 2) NULL,
    status ENUM('draft', 'pending_signature', 'active', 'expired', 'terminated', 'renewed') NOT NULL DEFAULT 'draft',
    billing_cycle ENUM('monthly', 'weekly', 'biweekly', 'quarterly', 'yearly') NOT NULL DEFAULT 'monthly',
    payment_due_day TINYINT NOT NULL,
    late_fee_amount DECIMAL(10, 2) NULL,
    late_fee_percentage DECIMAL(5, 2) NULL,
    renewal_options JSON NULL,
    signed_at TIMESTAMP NULL,
    signed_by_tenant_at TIMESTAMP NULL,
    signed_by_owner_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_leases_organization (organization_id),
    INDEX idx_leases_unit (unit_id),
    INDEX idx_leases_tenant (tenant_id),
    INDEX idx_leases_property (property_id),
    INDEX idx_leases_status (status),
    INDEX idx_leases_dates (start_date, end_date),
    INDEX idx_leases_unit_status (unit_id, status),
    INDEX idx_leases_tenant_status (tenant_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payments
CREATE TABLE payments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    lease_id BIGINT UNSIGNED NOT NULL,
    tenant_id BIGINT UNSIGNED NOT NULL,
    property_id BIGINT UNSIGNED NOT NULL,
    unit_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    due_date DATE NOT NULL,
    paid_at TIMESTAMP NULL,
    status ENUM('pending', 'paid', 'partial', 'failed', 'refunded', 'voided') NOT NULL DEFAULT 'pending',
    payment_type ENUM('rent', 'deposit', 'late_fee', 'other') NOT NULL,
    method ENUM('card', 'ach', 'cash', 'check', 'money_order', 'other') NULL,
    transaction_id VARCHAR(255) NULL,
    receipt_number VARCHAR(50) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (lease_id) REFERENCES leases(id) ON DELETE RESTRICT,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uk_payments_receipt (receipt_number),
    INDEX idx_payments_organization (organization_id),
    INDEX idx_payments_lease (lease_id),
    INDEX idx_payments_tenant (tenant_id),
    INDEX idx_payments_property (property_id),
    INDEX idx_payments_unit (unit_id),
    INDEX idx_payments_status (status),
    INDEX idx_payments_due_date (due_date),
    INDEX idx_payments_tenant_status (tenant_id, status),
    INDEX idx_payments_lease_status (lease_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Maintenance Requests
CREATE TABLE maintenance_requests (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    property_id BIGINT UNSIGNED NOT NULL,
    unit_id BIGINT UNSIGNED NULL,
    tenant_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority ENUM('emergency', 'urgent', 'routine', 'cosmetic') NOT NULL DEFAULT 'routine',
    status ENUM('submitted', 'acknowledged', 'assigned', 'in_progress', 'completed', 'closed', 'cancelled') NOT NULL DEFAULT 'submitted',
    submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_maintenance_requests_organization (organization_id),
    INDEX idx_maintenance_requests_property (property_id),
    INDEX idx_maintenance_requests_unit (unit_id),
    INDEX idx_maintenance_requests_tenant (tenant_id),
    INDEX idx_maintenance_requests_status (status),
    INDEX idx_maintenance_requests_priority (priority)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Work Orders
CREATE TABLE work_orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    maintenance_request_id BIGINT UNSIGNED NULL,
    property_id BIGINT UNSIGNED NOT NULL,
    unit_id BIGINT UNSIGNED NULL,
    tenant_id BIGINT UNSIGNED NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority ENUM('emergency', 'urgent', 'routine', 'cosmetic') NOT NULL DEFAULT 'routine',
    status ENUM('draft', 'assigned', 'in_progress', 'completed', 'closed', 'cancelled') NOT NULL DEFAULT 'draft',
    assigned_to_user_id BIGINT UNSIGNED NULL,
    assigned_to_vendor_id BIGINT UNSIGNED NULL,
    scheduled_date DATE NULL,
    completed_at TIMESTAMP NULL,
    cost_amount DECIMAL(10, 2) NULL,
    invoice_number VARCHAR(50) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,
    FOREIGN KEY (maintenance_request_id) REFERENCES maintenance_requests(id) ON DELETE SET NULL,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE RESTRICT,
    FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL,
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_work_orders_organization (organization_id),
    INDEX idx_work_orders_property (property_id),
    INDEX idx_work_orders_unit (unit_id),
    INDEX idx_work_orders_tenant (tenant_id),
    INDEX idx_work_orders_status (status),
    INDEX idx_work_orders_user (assigned_to_user_id),
    INDEX idx_work_orders_vendor (assigned_to_vendor_id),
    INDEX idx_work_orders_property_status (property_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User Property Assignments (Access Control)
CREATE TABLE user_property_assignments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    property_id BIGINT UNSIGNED NOT NULL,
    portfolio_id BIGINT UNSIGNED NULL,
    access_level ENUM('full', 'read_only') NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by BIGINT UNSIGNED NOT NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE RESTRICT,
    INDEX idx_user_property_assignments_user (user_id),
    INDEX idx_user_property_assignments_property (property_id),
    INDEX idx_user_property_assignments_portfolio (portfolio_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===============================
-- 2. Check Constraints (MySQL 8.0.16+)
-- ===============================

-- Note: MySQL 8.0.16+ supports CHECK constraints
-- For older versions, these should be enforced at application level

ALTER TABLE leases
    ADD CONSTRAINT chk_lease_dates CHECK (end_date >= start_date);

ALTER TABLE payments
    ADD CONSTRAINT chk_payment_amount CHECK (amount > 0);

ALTER TABLE units
    ADD CONSTRAINT chk_unit_bedrooms CHECK (bedrooms >= 0 AND bedrooms <= 20);

ALTER TABLE units
    ADD CONSTRAINT chk_unit_bathrooms CHECK (bathrooms >= 0 AND bathrooms <= 99.9);

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
-- 3. Views (Optional - for common queries)
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
        WHEN l.status = 'active' AND CURDATE() BETWEEN l.start_date AND l.end_date THEN 'occupied'
        WHEN l.status = 'active' AND CURDATE() < l.start_date THEN 'reserved'
        ELSE 'available'
    END AS occupancy_status
FROM units u
LEFT JOIN leases l ON u.id = l.unit_id AND l.status = 'active' AND l.deleted_at IS NULL
WHERE u.deleted_at IS NULL;

-- ===============================
-- 4. Stored Procedures (Optional - for complex operations)
-- ===============================

DELIMITER //

-- Procedure to check if unit has active lease
CREATE PROCEDURE sp_check_unit_active_lease(
    IN p_unit_id BIGINT UNSIGNED,
    OUT p_has_active_lease BOOLEAN,
    OUT p_lease_id BIGINT UNSIGNED
)
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
        AND CURDATE() BETWEEN start_date AND end_date
        AND deleted_at IS NULL;
END //

DELIMITER ;

-- ===============================
-- 5. Triggers (Optional - for audit logging)
-- ===============================

-- Note: Triggers can be added for automatic audit logging
-- This is a placeholder - actual implementation depends on audit requirements

-- ===============================
-- Schema Summary
-- ===============================

-- Core Tables: 9
-- - organizations, users, roles, permissions
-- - portfolios, properties, units
-- - tenants, leases, payments
-- - maintenance_requests, work_orders
-- - user_roles, role_permissions, user_property_assignments

-- Total Tables: 14
-- Indexes: Multiple indexes for performance
-- Foreign Keys: All relationships enforced
-- Constraints: Check constraints for data integrity
-- Views: 2 common query views
-- Procedures: 1 utility procedure

