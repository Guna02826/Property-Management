# Dynamic API / Database Field Handling

## Overview

The Neorem platform implements a fully dynamic API system that adapts to database schema changes without requiring API modifications. This allows for maximum flexibility and future-proofing of the system.

## Core Principles

- **No Hardcoded Field Mappings:** APIs work dynamically based on request parameters
- **Schema Introspection:** Use database schema introspection for field validation
- **Query-Based Field Selection:** Frontend can request any fields via query params
- **Dynamic Filtering:** Support complex filtering without code changes
- **Dynamic Sorting:** Flexible sorting based on any field
- **Future-Proof:** Database field changes don't require API modifications

## Field Selection

### Basic Field Selection

Request specific fields using the `fields` query parameter:

```
GET /api/buildings?fields=id,name,address.city,amenities
```

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Building Name",
      "address": {
        "city": "New York"
      },
      "amenities": ["Parking", "Elevator"]
    }
  ]
}
```

### Nested Field Selection

Select nested fields using dot notation:

```
GET /api/buildings?fields=id,name,owner.name,owner.email,floors.floor_number
```

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Building Name",
      "owner": {
        "name": "Owner Name",
        "email": "owner@example.com"
      },
      "floors": [
        {
          "floor_number": 1
        },
        {
          "floor_number": 2
        }
      ]
    }
  ]
}
```

### Exclude Fields

Exclude specific fields using `exclude` parameter:

```
GET /api/buildings?exclude=created_at,updated_at,deleted_at
```

### Default Fields

If no `fields` parameter is provided, return all non-sensitive fields:

```javascript
// Default fields configuration
const defaultFields = {
  buildings: ['id', 'name', 'address', 'property_type', 'amenities', 'created_at'],
  users: ['id', 'name', 'email', 'role', 'created_at'],
  spaces: ['id', 'name', 'gross_sqft', 'usable_sqft', 'availability_status']
};
```

## Dynamic Filtering

### Basic Filtering

Filter by any field using the `filter` parameter:

```
GET /api/buildings?filter[property_type]=COMMERCIAL
GET /api/buildings?filter[property_type]=RESIDENTIAL&filter[city]=New York
```

### Comparison Operators

Support various comparison operators:

```
GET /api/spaces?filter[base_price_monthly][gte]=1000
GET /api/spaces?filter[base_price_monthly][lte]=5000
GET /api/spaces?filter[base_price_monthly][between]=1000,5000
GET /api/spaces?filter[availability_status][in]=AVAILABLE,OCCUPIED
GET /api/spaces?filter[name][like]=Office%
GET /api/spaces?filter[gross_sqft][gt]=1000
```

**Operators:**
- `eq` / `=` - Equal
- `ne` / `!=` - Not equal
- `gt` - Greater than
- `gte` - Greater than or equal
- `lt` - Less than
- `lte` - Less than or equal
- `between` - Between two values
- `in` - In array
- `notIn` - Not in array
- `like` - SQL LIKE
- `ilike` - Case-insensitive LIKE
- `isNull` - Is NULL
- `isNotNull` - Is not NULL

### Nested Filtering

Filter on related models:

```
GET /api/buildings?filter[owner.role]=OWNER&filter[floors.total_sqft][gte]=10000
```

### Complex Filtering (AND/OR)

Combine filters with logical operators:

```
GET /api/spaces?filter[or][0][property_type]=COMMERCIAL&filter[or][1][property_type]=MIXED_USE
GET /api/spaces?filter[and][0][base_price_monthly][gte]=1000&filter[and][1][availability_status]=AVAILABLE
```

**JSON Body Format (for complex queries):**
```json
{
  "filter": {
    "or": [
      { "property_type": "COMMERCIAL" },
      { "property_type": "MIXED_USE" }
    ],
    "and": [
      { "base_price_monthly": { "gte": 1000 } },
      { "availability_status": "AVAILABLE" }
    ]
  }
}
```

## Dynamic Sorting

### Basic Sorting

Sort by any field:

```
GET /api/buildings?sort=name
GET /api/buildings?sort=created_at:desc
GET /api/buildings?sort=name:asc,created_at:desc
```

### Nested Sorting

Sort by related model fields:

```
GET /api/buildings?sort=owner.name:asc,floors.floor_number:asc
```

## Dynamic Pagination

### Standard Pagination

```
GET /api/buildings?page=1&limit=20
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5,
    "hasNext": true,
    "hasPrev": false
  }
}
```

### Cursor-Based Pagination

```
GET /api/buildings?cursor=uuid&limit=20
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "cursor": "next-cursor-uuid",
    "limit": 20,
    "hasNext": true
  }
}
```

## Implementation (Sequelize)

### Dynamic Query Builder

```javascript
class DynamicQueryBuilder {
  constructor(model, request) {
    this.model = model;
    this.request = request;
    this.query = {
      where: {},
      attributes: [],
      include: [],
      order: [],
      limit: null,
      offset: null
    };
  }

  // Parse fields parameter
  parseFields() {
    const { fields } = this.request.query;
    if (fields) {
      const fieldList = fields.split(',');
      // Validate fields against schema
      const validFields = this.validateFields(fieldList);
      this.query.attributes = validFields;
    }
    return this;
  }

  // Parse filter parameter
  parseFilters() {
    const { filter } = this.request.query;
    if (filter) {
      this.query.where = this.buildWhereClause(filter);
    }
    return this;
  }

  // Parse sort parameter
  parseSort() {
    const { sort } = this.request.query;
    if (sort) {
      const sortList = sort.split(',');
      this.query.order = sortList.map(s => {
        const [field, direction = 'ASC'] = s.split(':');
        return [field, direction.toUpperCase()];
      });
    }
    return this;
  }

  // Parse pagination
  parsePagination() {
    const { page, limit } = this.request.query;
    if (limit) {
      this.query.limit = parseInt(limit);
      if (page) {
        this.query.offset = (parseInt(page) - 1) * this.query.limit;
      }
    }
    return this;
  }

  // Validate fields against database schema
  validateFields(fields) {
    const tableAttributes = this.model.rawAttributes;
    const validFields = [];
    
    fields.forEach(field => {
      // Handle nested fields (e.g., "address.city")
      const parts = field.split('.');
      const baseField = parts[0];
      
      if (tableAttributes[baseField]) {
        validFields.push(field);
      } else {
        // Check if it's a relation
        const association = this.model.associations[baseField];
        if (association) {
          validFields.push(field);
        }
      }
    });
    
    return validFields;
  }

  // Build WHERE clause from filter object
  buildWhereClause(filter) {
    const { Op } = require('sequelize');
    const where = {};
    
    Object.keys(filter).forEach(key => {
      const value = filter[key];
      
      // Handle operators (gte, lte, etc.)
      if (typeof value === 'object' && !Array.isArray(value)) {
        Object.keys(value).forEach(op => {
          const opMap = {
            'gte': Op.gte,
            'lte': Op.lte,
            'gt': Op.gt,
            'lt': Op.lt,
            'ne': Op.ne,
            'in': Op.in,
            'notIn': Op.notIn,
            'like': Op.like,
            'ilike': Op.iLike,
            'between': Op.between
          };
          
          if (opMap[op]) {
            where[key] = {
              [opMap[op]]: value[op]
            };
          }
        });
      } else {
        where[key] = value;
      }
    });
    
    return where;
  }

  // Execute query
  async execute() {
    return await this.model.findAll(this.query);
  }
}
```

### Usage in Controller

```javascript
async function getBuildings(req, res) {
  try {
    const builder = new DynamicQueryBuilder(Building, req);
    
    const buildings = await builder
      .parseFields()
      .parseFilters()
      .parseSort()
      .parsePagination()
      .execute();
    
    res.json({
      data: buildings,
      pagination: builder.getPagination()
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
}
```

## Schema Introspection

### Get Available Fields

```
GET /api/buildings/schema
```

**Response:**
```json
{
  "fields": [
    {
      "name": "id",
      "type": "UUID",
      "required": true,
      "readOnly": true
    },
    {
      "name": "name",
      "type": "VARCHAR(255)",
      "required": true,
      "readOnly": false
    },
    {
      "name": "property_type",
      "type": "ENUM",
      "values": ["COMMERCIAL", "RESIDENTIAL", "MIXED_USE"],
      "required": false,
      "readOnly": false
    },
    {
      "name": "address",
      "type": "JSONB",
      "required": true,
      "readOnly": false
    }
  ],
  "relations": [
    {
      "name": "owner",
      "type": "belongsTo",
      "model": "User"
    },
    {
      "name": "floors",
      "type": "hasMany",
      "model": "Floor"
    }
  ]
}
```

## Error Handling

### Invalid Field

```
GET /api/buildings?fields=invalid_field
```

**Response:**
```json
{
  "error": "Invalid field: invalid_field",
  "availableFields": ["id", "name", "address", "property_type", ...]
}
```

### Invalid Filter

```
GET /api/buildings?filter[invalid_field]=value
```

**Response:**
```json
{
  "error": "Invalid filter field: invalid_field",
  "availableFields": ["id", "name", "address", "property_type", ...]
}
```

## Security Considerations

1. **Field Access Control:** Validate field access based on user role
2. **Sensitive Fields:** Never expose sensitive fields (passwords, tokens)
3. **Rate Limiting:** Implement rate limiting on dynamic queries
4. **Query Complexity:** Limit depth of nested queries to prevent performance issues
5. **SQL Injection:** Use parameterized queries (Sequelize handles this)

## Performance Optimization

1. **Index Strategy:** Ensure frequently filtered/sorted fields are indexed
2. **Query Caching:** Cache common query patterns
3. **Field Limiting:** Encourage field selection to reduce payload size
4. **Pagination:** Always enforce pagination limits
5. **Eager Loading:** Optimize includes for nested field selection

## Best Practices

1. **Always Validate Fields:** Use schema introspection to validate requested fields
2. **Document Available Fields:** Provide schema endpoint for frontend discovery
3. **Default Fields:** Provide sensible defaults when fields not specified
4. **Error Messages:** Provide helpful error messages with available options
5. **Performance Monitoring:** Monitor query performance and optimize slow queries
6. **Field Documentation:** Document all available fields and their types

## Example API Calls

### Complex Query Example

```
GET /api/spaces?fields=id,name,gross_sqft,base_price_monthly,floor.building.name&filter[base_price_monthly][between]=1000,5000&filter[availability_status]=AVAILABLE&filter[floor.building.property_type]=COMMERCIAL&sort=base_price_monthly:asc&page=1&limit=20
```

This query:
- Selects specific fields including nested building name
- Filters by price range and availability
- Filters by building property type
- Sorts by price ascending
- Paginates results

## Related Documentation

- [Database Schema](./Database-Schema.md) - Complete database schema
- [Recycle Bin System](./Recycle-Bin-System.md) - Soft delete with dynamic queries
- [API Documentation](./API-Documentation.md) - Complete API reference

---

**Last Updated:** 2025-01-27  
**Version:** 1.0

