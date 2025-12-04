# Role Hierarchy System

## Overview

The role hierarchy system provides a highly configurable mechanism to enforce hierarchical relationships between user roles, ensuring proper oversight and reporting structures. The system is designed to be extremely flexible and adapt to each organization's unique structure:

- **Small Companies:** May have only Owners
- **Medium Companies:** Owners + Managers
- **Large Companies:** Multiple Managers, Assistant Managers, and Sales Reps

The system supports multiple managers per organization, multiple assistant managers per manager, and multiple sales reps per manager/assistant manager. Hierarchy can be enabled or disabled per organization, and organizations can configure which roles are active in their structure.

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

**Owner → Manager**: Manager must always report to Owner (mandatory when Owner exists).

**Conditional Hierarchy for Sales Rep Team**:
- If Assistant Manager exists: Sales Rep team must be overseen by Assistant Manager
- If Assistant Manager does not exist: Sales Rep team must be overseen by Manager

This conditional logic ensures cost-effective hierarchy where Assistant Manager is only created when needed by Owner or Manager, avoiding unnecessary overhead.

### Standard Hierarchy Structure

**Small Company (Owner Only):**
```
OWNER
```

**Medium Company (Owner + Manager):**
```
OWNER
  └── MANAGER
      └── SALES_REP (if no Assistant Manager)
          └── CLIENT (via bookings/visits)
```

**Large Company (Multiple Managers, Assistant Managers, Sales Reps):**
```
OWNER
  ├── MANAGER_1
  │   ├── ASSISTANT_MANAGER_1 (optional)
  │   │   ├── SALES_REP_1
  │   │   ├── SALES_REP_2
  │   │   └── SALES_REP_3
  │   └── SALES_REP_4 (if no Assistant Manager)
  ├── MANAGER_2
  │   └── ASSISTANT_MANAGER_2
  │       ├── SALES_REP_5
  │       └── SALES_REP_6
  └── MANAGER_3
      └── SALES_REP_7
```

**Key Features:**
- Multiple Managers can report to the same Owner
- Multiple Assistant Managers can report to the same Manager
- Multiple Sales Reps can report to the same Manager or Assistant Manager
- System adapts to organization size and structure

### Hierarchy Rules

1. **Owner → Manager**: Manager reports to Owner (mandatory)
2. **Manager → Assistant Manager**: Assistant Manager reports to Manager (optional - created based on Owner or Manager's need)
3. **Assistant Manager → Sales Rep**: Sales Rep reports to Assistant Manager when Assistant Manager exists (conditional)
4. **Manager → Sales Rep**: Sales Rep reports directly to Manager when no Assistant Manager exists (conditional)
5. **Sales Rep → Client**: Sales Rep manages client relationships (not enforced in hierarchy table, but in business logic)

### Conditional Hierarchy Logic

The system implements conditional hierarchy based on the presence of Assistant Manager:

- **If Assistant Manager exists**: Sales Rep team reports to Assistant Manager
- **If Assistant Manager does not exist**: Sales Rep team reports directly to Manager

This ensures cost-effective hierarchy where Assistant Manager is only created when needed by Owner or Manager.

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
    // Check if Assistant Manager exists for this Manager
    const assistantManager = await this.findAssistantManagerForManager(
      userData.organization_id,
      userData.manager_id
    );
    
    // Determine parent based on Assistant Manager existence
    const parentId = assistantManager ? assistantManager.id : userData.manager_id;
    const parentRole = assistantManager ? 'ASSISTANT_MANAGER' : 'MANAGER';
    
    // Check if hierarchy is enabled for the appropriate parent role
    const hierarchyConfig = await this.hierarchyConfigRepository.findOne({
      where: {
        organization_id: userData.organization_id,
        parent_role: parentRole,
        child_role: 'SALES_REP',
        is_enabled: true
      }
    });
    
    if (hierarchyConfig) {
      // Sales Rep must be assigned to a parent (Manager or Assistant Manager)
      if (!parentId) {
        throw new ValidationError(
          `Sales Rep must be assigned to a ${parentRole} when Manager role exists`
        );
      }
      
      // Create user
      const salesRep = await this.userRepository.create(userData);
      
      // Create hierarchy relationship
      await this.userRoleHierarchyRepository.create({
        parent_user_id: parentId,
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

async function findAssistantManagerForManager(
  organizationId: UUID,
  managerId: UUID
): Promise<User | null> {
  // Check if there's an active Assistant Manager under this Manager
  const hierarchy = await this.userRoleHierarchyRepository.findOne({
    where: {
      parent_user_id: managerId,
      is_active: true
    },
    relations: ['child_user', 'hierarchy_config']
  });
  
  if (hierarchy && hierarchy.hierarchy_config.child_role === 'ASSISTANT_MANAGER') {
    return hierarchy.child_user;
  }
  
  return null;
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
  // Get direct Sales Reps under Manager (if no Assistant Manager)
  const directHierarchies = await this.userRoleHierarchyRepository.find({
    where: {
      parent_user_id: managerId,
      is_active: true
    },
    relations: ['child_user', 'hierarchy_config']
  });
  
  const directSalesReps = directHierarchies
    .filter(h => h.hierarchy_config.child_role === 'SALES_REP')
    .map(h => h.child_user);
  
  // Get Sales Reps under Assistant Managers (if Assistant Manager exists)
  const assistantManagers = directHierarchies
    .filter(h => h.hierarchy_config.child_role === 'ASSISTANT_MANAGER')
    .map(h => h.child_user);
  
  const indirectSalesReps: User[] = [];
  for (const assistantManager of assistantManagers) {
    const salesRepHierarchies = await this.userRoleHierarchyRepository.find({
      where: {
        parent_user_id: assistantManager.id,
        is_active: true
      },
      relations: ['child_user', 'hierarchy_config']
    });
    
    const salesReps = salesRepHierarchies
      .filter(h => h.hierarchy_config.child_role === 'SALES_REP')
      .map(h => h.child_user);
    
    indirectSalesReps.push(...salesReps);
  }
  
  // Return combined list (direct + indirect via Assistant Manager)
  return [...directSalesReps, ...indirectSalesReps];
}
```

## Organization-Level Role Configuration

### Role Activation per Organization

Organizations can enable/disable specific roles based on their needs:

```typescript
interface OrganizationRoleConfig {
  organization_id: UUID;
  roles_enabled: {
    MANAGER: boolean;
    ASSISTANT_MANAGER: boolean;
    SALES_REP: boolean;
  };
  max_managers?: number; // Optional limit
  max_assistant_managers_per_manager?: number; // Optional limit
  max_sales_reps_per_parent?: number; // Optional limit
}
```

### Organization Configuration UI

The system provides an organization-level role configuration interface:

```typescript
// Get organization role configuration
GET /api/v1/organizations/:orgId/role-config

// Update organization role configuration
PUT /api/v1/organizations/:orgId/role-config
{
  "roles_enabled": {
    "MANAGER": true,
    "ASSISTANT_MANAGER": true,
    "SALES_REP": true
  },
  "max_managers": null, // No limit
  "max_assistant_managers_per_manager": 3,
  "max_sales_reps_per_parent": 10
}
```

### Dynamic Hierarchy Validation

The system validates hierarchy based on organization configuration:

```typescript
async function validateHierarchyAssignment(
  organizationId: UUID,
  parentRole: string,
  childRole: string
): Promise<boolean> {
  // Get organization role configuration
  const orgConfig = await this.getOrganizationRoleConfig(organizationId);
  
  // Check if roles are enabled for this organization
  if (!orgConfig.roles_enabled[parentRole] || !orgConfig.roles_enabled[childRole]) {
    throw new ValidationError(
      `Role ${parentRole} or ${childRole} is not enabled for this organization`
    );
  }
  
  // Check limits if configured
  if (orgConfig.max_managers && parentRole === 'MANAGER') {
    const managerCount = await this.countManagers(organizationId);
    if (managerCount >= orgConfig.max_managers) {
      throw new ValidationError(
        `Maximum number of managers (${orgConfig.max_managers}) reached for this organization`
      );
    }
  }
  
  return true;
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
  (NULL, 'OWNER', 'MANAGER', TRUE, FALSE, NOW(), NOW()),
  (NULL, 'MANAGER', 'ASSISTANT_MANAGER', TRUE, FALSE, NOW(), NOW()),
  (NULL, 'ASSISTANT_MANAGER', 'SALES_REP', TRUE, FALSE, NOW(), NOW()),
  (NULL, 'MANAGER', 'SALES_REP', TRUE, FALSE, NOW(), NOW());
```

**Note:** Both `ASSISTANT_MANAGER → SALES_REP` and `MANAGER → SALES_REP` configurations are enabled by default. The system logic determines which one to use based on whether an Assistant Manager exists for the Manager. This ensures cost-effective hierarchy where Assistant Manager is optional.

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

## Multiple Managers/Assistant Managers/Sales Reps Support

### Creating Multiple Managers

```typescript
// Create multiple managers for the same owner
const manager1 = await createUser({
  role: 'MANAGER',
  organization_id: orgId,
  parent_id: ownerId
});

const manager2 = await createUser({
  role: 'MANAGER',
  organization_id: orgId,
  parent_id: ownerId
});

// Both managers report to the same owner
```

### Creating Multiple Assistant Managers

```typescript
// Create multiple assistant managers for the same manager
const assistantManager1 = await createUser({
  role: 'ASSISTANT_MANAGER',
  organization_id: orgId,
  parent_id: managerId
});

const assistantManager2 = await createUser({
  role: 'ASSISTANT_MANAGER',
  organization_id: orgId,
  parent_id: managerId
});

// Both assistant managers report to the same manager
```

### Creating Multiple Sales Reps

```typescript
// Create multiple sales reps under the same manager
const salesRep1 = await createUser({
  role: 'SALES_REP',
  organization_id: orgId,
  parent_id: managerId // or assistantManagerId
});

const salesRep2 = await createUser({
  role: 'SALES_REP',
  organization_id: orgId,
  parent_id: managerId
});

// Both sales reps report to the same manager (or assistant manager)
```

### Querying Multiple Hierarchies

```typescript
// Get all managers for an owner
async function getOwnerManagers(ownerId: UUID): Promise<User[]> {
  const hierarchies = await this.userRoleHierarchyRepository.find({
    where: {
      parent_user_id: ownerId,
      is_active: true
    },
    relations: ['child_user', 'hierarchy_config']
  });
  
  return hierarchies
    .filter(h => h.hierarchy_config.child_role === 'MANAGER')
    .map(h => h.child_user);
}

// Get all assistant managers for a manager
async function getManagerAssistantManagers(managerId: UUID): Promise<User[]> {
  const hierarchies = await this.userRoleHierarchyRepository.find({
    where: {
      parent_user_id: managerId,
      is_active: true
    },
    relations: ['child_user', 'hierarchy_config']
  });
  
  return hierarchies
    .filter(h => h.hierarchy_config.child_role === 'ASSISTANT_MANAGER')
    .map(h => h.child_user);
}
```

## Best Practices

1. **Start Simple:** Small organizations should start with Owner-only structure
2. **Scale Gradually:** Add Managers, then Assistant Managers, then Sales Reps as needed
3. **Configure Limits:** Set appropriate limits to prevent hierarchy bloat
4. **Monitor Performance:** Track hierarchy depth and width for performance optimization
5. **Document Structure:** Maintain clear documentation of each organization's hierarchy

---

**Last Updated:** 2025-01-27  
**Version:** 2.0

