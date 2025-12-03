# Testing Strategy
## Enterprise Multi-Floor Commercial Office Leasing Platform

**Version:** 1.0  
**Date:** 2025-01-27

---

## Table of Contents

1. [Overview](#1-overview)
2. [Testing Pyramid](#2-testing-pyramid)
3. [Unit Testing](#3-unit-testing)
4. [Integration Testing](#4-integration-testing)
5. [End-to-End Testing](#5-end-to-end-testing)
6. [Performance Testing](#6-performance-testing)
7. [Security Testing](#7-security-testing)
8. [Test Coverage](#8-test-coverage)
9. [Test Data Management](#9-test-data-management)
10. [CI/CD Integration](#10-cicd-integration)

---

## 1. Overview

### 1.1 Testing Objectives

- Ensure code quality and reliability
- Prevent regressions
- Validate business logic
- Verify API contracts
- Ensure security compliance
- Maintain 80%+ code coverage

### 1.2 Testing Principles

- **Test Early, Test Often:** Write tests alongside code
- **Test Isolation:** Each test should be independent
- **Test Clarity:** Tests should be readable and maintainable
- **Fast Feedback:** Tests should run quickly
- **Realistic Data:** Use realistic test data

---

## 2. Testing Pyramid

```
        /\
       /  \      E2E Tests (10%)
      /____\
     /      \    Integration Tests (20%)
    /________\
   /          \  Unit Tests (70%)
  /____________\
```

### 2.1 Distribution

- **70% Unit Tests:** Fast, isolated, test individual functions
- **20% Integration Tests:** Test component interactions
- **10% E2E Tests:** Test complete user workflows

---

## 3. Unit Testing

### 3.1 Scope

Test individual functions, methods, and classes in isolation.

### 3.2 Tools

- **Framework:** Jest or Vitest
- **Assertions:** Jest assertions or Chai
- **Mocks:** Jest mocks or Sinon
- **Coverage:** Istanbul/NYC

### 3.3 Example

```typescript
// services/bid.service.test.ts
import { BidService } from './bid.service';
import { SpaceService } from './space.service';
import { NotificationService } from './notification.service';

describe('BidService', () => {
  let bidService: BidService;
  let mockSpaceService: jest.Mocked<SpaceService>;
  let mockNotificationService: jest.Mocked<NotificationService>;

  beforeEach(() => {
    mockSpaceService = {
      getById: jest.fn(),
      updateAvailability: jest.fn(),
    } as any;
    
    mockNotificationService = {
      sendBidCreated: jest.fn(),
    } as any;

    bidService = new BidService(mockSpaceService, mockNotificationService);
  });

  describe('createBid', () => {
    it('should create bid when space is available', async () => {
      // Arrange
      const spaceId = 'space-123';
      const clientId = 'client-123';
      const bidData = { bid_amount: 5000 };
      
      mockSpaceService.getById.mockResolvedValue({
        id: spaceId,
        availability_status: 'AVAILABLE',
        is_leasable: true,
      });

      // Act
      const result = await bidService.createBid(spaceId, clientId, bidData);

      // Assert
      expect(result.status).toBe('PENDING');
      expect(mockNotificationService.sendBidCreated).toHaveBeenCalled();
    });

    it('should throw error when space is not available', async () => {
      // Arrange
      mockSpaceService.getById.mockResolvedValue({
        availability_status: 'OCCUPIED',
      });

      // Act & Assert
      await expect(
        bidService.createBid('space-123', 'client-123', { bid_amount: 5000 })
      ).rejects.toThrow('Space not available');
    });
  });
});
```

### 3.4 Best Practices

- **AAA Pattern:** Arrange, Act, Assert
- **One Assertion Per Test:** Focus on one behavior
- **Descriptive Names:** Test names should describe behavior
- **Mock External Dependencies:** Don't test database or external APIs
- **Test Edge Cases:** Null, empty, boundary values

---

## 4. Integration Testing

### 4.1 Scope

Test interactions between components, services, and database.

### 4.2 Tools

- **Framework:** Jest with Supertest
- **Database:** Test database (PostgreSQL)
- **Redis:** Test Redis instance or mock
- **HTTP Client:** Supertest for API testing

### 4.3 Example

```typescript
// tests/integration/bid.api.test.ts
import request from 'supertest';
import { app } from '../../src/app';
import { db } from '../../src/db';

describe('Bid API Integration', () => {
  let authToken: string;
  let spaceId: string;

  beforeAll(async () => {
    // Setup test database
    await db.migrate.latest();
    
    // Create test user and get token
    const response = await request(app)
      .post('/api/v1/auth/register')
      .send({
        email: 'test@example.com',
        password: 'Test123!',
        name: 'Test User',
        role: 'CLIENT',
      });
    authToken = response.body.token;
    
    // Create test space
    const spaceResponse = await request(app)
      .post('/api/v1/spaces')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        floor_id: 'floor-123',
        name: 'Test Space',
        gross_sqft: 1000,
        usable_sqft: 800,
        is_leasable: true,
      });
    spaceId = spaceResponse.body.data.id;
  });

  afterAll(async () => {
    await db.migrate.rollback();
    await db.destroy();
  });

  describe('POST /api/v1/bids', () => {
    it('should create bid successfully', async () => {
      const response = await request(app)
        .post('/api/v1/bids')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          space_id: spaceId,
          bid_amount: 5000,
        });

      expect(response.status).toBe(201);
      expect(response.body.data.status).toBe('PENDING');
      expect(response.body.data.bid_amount).toBe(5000);
    });

    it('should return 400 for invalid bid amount', async () => {
      const response = await request(app)
        .post('/api/v1/bids')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          space_id: spaceId,
          bid_amount: -100,
        });

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });
  });
});
```

### 4.4 Best Practices

- **Test Database:** Use separate test database
- **Clean State:** Reset database between tests
- **Real Dependencies:** Use real database, mock external APIs
- **Test API Contracts:** Verify request/response formats
- **Test Error Cases:** 400, 401, 403, 404 responses

---

## 5. End-to-End Testing

### 5.1 Scope

Test complete user workflows from UI to database.

### 5.2 Tools

- **Framework:** Playwright or Cypress
- **Browser:** Chromium, Firefox, WebKit
- **API:** Test API endpoints directly

### 5.3 Example

```typescript
// tests/e2e/bid-workflow.test.ts
import { test, expect } from '@playwright/test';

test.describe('Bid Workflow', () => {
  test('client can place bid and owner can approve', async ({ page }) => {
    // Step 1: Client logs in
    await page.goto('http://localhost:3000/login');
    await page.fill('[name="email"]', 'client@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    
    // Step 2: Client searches for space
    await page.goto('http://localhost:3000/spaces');
    await page.fill('[name="search"]', 'Office Suite');
    await page.click('button[type="submit"]');
    
    // Step 3: Client views space details
    await page.click('.space-card:first-child');
    await expect(page.locator('.space-name')).toBeVisible();
    
    // Step 4: Client places bid
    await page.fill('[name="bid_amount"]', '5000');
    await page.click('button:has-text("Place Bid")');
    
    // Step 5: Verify bid confirmation
    await expect(page.locator('.bid-confirmation')).toBeVisible();
    await expect(page.locator('.bid-status')).toHaveText('PENDING');
    
    // Step 6: Owner logs in and approves
    await page.goto('http://localhost:3000/login');
    await page.fill('[name="email"]', 'owner@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    
    // Step 7: Owner views bids
    await page.goto('http://localhost:3000/owner/bids');
    await page.click('.bid-item:first-child');
    
    // Step 8: Owner approves bid
    await page.click('button:has-text("Approve")');
    await expect(page.locator('.bid-status')).toHaveText('APPROVED');
  });
});
```

### 5.4 Best Practices

- **Critical Paths:** Test main user journeys
- **Realistic Data:** Use production-like data
- **Parallel Execution:** Run tests in parallel
- **Screenshots:** Capture screenshots on failure
- **Video Recording:** Record test execution

---

## 6. Performance Testing

### 6.1 Scope

Test system performance under load.

### 6.2 Tools

- **Load Testing:** k6, Artillery, or Apache JMeter
- **Profiling:** Node.js built-in profiler
- **Monitoring:** Prometheus, Grafana

### 6.3 Example

```javascript
// tests/performance/api-load.test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 }, // Ramp up to 100 users
    { duration: '5m', target: 100 }, // Stay at 100 users
    { duration: '2m', target: 200 }, // Ramp up to 200 users
    { duration: '5m', target: 200 }, // Stay at 200 users
    { duration: '2m', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests < 500ms
    http_req_failed: ['rate<0.01'],    // Error rate < 1%
  },
};

export default function () {
  const response = http.get('http://localhost:3000/api/v1/spaces');
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  sleep(1);
}
```

### 6.4 Performance Targets

- **API Response:** < 500ms (95th percentile)
- **Page Load:** < 2 seconds (95th percentile)
- **Search Results:** < 1 second
- **Concurrent Users:** 100,000+
- **Transactions:** 10,000+ per minute

---

## 7. Security Testing

### 7.1 Scope

Test security vulnerabilities and compliance.

### 7.2 Areas to Test

- **Authentication:** Token validation, password strength
- **Authorization:** Role-based access control
- **Input Validation:** SQL injection, XSS prevention
- **Rate Limiting:** DDoS protection
- **Data Encryption:** Sensitive data protection

### 7.3 Example

```typescript
// tests/security/auth.test.ts
describe('Security Tests', () => {
  it('should reject invalid JWT token', async () => {
    const response = await request(app)
      .get('/api/v1/users/me')
      .set('Authorization', 'Bearer invalid-token');

    expect(response.status).toBe(401);
  });

  it('should prevent SQL injection', async () => {
    const maliciousInput = "'; DROP TABLE users; --";
    const response = await request(app)
      .get(`/api/v1/spaces?search=${maliciousInput}`);

    expect(response.status).toBe(400);
    // Verify users table still exists
  });

  it('should enforce rate limiting', async () => {
    const requests = Array(10).fill(null).map(() =>
      request(app).post('/api/v1/auth/login').send({
        email: 'test@example.com',
        password: 'wrong',
      })
    );

    const responses = await Promise.all(requests);
    const rateLimited = responses.filter(r => r.status === 429);
    
    expect(rateLimited.length).toBeGreaterThan(0);
  });
});
```

---

## 8. Test Coverage

### 8.1 Coverage Targets

- **Overall Coverage:** 80%+
- **Business Logic:** 90%+
- **API Endpoints:** 100%
- **Critical Paths:** 100%

### 8.2 Coverage Reports

```bash
# Generate coverage report
npm run test:coverage

# View HTML report
open coverage/index.html
```

### 8.3 Coverage Tools

- **Istanbul/NYC:** Code coverage
- **Coveralls/Codecov:** Coverage tracking
- **SonarQube:** Code quality and coverage

---

## 9. Test Data Management

### 9.1 Test Fixtures

```typescript
// tests/fixtures/users.ts
export const testUsers = {
  client: {
    email: 'client@test.com',
    password: 'Test123!',
    role: 'CLIENT',
  },
  owner: {
    email: 'owner@test.com',
    password: 'Test123!',
    role: 'OWNER',
  },
};

// tests/fixtures/spaces.ts
export const testSpaces = {
  available: {
    name: 'Test Office',
    gross_sqft: 1000,
    usable_sqft: 800,
    is_leasable: true,
    availability_status: 'AVAILABLE',
  },
};
```

### 9.2 Database Seeding

```bash
# Seed test database
npm run seed:test

# Reset test database
npm run db:reset:test
```

### 9.3 Test Isolation

- Each test should be independent
- Use transactions for database tests
- Clean up test data after tests
- Use factories for test data generation

---

## 10. CI/CD Integration

### 10.1 Test Execution

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:6
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run migrations
        run: npm run migrate
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
      
      - name: Run tests
        run: npm test
      
      - name: Generate coverage
        run: npm run test:coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### 10.2 Test Gates

- **Unit Tests:** Must pass before merge
- **Integration Tests:** Must pass before merge
- **Coverage:** Must maintain 80%+ coverage
- **E2E Tests:** Run on staging before production deploy

---

## 11. Test Execution

### 11.1 Running Tests

```bash
# Run all tests
npm test

# Run unit tests only
npm run test:unit

# Run integration tests only
npm run test:integration

# Run E2E tests only
npm run test:e2e

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### 11.2 Test Reports

- **Console:** Standard output
- **HTML:** Coverage reports in `coverage/`
- **JUnit:** XML reports for CI/CD
- **JSON:** Machine-readable test results

---

**Last Updated:** 2025-01-27

