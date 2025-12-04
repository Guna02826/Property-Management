# Database Migrations

This directory contains Sequelize migration files for the Neorem platform database schema.

## Migration Files

### 001-add-soft-delete-fields.js
Adds `deleted_at` and `deleted_by` fields to all tables for recycle bin functionality.

**Tables Updated:**
- users
- buildings
- floors
- spaces
- bids
- contracts
- payments
- notifications
- private_visits
- role_hierarchy_config
- user_role_hierarchy

### 002-add-property-type-and-leave-management.js
- Adds `property_type` field to buildings table (COMMERCIAL, RESIDENTIAL, MIXED_USE)
- Adds leave management fields to users table (leave_status, leave_start_date, leave_end_date)

### 003-create-parking-spaces-table.js
Creates the `parking_spaces` table for parking management with assignment tracking.

**Features:**
- Parking space assignment to users or contracts
- Parking types: STANDARD, RESERVED, HANDICAP, ELECTRIC_CHARGING
- Monthly fee tracking
- Availability status

### 004-update-private-visits-rescheduling.js
Updates `private_visits` table to support rescheduling when sales reps are on leave.

**Changes:**
- Adds `RESCHEDULED` status to visit status enum
- Adds `rescheduled_from_visit_id` for tracking original visit
- Adds `rescheduled_reason` field

## Running Migrations

### Development
```bash
npx sequelize-cli db:migrate
```

### Production
```bash
NODE_ENV=production npx sequelize-cli db:migrate
```

### Rollback
```bash
# Rollback last migration
npx sequelize-cli db:migrate:undo

# Rollback to specific migration
npx sequelize-cli db:migrate:undo:all --to 002-add-property-type-and-leave-management.js
```

## Migration Order

Migrations must be run in order:
1. 001-add-soft-delete-fields.js
2. 002-add-property-type-and-leave-management.js
3. 003-create-parking-spaces-table.js
4. 004-update-private-visits-rescheduling.js

## Notes

- All migrations include both `up` and `down` methods for rollback support
- Partial indexes are used for performance optimization on soft delete queries
- ENUM types are created automatically by Sequelize
- Foreign key constraints ensure referential integrity

## Best Practices

1. **Always test migrations** on a development database first
2. **Backup database** before running migrations in production
3. **Run migrations in transaction** when possible
4. **Monitor migration execution** for errors
5. **Document breaking changes** in migration comments

---

**Last Updated:** 2025-01-27

