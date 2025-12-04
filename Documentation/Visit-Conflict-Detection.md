# Private Visit Booking and Conflict Detection

## Overview

The private visit booking system allows clients to schedule property viewings with automatic conflict detection to prevent scheduling clashes when multiple visits occur on the same day for the same space.

## Database Schema

### private_visits Table

The `private_visits` table stores all private visit bookings with the following key fields:

- `space_id`: The space being visited
- `client_id`: The client booking the visit
- `sales_rep_id`: Optional sales representative assigned to the visit
- `visit_date`: Date of the visit
- `start_time`: Start time of the visit
- `end_time`: End time of the visit
- `status`: Visit status (SCHEDULED, CONFIRMED, COMPLETED, CANCELLED, NO_SHOW)
- `visit_type`: Type of visit (PRIVATE, GROUP, VIRTUAL)

## Conflict Detection Logic

### Same-Day Conflict Prevention

The system prevents scheduling conflicts by:

1. **Date and Space Validation**: Before creating a new visit, the system checks for existing visits on the same date for the same space.

2. **Time Overlap Detection**: The system validates that the requested time slot does not overlap with existing visits:
   ```sql
   -- Example conflict detection query
   SELECT COUNT(*) 
   FROM private_visits 
   WHERE space_id = :space_id
     AND visit_date = :visit_date
     AND status IN ('SCHEDULED', 'CONFIRMED')
     AND (
       (start_time <= :new_start_time AND end_time > :new_start_time) OR
       (start_time < :new_end_time AND end_time >= :new_end_time) OR
       (start_time >= :new_start_time AND end_time <= :new_end_time)
     )
   ```

3. **Index Optimization**: The `idx_private_visits_date_space` and `idx_private_visits_date_time_range` indexes optimize conflict detection queries.

### Conflict Detection Rules

1. **Same Space, Same Day**: Two visits cannot be scheduled for the same space on the same day if their time ranges overlap.

2. **Status Consideration**: Only visits with status `SCHEDULED` or `CONFIRMED` are considered for conflict detection. Cancelled or completed visits do not block new bookings.

3. **Time Range Validation**: The system ensures `end_time > start_time` at the database level.

4. **Buffer Time (Optional)**: The application layer can implement buffer time between visits (e.g., 15 minutes) to allow for cleanup and preparation.

## Implementation Example

### Service Layer Logic

```typescript
async function createPrivateVisit(visitData: CreateVisitDto): Promise<PrivateVisit> {
  const { space_id, visit_date, start_time, end_time } = visitData;
  
  // Check for conflicts
  const conflicts = await this.checkVisitConflicts(
    space_id,
    visit_date,
    start_time,
    end_time
  );
  
  if (conflicts.length > 0) {
    throw new ConflictError(
      'A visit is already scheduled for this space on the same day with overlapping time'
    );
  }
  
  // Create the visit
  return await this.visitRepository.create(visitData);
}

async function checkVisitConflicts(
  spaceId: UUID,
  visitDate: Date,
  startTime: Time,
  endTime: Time
): Promise<PrivateVisit[]> {
  return await this.visitRepository.find({
    where: {
      space_id: spaceId,
      visit_date: visitDate,
      status: In(['SCHEDULED', 'CONFIRMED']),
      // Time overlap conditions
      OR: [
        { start_time: LessThanOrEqual(startTime), end_time: MoreThan(startTime) },
        { start_time: LessThan(endTime), end_time: MoreThanOrEqual(endTime) },
        { start_time: MoreThanOrEqual(startTime), end_time: LessThanOrEqual(endTime) }
      ]
    }
  });
}
```

### API Endpoint

```typescript
POST /api/v1/spaces/:spaceId/visits
{
  "client_id": "uuid",
  "sales_rep_id": "uuid", // optional
  "visit_date": "2025-02-15",
  "start_time": "10:00:00",
  "end_time": "11:00:00",
  "visit_type": "PRIVATE",
  "notes": "First visit",
  "contact_preference": "WHATSAPP"
}

// Response on conflict:
{
  "error": "CONFLICT",
  "message": "A visit is already scheduled for this space on 2025-02-15 between 10:30-11:30",
  "conflicting_visit": {
    "id": "uuid",
    "start_time": "10:30:00",
    "end_time": "11:30:00"
  }
}
```

## Alternative Time Slots

When a conflict is detected, the system can suggest alternative available time slots:

```typescript
async function suggestAlternativeSlots(
  spaceId: UUID,
  visitDate: Date,
  preferredStartTime: Time,
  preferredEndTime: Time
): Promise<TimeSlot[]> {
  const existingVisits = await this.getVisitsForDate(spaceId, visitDate);
  const availableSlots = this.calculateAvailableSlots(
    existingVisits,
    preferredStartTime,
    preferredEndTime
  );
  
  return availableSlots;
}
```

## Role-Based Access

### Client
- Can book private visits for available spaces
- Can view their own scheduled visits
- Can cancel their own visits (with appropriate notice)

### Sales Rep
- Can book visits on behalf of clients
- Can view all visits assigned to them
- Can update visit status (confirm, mark as completed, etc.)
- Must be overseen by Manager if Manager role exists (enforced by hierarchy)

### Manager
- Can view all visits for spaces they manage
- Can reassign visits to different sales reps
- Can override conflicts in exceptional circumstances (with audit log)

### Owner
- Can view all visits for their properties
- Can configure visit scheduling rules per building/space

## Notifications

The system sends notifications for:
- Visit confirmation (to client and sales rep)
- Visit reminders (24 hours and 1 hour before)
- Visit cancellation
- Conflict warnings (if attempting to book conflicting time)

## Audit Trail

All visit bookings and modifications are logged in the `audit_logs` table with:
- User who created/modified the visit
- Timestamp of action
- Previous and new values (for updates)
- Conflict resolution actions (if any)

---

**Last Updated:** 2025-01-27  
**Version:** 1.0

