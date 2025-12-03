## Code Style Guidelines

**Scope:** Applies to all code in this repository (backend, frontend, tests, scripts).  
**Primary Languages/Frameworks:** TypeScript, Node.js/Fastify, React/Next.js, TailwindCSS, shadcn/ui.

---

## 1. General Principles

- **Clarity over cleverness**: Prefer readable, explicit code to “smart” one-liners.
- **Single responsibility**: Keep functions, modules, and components focused on one concern.
- **Fail fast**: Validate inputs early and return/throw clear errors.
- **Consistency**: Follow the existing patterns in the codebase before introducing new ones.
- **Type safety**: Use TypeScript types and interfaces everywhere; avoid `any`.

---

## 2. TypeScript & JavaScript

- **Language**
  - Use **TypeScript** for all application code.
  - Avoid `any`; if unavoidable, wrap it in a clearly named type alias and add a TODO with justification.
  - Enable strict mode in `tsconfig.json` (e.g., `strict: true`).

- **Variables & Functions**
  - Use `const` by default; use `let` only when reassignment is required.
  - Do not use `var`.
  - Use arrow functions for inline callbacks and React components.
  - Prefer named exports over default exports for modules with multiple exports.

- **Error Handling**
  - Throw domain-specific errors (e.g., `ServiceError`) instead of raw `Error` where possible.
  - Never swallow errors silently; log them or return a typed error response.
  - Use `try/catch` at controller or boundary layers, not deep in utilities.

- **Imports**
  - Group imports: standard libs → third-party → internal.
  - Avoid deep relative paths (`../../../`); prefer path aliases via `tsconfig` when configured.

---

## 3. Backend Style (Fastify, Services, Models)

- **Controllers**
  - Keep controllers **thin**: validate input, call a service, map to HTTP response.
  - All request/response schemas should be defined and reused (JSON schema / DTO types).
  - Do not put business rules in controllers; move them into service classes.

- **Services**
  - Each service should encapsulate one domain: `BidService`, `LeaseService`, `PaymentService`, etc.
  - Services may depend on repositories/ORM models but not on HTTP-specific types.
  - Use dependency injection or explicit constructor parameters instead of importing globals.

- **Models / ORM**
  - Keep persistence logic (queries, mapping) in repositories or ORM models.
  - Avoid leaking ORM-specific types into controller signatures; wrap in domain types.

- **Error & Logging**
  - Use a shared error type (e.g., `ServiceError`) with `code`, `message`, and `statusCode`.
  - Log structured data (ids, roles, correlation ids), not just raw messages.

---

## 4. Frontend Style (React, Next.js, shadcn/ui)

- **Components**
  - Use **functional components** with hooks; do not use class components.
  - Keep components small and composable; extract subcomponents instead of deeply nested JSX.
  - Separate **container** (data fetching / state) and **presentational** (UI) concerns when complexity grows.

- **State Management**
  - Prefer local component state for simple UI.
  - Use React Query / SWR (or the chosen library) for server state when adopted.
  - Avoid prop drilling; use context only for cross-cutting concerns (theme, auth, layout).

- **Styling & Theme**
  - Use Tailwind utility classes and shadcn/ui primitives; **do not hardcode colors or fonts**.
  - Always use theme tokens (Tailwind config, CSS variables) for colors, typography, spacing, and shadows.
  - Keep styling co-located with components when simple; use shared style utilities for repetitive patterns.

- **Accessibility**
  - Use semantic HTML elements.
  - Ensure interactive elements are keyboard accessible.
  - Provide `aria-*` attributes and labels where needed.

---

## 5. Naming Conventions

- **Files & Folders**
  - Backend files/directories: `kebab-case` (e.g., `user-service.ts`, `building-controller.ts`).
  - Frontend components: `PascalCase` (e.g., `OwnerDashboard.tsx`, `BidListItem.tsx`).
  - Shared libraries/utils: `kebab-case` (e.g., `date-utils.ts`, `api-client.ts`).

- **Types & Interfaces**
  - Use `PascalCase` for types and interfaces: `User`, `BidInput`, `LeaseContract`.
  - Prefer `type` aliases for simple shapes and unions; use `interface` when extending is expected.

- **Enums & Constants**
  - Use `PascalCase` for enums: `BidStatus`, `UserRole`.
  - Use `UPPER_SNAKE_CASE` for constants: `MAX_BID_AMOUNT`, `DEFAULT_PAGE_SIZE`.

---

## 6. Comments & Documentation

- Write **self-documenting code**; use comments only where logic is non-obvious or business-critical.
- Use JSDoc/TSDoc for:
  - Public service methods
  - Complex utility functions
  - Public APIs or library-style modules
- Keep comments accurate; update or remove them when code changes.

---

## 7. Testing Conventions

- Co-locate tests under `tests/` or next to the implementation, following project structure.
- Name tests with `.test.ts` or `.spec.ts`.
- Use descriptive test names: `"should create bid when space is available"` versus `"works"`.
- For each bug fix, add at least one regression test.

---

## 8. Tooling

- **Linting**
  - Run `npm run lint` before committing.
  - Do not ignore linter errors without a clear, documented reason.

- **Formatting**
  - Use the configured formatter (e.g., Prettier) via `npm run format` or editor integration.
  - Do not hand-format code contrary to formatter rules.


