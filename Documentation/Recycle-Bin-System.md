# Recycle Bin / Soft Delete System

## Overview

The Neorem platform implements a comprehensive soft delete system with recycle bin functionality. All database records support soft deletion, allowing for data recovery and audit trails while maintaining data integrity.

## Design Principles

- **Soft Delete by Default:** All tables include `deleted_at` and `deleted_by` fields
- **Recycle Bin Access:** Only Super Admin can access deleted records
- **Permanent Delete:** Only Super Admin can permanently delete from recycle bin
- **Automatic Filtering:** All queries exclude soft-deleted records by default
- **Audit Trail:** Track who deleted records and when

## Database Schema

### Soft Delete Fields

All tables include the following fields:

```sql
deleted_at TIMESTAMP,
deleted_by UUID REFERENCES users(id)
```

### Indexes

Partial indexes are created on `deleted_at` for performance:

```sql
CREATE INDEX idx_table_name_deleted_at ON table_name(deleted_at) 
WHERE deleted_at IS NULL;
```

This ensures queries for active records are optimized.

## Implementation

### 1. Model Level (Sequelize)

All Sequelize models should include:

```javascript
const Model = sequelize.define('Model', {
  // ... other fields
  deletedAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'deleted_at'
  },
  deletedBy: {
    type: DataTypes.UUID,
    allowNull: true,
    field: 'deleted_by',
    references: {
      model: 'users',
      key: 'id'
    }
  }
}, {
  paranoid: true, // Enables soft delete
  defaultScope: {
    where: {
      deletedAt: null
    }
  }
});
```

### 2. Query Level

**Default Behavior (Active Records Only):**
```javascript
// Automatically excludes deleted records
const buildings = await Building.findAll();
```

**Include Deleted Records (Super Admin Only):**
```javascript
// Only Super Admin can access
const allBuildings = await Building.findAll({
  paranoid: false, // Include deleted
  where: {
    deletedAt: { [Op.ne]: null }
  }
});
```

**Only Deleted Records (Recycle Bin):**
```javascript
const deletedBuildings = await Building.findAll({
  paranoid: false,
  where: {
    deletedAt: { [Op.ne]: null }
  }
});
```

### 3. Delete Operations

**Soft Delete (Regular Users):**
```javascript
// Regular users can only soft delete
await building.update({
  deletedAt: new Date(),
  deletedBy: currentUser.id
});
```

**Permanent Delete (Super Admin Only):**
```javascript
// Only Super Admin can permanently delete
if (user.role === 'SUPER_ADMIN') {
  await building.destroy({ force: true }); // Hard delete
}
```

### 4. Restore Operations

**Restore from Recycle Bin (Super Admin Only):**
```javascript
if (user.role === 'SUPER_ADMIN') {
  await building.update({
    deletedAt: null,
    deletedBy: null
  });
}
```

## API Endpoints

### Recycle Bin Endpoints (Super Admin Only)

#### List Deleted Records
```
GET /api/admin/recycle-bin/:resourceType
```

**Query Parameters:**
- `resourceType`: buildings, spaces, users, etc.
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20)
- `sort`: Sort field (default: deleted_at)
- `order`: asc or desc (default: desc)

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Building Name",
      "deletedAt": "2025-01-27T12:00:00Z",
      "deletedBy": {
        "id": "uuid",
        "name": "User Name"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

#### Restore Record
```
POST /api/admin/recycle-bin/:resourceType/:id/restore
```

**Response:**
```json
{
  "success": true,
  "message": "Record restored successfully",
  "data": {
    "id": "uuid",
    "name": "Building Name"
  }
}
```

#### Permanently Delete Record
```
DELETE /api/admin/recycle-bin/:resourceType/:id
```

**Response:**
```json
{
  "success": true,
  "message": "Record permanently deleted"
}
```

#### Bulk Restore
```
POST /api/admin/recycle-bin/:resourceType/bulk-restore
```

**Body:**
```json
{
  "ids": ["uuid1", "uuid2", "uuid3"]
}
```

#### Bulk Permanent Delete
```
DELETE /api/admin/recycle-bin/:resourceType/bulk-delete
```

**Body:**
```json
{
  "ids": ["uuid1", "uuid2", "uuid3"]
}
```

### Regular Delete Endpoints

All delete endpoints automatically perform soft delete:

```
DELETE /api/buildings/:id
DELETE /api/spaces/:id
DELETE /api/users/:id
```

**Response:**
```json
{
  "success": true,
  "message": "Record moved to recycle bin"
}
```

## Access Control

### Role Permissions

| Role | View Active Records | View Deleted Records | Soft Delete | Restore | Permanent Delete |
|------|---------------------|---------------------|-------------|---------|------------------|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Owner | ✅ | ❌ | ✅ | ❌ | ❌ |
| Manager | ✅ | ❌ | ✅ | ❌ | ❌ |
| Client | ✅ | ❌ | ❌ | ❌ | ❌ |
| Sales Rep | ✅ | ❌ | ✅* | ❌ | ❌ |

*Sales Rep can only delete records they created

## Parent-Child Relationships

When deleting parent records with children, the system supports two strategies:

### Strategy: Detach
Remove parent reference only (set `parent_id` to NULL):

```
DELETE /api/buildings/:id?strategy=detach
```

### Strategy: Cascade
Soft delete parent and all children:

```
DELETE /api/buildings/:id?strategy=cascade
```

**Default:** If no strategy specified, system prevents deletion if children exist.

## Retention Policy

### Automatic Cleanup

Deleted records are automatically purged after retention period:

- **Default Retention:** 90 days
- **Configurable:** Per organization or resource type
- **Super Admin Override:** Can extend retention for specific records

### Cleanup Job

```javascript
// Scheduled job (daily)
async function cleanupRecycleBin() {
  const retentionDays = 90;
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - retentionDays);
  
  // Find records older than retention period
  const oldRecords = await Building.findAll({
    paranoid: false,
    where: {
      deletedAt: {
        [Op.lt]: cutoffDate
      }
    }
  });
  
  // Notify Super Admin before permanent deletion
  await notifySuperAdmin(oldRecords);
  
  // Permanent delete after notification period
  await Building.destroy({
    where: {
      deletedAt: {
        [Op.lt]: cutoffDate
      }
    },
    force: true
  });
}
```

## Best Practices

1. **Always Use Soft Delete:** Never hard delete unless absolutely necessary
2. **Check Permissions:** Verify user role before allowing restore/permanent delete
3. **Audit Trail:** Log all restore and permanent delete operations
4. **Notifications:** Notify relevant users when their records are deleted
5. **Cascade Strategy:** Clearly document deletion strategy for parent-child relationships
6. **Index Performance:** Use partial indexes on `deleted_at` for query optimization
7. **Retention Policy:** Configure appropriate retention periods per data type

## Migration Guide

### Adding Soft Delete to Existing Tables

```sql
-- Add soft delete columns
ALTER TABLE buildings 
ADD COLUMN deleted_at TIMESTAMP,
ADD COLUMN deleted_by UUID REFERENCES users(id);

-- Create partial index
CREATE INDEX idx_buildings_deleted_at 
ON buildings(deleted_at) 
WHERE deleted_at IS NULL;

-- Update existing queries to exclude deleted records
-- (Application code changes required)
```

## Related Documentation

- [Database Schema](./Database-Schema.md) - Complete schema with soft delete fields
- [Dynamic API Patterns](./Dynamic-API-Patterns.md) - Dynamic query support for recycle bin
- [Parent-Child Relationship Management](./Parent-Child-Relationships.md) - Deletion strategies

---

**Last Updated:** 2025-01-27  
**Version:** 1.0

