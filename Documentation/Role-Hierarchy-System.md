# Role Hierarchy System

## Overview

The role hierarchy system provides a configurable mechanism to enforce hierarchical relationships between user roles, ensuring proper oversight and reporting structures. The system is designed to be flexible and can be enabled or disabled per organization.

## Database Schema

### role_hierarchy_config Table

Stores the configuration for role hierarchy relationships:

- `organization_id`: NULL for global config, UUID for organization-specific config
- `parent_role`: The superior role (MANAGER, ASSISTANT_MANAGER, OWNER, SUPER_ADMIN)
- `child_role`: The subordinate role (SALES_REP, ASSISTANT_MANAGER, MANAGER, BROKER)
- `is_enabled`: Whether this hierarchy rule is active
- `requires_approval`: Whether actions by child role require parent approval

### user_role_hierarchy Table

Stores actual hierarchical relationships between specific users:

- `parent_user_id`: The user in the parent role
- `child_user_id`: The user in the child role
- `hierarchy_config_id`: Reference to the configuration that enabled this relationship
- `is_active`: Whether this relationship is currently active

## Default Hierarchy Rules

### Mandatory Hierarchy

**If Manager role exists, Sales Rep must be overseen by Manager:**

```sql
-- Default configuration
INSERT INTO role_hierarchy_config (
  organization_id, 
  parent_role, 
  child_role, 
  is_enabled, 
  requires_approval
) VALUES (
  NULL, -- Global default
  'MANAGER',
  'SALES_REP',
  TRUE,
  FALSE -- Can be set to TRUE if approval required
);
```

### Standard Hierarchy Structure

```
OWNER
  └── MANAGER
      ├── ASSISTANT_MANAGER
      └── SALES_REP
          └── CLIENT (via bookings/visits)
```

### Hierarchy Rules

1. **Manager → Sales Rep**: Sales Rep must report to Manager when Manager exists
2. **Manager → Assistant Manager**: Assistant Manager reports to Manager
3. **Owner → Manager**: Manager reports to Owner
4. **Sales Rep → Client**: Sales Rep manages client relationships (not enforced in hierarchy table, but in business logic)

## Implementation

### Enforcing Hierarchy on User Creation

```typescript
async function createSalesRep(userData: CreateUserDto): Promise<User> {
  // Check if Manager role exists in the organization
  const hasManager = await this.userRepository.exists({
    role: 'MANAGER',
    organization_id: userData.organization_id
  });
  
  if (hasManager) {
    // Check if hierarchy is enabled
    const hierarchyConfig = await this.hierarchyConfigRepository.findOne({
      where: {
        organization_id: userData.organization_id,
        parent_role: 'MANAGER',
        child_role: 'SALES_REP',
        is_enabled: true
      }
    });
    
    if (hierarchyConfig) {
      // Sales Rep must be assigned to a Manager
      if (!userData.manager_id) {
        throw new ValidationError(
          'Sales Rep must be assigned to a Manager when Manager role exists'
        );
      }
      
      // Create user
      const salesRep = await this.userRepository.create(userData);
      
      // Create hierarchy relationship
      await this.userRoleHierarchyRepository.create({
        parent_user_id: userData.manager_id,
        child_user_id: salesRep.id,
        hierarchy_config_id: hierarchyConfig.id,
        is_active: true
      });
      
      return salesRep;
    }
  }
  
  // If no Manager or hierarchy disabled, create without hierarchy
  return await this.userRepository.create(userData);
}
```

### Checking Hierarchy Permissions

```typescript
async function canSalesRepAccessResource(
  salesRepId: UUID,
  resourceId: UUID
): Promise<boolean> {
  // Get the Manager overseeing this Sales Rep
  const hierarchy = await this.userRoleHierarchyRepository.findOne({
    where: {
      child_user_id: salesRepId,
      is_active: true
    },
    relations: ['parent_user', 'hierarchy_config']
  });
  
  if (!hierarchy) {
    // No hierarchy enforced, allow access
    return true;
  }
  
  // Check if hierarchy requires approval
  if (hierarchy.hierarchy_config.requires_approval) {
    // Check if Manager has approved this action
    const approval = await this.getApproval(salesRepId, resourceId);
    return approval?.approved === true;
  }
  
  // Hierarchy exists but no approval required
  return true;
}
```

### Querying Subordinates

```typescript
async function getManagerSubordinates(managerId: UUID): Promise<User[]> {
  const hierarchies = await this.userRoleHierarchyRepository.find({
    where: {
      parent_user_id: managerId,
      is_active: true
    },
    relations: ['child_user']
  });
  
  return hierarchies.map(h => h.child_user);
}

async function getSalesRepsUnderManager(managerId: UUID): Promise<User[]> {
  const hierarchies = await this.userRoleHierarchyRepository.find({
    where: {
      parent_user_id: managerId,
      is_active: true
    },
    relations: ['child_user', 'hierarchy_config']
  });
  
  return hierarchies
    .filter(h => h.hierarchy_config.child_role === 'SALES_REP')
    .map(h => h.child_user);
}
```

## Configuration Management

### Enabling/Disabling Hierarchy

```typescript
async function toggleHierarchy(
  organizationId: UUID | null,
  parentRole: string,
  childRole: string,
  enabled: boolean
): Promise<RoleHierarchyConfig> {
  const config = await this.hierarchyConfigRepository.findOne({
    where: {
      organization_id: organizationId,
      parent_role: parentRole,
      child_role: childRole
    }
  });
  
  if (!config) {
    // Create new configuration
    return await this.hierarchyConfigRepository.create({
      organization_id: organizationId,
      parent_role: parentRole,
      child_role: childRole,
      is_enabled: enabled
    });
  }
  
  // Update existing configuration
  config.is_enabled = enabled;
  return await this.hierarchyConfigRepository.save(config);
}
```

### Organization-Specific Overrides

Organizations can override global hierarchy settings:

```typescript
// Global default: Manager oversees Sales Rep
await toggleHierarchy(null, 'MANAGER', 'SALES_REP', true);

// Organization A: Disable hierarchy
await toggleHierarchy(orgAId, 'MANAGER', 'SALES_REP', false);

// Organization B: Enable with approval required
const config = await toggleHierarchy(orgBId, 'MANAGER', 'SALES_REP', true);
config.requires_approval = true;
await this.hierarchyConfigRepository.save(config);
```

## API Endpoints

### Hierarchy Configuration

```typescript
// Get hierarchy configuration
GET /api/v1/admin/role-hierarchy/config?organization_id=:orgId

// Update hierarchy configuration
PUT /api/v1/admin/role-hierarchy/config/:id
{
  "is_enabled": true,
  "requires_approval": false
}

// Create hierarchy relationship
POST /api/v1/admin/role-hierarchy/relationships
{
  "parent_user_id": "uuid",
  "child_user_id": "uuid",
  "hierarchy_config_id": "uuid"
}
```

### Hierarchy Queries

```typescript
// Get subordinates of a user
GET /api/v1/users/:userId/subordinates

// Get manager of a user
GET /api/v1/users/:userId/manager

// Get all Sales Reps under a Manager
GET /api/v1/managers/:managerId/sales-reps
```

## Business Logic Integration

### Private Visit Booking

When a Sales Rep books a visit, the system checks hierarchy:

```typescript
async function bookVisitAsSalesRep(
  salesRepId: UUID,
  visitData: CreateVisitDto
): Promise<PrivateVisit> {
  // Check if Sales Rep is under a Manager
  const hierarchy = await this.getActiveHierarchy(salesRepId);
  
  if (hierarchy && hierarchy.hierarchy_config.requires_approval) {
    // Create visit in PENDING_APPROVAL status
    visitData.status = 'PENDING_APPROVAL';
    visitData.requires_manager_approval = true;
    visitData.manager_id = hierarchy.parent_user_id;
  }
  
  return await this.createVisit(visitData);
}
```

### Reporting and Analytics

Managers can view reports for their subordinates:

```typescript
async function getManagerDashboard(managerId: UUID): Promise<DashboardData> {
  const subordinates = await this.getManagerSubordinates(managerId);
  const subordinateIds = subordinates.map(u => u.id);
  
  return {
    total_visits: await this.visitRepository.count({
      sales_rep_id: In(subordinateIds)
    }),
    total_bids: await this.bidRepository.count({
      created_by: In(subordinateIds)
    }),
    revenue: await this.calculateRevenue(subordinateIds),
    subordinates: subordinates
  };
}
```

## Audit and Compliance

All hierarchy changes are logged:

- User assignment to hierarchy
- Hierarchy configuration changes
- Approval actions (if requires_approval is enabled)
- Hierarchy-enabled actions (visits, bids, etc.)

## Migration and Setup

### Initial Setup

```sql
-- Create default global hierarchy configuration
INSERT INTO role_hierarchy_config (
  organization_id,
  parent_role,
  child_role,
  is_enabled,
  requires_approval,
  created_at,
  updated_at
) VALUES
  (NULL, 'MANAGER', 'SALES_REP', TRUE, FALSE, NOW(), NOW()),
  (NULL, 'MANAGER', 'ASSISTANT_MANAGER', TRUE, FALSE, NOW(), NOW()),
  (NULL, 'OWNER', 'MANAGER', TRUE, FALSE, NOW(), NOW());
```

### Migrating Existing Users

```typescript
async function migrateExistingSalesReps(): Promise<void> {
  const salesReps = await this.userRepository.find({
    role: 'SALES_REP'
  });
  
  for (const salesRep of salesReps) {
    // Check if Manager exists in same organization
    const manager = await this.findManagerForOrganization(
      salesRep.organization_id
    );
    
    if (manager) {
      // Create hierarchy relationship
      await this.createHierarchyRelationship(
        manager.id,
        salesRep.id,
        'MANAGER',
        'SALES_REP'
      );
    }
  }
}
```

---

**Last Updated:** 2025-01-27  
**Version:** 1.0
