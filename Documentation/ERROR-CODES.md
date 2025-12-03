# Error Codes Reference
## Enterprise Multi-Floor Commercial Office Leasing Platform

**Version:** 1.0  
**Date:** 2025-01-27

---

## Table of Contents

1. [Overview](#1-overview)
2. [Error Response Format](#2-error-response-format)
3. [HTTP Status Codes](#3-http-status-codes)
4. [Application Error Codes](#4-application-error-codes)
5. [Validation Errors](#5-validation-errors)
6. [Authentication Errors](#6-authentication-errors)
7. [Authorization Errors](#7-authorization-errors)
8. [Business Logic Errors](#8-business-logic-errors)
9. [System Errors](#9-system-errors)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Overview

This document provides a complete reference for all error codes returned by the API. Errors follow a consistent format and include error codes, messages, and optional details.

---

## 2. Error Response Format

### 2.1 Standard Error Response

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": [
      {
        "field": "field_name",
        "message": "Field-specific error message"
      }
    ],
    "timestamp": "2025-01-27T12:00:00Z",
    "request_id": "correlation-id"
  }
}
```

### 2.2 Minimal Error Response

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Error message"
  }
}
```

---

## 3. HTTP Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful request |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request data or validation error |
| 401 | Unauthorized | Authentication required or invalid |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource conflict (duplicate, constraint violation) |
| 422 | Unprocessable Entity | Valid format but semantic error |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Service temporarily unavailable |

---

## 4. Application Error Codes

### 4.1 Error Code Format

Error codes follow the pattern: `CATEGORY_SUBCATEGORY_DESCRIPTION`

Examples:
- `VALIDATION_EMAIL_INVALID`
- `AUTH_TOKEN_EXPIRED`
- `BIZ_SPACE_NOT_AVAILABLE`

---

## 5. Validation Errors (400)

### 5.1 General Validation

| Code | Message | Details |
|------|---------|---------|
| `VALIDATION_ERROR` | Validation failed | Array of field errors |
| `VALIDATION_REQUIRED` | Field is required | Field name |
| `VALIDATION_INVALID_FORMAT` | Invalid format | Field name and expected format |
| `VALIDATION_OUT_OF_RANGE` | Value out of range | Field name, min, max |

### 5.2 Email Validation

| Code | Message | Details |
|------|---------|---------|
| `VALIDATION_EMAIL_INVALID` | Invalid email format | Email field |
| `VALIDATION_EMAIL_REQUIRED` | Email is required | - |
| `VALIDATION_EMAIL_DUPLICATE` | Email already exists | Email value |

### 5.3 Password Validation

| Code | Message | Details |
|------|---------|---------|
| `VALIDATION_PASSWORD_WEAK` | Password does not meet requirements | Requirements list |
| `VALIDATION_PASSWORD_REQUIRED` | Password is required | - |
| `VALIDATION_PASSWORD_MISMATCH` | Passwords do not match | - |

### 5.4 Space Validation

| Code | Message | Details |
|------|---------|---------|
| `VALIDATION_SQFT_INVALID` | Usable square footage cannot exceed gross square footage | gross_sqft, usable_sqft |
| `VALIDATION_PRICE_INVALID` | Price must be positive | price field |
| `VALIDATION_AMENITIES_INVALID` | Invalid amenities format | Expected format |

### 5.5 Example Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "password",
        "message": "Password must be at least 8 characters"
      }
    ]
  }
}
```

---

## 6. Authentication Errors (401)

### 6.1 Token Errors

| Code | Message | Details |
|------|---------|---------|
| `AUTH_TOKEN_MISSING` | Authentication token required | - |
| `AUTH_TOKEN_INVALID` | Invalid authentication token | - |
| `AUTH_TOKEN_EXPIRED` | Authentication token expired | Expiration time |
| `AUTH_TOKEN_MALFORMED` | Malformed authentication token | - |

### 6.2 Credential Errors

| Code | Message | Details |
|------|---------|---------|
| `AUTH_CREDENTIALS_INVALID` | Invalid email or password | - |
| `AUTH_ACCOUNT_LOCKED` | Account is locked | Locked until timestamp |
| `AUTH_ACCOUNT_NOT_VERIFIED` | Email not verified | Verification required |
| `AUTH_PASSWORD_RESET_EXPIRED` | Password reset token expired | - |
| `AUTH_PASSWORD_RESET_INVALID` | Invalid password reset token | - |

### 6.3 Example Response

```json
{
  "error": {
    "code": "AUTH_TOKEN_EXPIRED",
    "message": "Authentication token expired",
    "details": {
      "expired_at": "2025-01-27T10:00:00Z"
    }
  }
}
```

---

## 7. Authorization Errors (403)

### 7.1 Permission Errors

| Code | Message | Details |
|------|---------|---------|
| `AUTHZ_INSUFFICIENT_PERMISSIONS` | Insufficient permissions | Required role/permission |
| `AUTHZ_RESOURCE_OWNERSHIP` | You do not own this resource | Resource type, resource ID |
| `AUTHZ_ROLE_REQUIRED` | Required role not assigned | Required role |

### 7.2 Example Response

```json
{
  "error": {
    "code": "AUTHZ_INSUFFICIENT_PERMISSIONS",
    "message": "Insufficient permissions to perform this action",
    "details": {
      "required_role": "OWNER",
      "current_role": "CLIENT"
    }
  }
}
```

---

## 8. Business Logic Errors

### 8.1 Resource Not Found (404)

| Code | Message | Details |
|------|---------|---------|
| `NOT_FOUND_USER` | User not found | User ID |
| `NOT_FOUND_BUILDING` | Building not found | Building ID |
| `NOT_FOUND_SPACE` | Space not found | Space ID |
| `NOT_FOUND_BID` | Bid not found | Bid ID |
| `NOT_FOUND_CONTRACT` | Contract not found | Contract ID |
| `NOT_FOUND_PAYMENT` | Payment not found | Payment ID |

### 8.2 Conflict Errors (409)

| Code | Message | Details |
|------|---------|---------|
| `CONFLICT_DUPLICATE_EMAIL` | Email already registered | Email |
| `CONFLICT_DUPLICATE_BID` | Active bid already exists for this space | Space ID, Client ID |
| `CONFLICT_ACTIVE_CONTRACT` | Space already has an active contract | Space ID, Contract ID |
| `CONFLICT_SPACE_OCCUPIED` | Space is currently occupied | Space ID |

### 8.3 Business Rule Errors (422)

| Code | Message | Details |
|------|---------|---------|
| `BIZ_SPACE_NOT_AVAILABLE` | Space is not available for bidding | Space ID, Current status |
| `BIZ_SPACE_NOT_LEASABLE` | Space is not leasable | Space ID, Usage type |
| `BIZ_BID_AMOUNT_INVALID` | Bid amount must be greater than 0 | Bid amount |
| `BIZ_BID_ALREADY_PROCESSED` | Bid has already been processed | Bid ID, Current status |
| `BIZ_CONTRACT_NOT_APPROVED` | Contract cannot be generated from unapproved bid | Bid ID, Bid status |
| `BIZ_PAYMENT_ALREADY_RECORDED` | Payment has already been recorded | Payment ID |
| `BIZ_PAYMENT_SCHEDULE_EXISTS` | Payment schedule already exists for this contract | Contract ID |

### 8.4 Example Response

```json
{
  "error": {
    "code": "BIZ_SPACE_NOT_AVAILABLE",
    "message": "Space is not available for bidding",
    "details": {
      "space_id": "uuid",
      "current_status": "OCCUPIED",
      "available_statuses": ["AVAILABLE", "RESERVED"]
    }
  }
}
```

---

## 9. System Errors

### 9.1 Rate Limiting (429)

| Code | Message | Details |
|------|---------|---------|
| `RATE_LIMIT_EXCEEDED` | Rate limit exceeded | Limit, Reset time |

**Example Response:**
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded",
    "details": {
      "limit": 100,
      "remaining": 0,
      "reset_at": "2025-01-27T13:00:00Z"
    }
  }
}
```

**Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1706313600
```

### 9.2 Server Errors (500)

| Code | Message | Details |
|------|---------|---------|
| `INTERNAL_SERVER_ERROR` | Internal server error | Request ID for support |
| `DATABASE_ERROR` | Database operation failed | - |
| `CACHE_ERROR` | Cache operation failed | - |
| `EXTERNAL_SERVICE_ERROR` | External service unavailable | Service name |

### 9.3 Service Unavailable (503)

| Code | Message | Details |
|------|---------|---------|
| `SERVICE_UNAVAILABLE` | Service temporarily unavailable | Retry after timestamp |
| `DATABASE_UNAVAILABLE` | Database temporarily unavailable | - |
| `CACHE_UNAVAILABLE` | Cache temporarily unavailable | - |

**Example Response:**
```json
{
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "Service temporarily unavailable",
    "details": {
      "retry_after": "2025-01-27T13:00:00Z"
    }
  }
}
```

---

## 10. Troubleshooting

### 10.1 Common Error Scenarios

#### Invalid Request Data

**Error:** `VALIDATION_ERROR`
**Solution:** Check request body against API documentation, verify all required fields are present and correctly formatted.

#### Authentication Token Expired

**Error:** `AUTH_TOKEN_EXPIRED`
**Solution:** Use refresh token endpoint to get new access token, or re-authenticate.

#### Insufficient Permissions

**Error:** `AUTHZ_INSUFFICIENT_PERMISSIONS`
**Solution:** Verify user role has required permissions. Contact administrator if role needs to be updated.

#### Resource Not Found

**Error:** `NOT_FOUND_*`
**Solution:** Verify resource ID is correct and resource exists. Check if resource was deleted.

#### Rate Limit Exceeded

**Error:** `RATE_LIMIT_EXCEEDED`
**Solution:** Wait until reset time or reduce request frequency. Consider implementing request batching.

### 10.2 Error Handling Best Practices

**Client-Side:**
- Display user-friendly error messages
- Log error details for debugging
- Implement retry logic for transient errors (5xx)
- Handle rate limiting gracefully
- Show appropriate UI feedback

**Server-Side:**
- Log all errors with context
- Include correlation IDs in responses
- Don't expose sensitive information
- Provide actionable error messages
- Monitor error rates and patterns

### 10.3 Error Logging

All errors are logged server-side with:
- Error code and message
- Request details (method, path, headers)
- User ID (if authenticated)
- Correlation ID
- Stack trace (development only)
- Timestamp

---

## 11. Error Code Reference Table

| Category | Prefix | Example Codes |
|----------|--------|---------------|
| Validation | `VALIDATION_` | `VALIDATION_ERROR`, `VALIDATION_EMAIL_INVALID` |
| Authentication | `AUTH_` | `AUTH_TOKEN_EXPIRED`, `AUTH_CREDENTIALS_INVALID` |
| Authorization | `AUTHZ_` | `AUTHZ_INSUFFICIENT_PERMISSIONS` |
| Not Found | `NOT_FOUND_` | `NOT_FOUND_USER`, `NOT_FOUND_SPACE` |
| Conflict | `CONFLICT_` | `CONFLICT_DUPLICATE_EMAIL`, `CONFLICT_DUPLICATE_BID` |
| Business Logic | `BIZ_` | `BIZ_SPACE_NOT_AVAILABLE`, `BIZ_BID_AMOUNT_INVALID` |
| Rate Limiting | `RATE_LIMIT_` | `RATE_LIMIT_EXCEEDED` |
| System | `INTERNAL_`, `DATABASE_`, `CACHE_` | `INTERNAL_SERVER_ERROR`, `DATABASE_ERROR` |
| Service | `SERVICE_` | `SERVICE_UNAVAILABLE` |

---

**Last Updated:** 2025-01-27

