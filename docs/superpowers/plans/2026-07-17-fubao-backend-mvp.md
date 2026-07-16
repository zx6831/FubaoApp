# Fubao Backend MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a locally deployable NestJS API for authentication, family roles, plans, tasks, topics, sparks, and health-management alerts.

**Architecture:** Modular NestJS service backed by PostgreSQL through Prisma, Redis for expiring codes and queues, and adapters for SMS, APNs, and MQTT. Docker Compose provides repeatable local infrastructure; the Flutter app initially uses demo data, then switches to the HTTP adapter.

**Tech Stack:** Node.js 22, NestJS, TypeScript, Prisma, PostgreSQL 16, Redis 7, Jest, Supertest, Docker Compose

## Global Constraints

- Mainland-China deployment readiness and personal-health-data minimization.
- One family has one child owner and one elder member in V1.
- Invitation codes are four digits and expire after 30 minutes.
- Account deletion schedules personal-data erasure after 30 days.
- Health thresholds produce care reminders only and never medical diagnoses.
- External SMS, APNs, and MQTT systems are adapter interfaces with local fake implementations.

---

### Task 1: Service scaffold, health endpoint, and local infrastructure

**Files:**
- Create: `services/api/package.json`
- Create: `services/api/src/main.ts`
- Create: `services/api/src/app.module.ts`
- Create: `services/api/src/health/health.controller.ts`
- Create: `services/api/test/health.e2e-spec.ts`
- Create: `services/api/prisma/schema.prisma`
- Create: `docker-compose.yml`

**Interfaces:**
- Produces: `GET /health` returning `{ "status": "ok" }`, PostgreSQL and Redis services.

- [ ] **Step 1: Write the health endpoint test**

```ts
it('GET /health', () => request(app.getHttpServer()).get('/health').expect(200, { status: 'ok' }));
```

- [ ] **Step 2: Run the test and confirm failure**

Run: `npm.cmd test -- health.e2e-spec.ts`
Expected: FAIL before the NestJS scaffold exists.

- [ ] **Step 3: Implement the minimal endpoint and Prisma configuration**

```ts
@Controller('health')
export class HealthController {
  @Get() status() { return { status: 'ok' }; }
}
```

- [ ] **Step 4: Run the health test**

Run: `npm.cmd test -- health.e2e-spec.ts`
Expected: PASS.

- [ ] **Step 5: Commit the service foundation**

```bash
git add services/api docker-compose.yml
git commit -m "feat: scaffold fubao api"
```

### Task 2: Test login, users, families, and invitations

**Files:**
- Create: `services/api/src/auth/auth.module.ts`
- Create: `services/api/src/auth/auth.controller.ts`
- Create: `services/api/src/auth/auth.service.ts`
- Create: `services/api/src/families/families.module.ts`
- Create: `services/api/src/families/families.service.ts`
- Test: `services/api/test/family-flow.e2e-spec.ts`

**Interfaces:**
- Produces: `POST /auth/test-login`, `POST /families`, `POST /families/invitations`, `POST /families/join`.

- [ ] **Step 1: Write the family invitation flow test**

```ts
expect(invitation.body.code).toMatch(/^\d{4}$/);
expect(join.body.role).toBe('elder');
```

- [ ] **Step 2: Run the focused test**

Run: `npm.cmd test -- family-flow.e2e-spec.ts`
Expected: FAIL before auth and family modules exist.

- [ ] **Step 3: Implement JWT test login and 30-minute invitations**

Store only a SHA-256 digest of each invitation code, its family id, and expiry; reject reuse, expiry, and a second elder membership.

- [ ] **Step 4: Run family tests**

Run: `npm.cmd test -- family-flow.e2e-spec.ts`
Expected: PASS.

- [ ] **Step 5: Commit account and family flows**

```bash
git add services/api/src/auth services/api/src/families services/api/test/family-flow.e2e-spec.ts services/api/prisma
git commit -m "feat: add family role binding"
```

### Task 3: Plans, daily tasks, and idempotent completion

**Files:**
- Create: `services/api/src/plans/plans.module.ts`
- Create: `services/api/src/plans/plans.controller.ts`
- Create: `services/api/src/plans/plans.service.ts`
- Create: `services/api/src/tasks/tasks.module.ts`
- Create: `services/api/src/tasks/tasks.service.ts`
- Test: `services/api/test/task-flow.e2e-spec.ts`

**Interfaces:**
- Produces: `POST /plans`, `GET /plans`, `GET /tasks/today`, `POST /tasks/:id/complete` with `Idempotency-Key`.

- [ ] **Step 1: Write plan and task tests**

```ts
expect(today.body).toEqual(expect.arrayContaining([expect.objectContaining({ kind: 'medicine' })]));
expect(secondCompletion.body.completedAt).toBe(firstCompletion.body.completedAt);
```

- [ ] **Step 2: Run the task tests**

Run: `npm.cmd test -- task-flow.e2e-spec.ts`
Expected: FAIL before plan and task modules exist.

- [ ] **Step 3: Implement role guards, daily generation, and completion**

Child accounts create or pause plans; elder accounts complete generated daily tasks; duplicate idempotency keys return the original result.

- [ ] **Step 4: Run task tests**

Run: `npm.cmd test -- task-flow.e2e-spec.ts`
Expected: PASS.

- [ ] **Step 5: Commit plans and tasks**

```bash
git add services/api/src/plans services/api/src/tasks services/api/test/task-flow.e2e-spec.ts services/api/prisma
git commit -m "feat: add plans and daily tasks"
```

### Task 4: Sparks, topics, health readings, and care alerts

**Files:**
- Create: `services/api/src/sparks/sparks.service.ts`
- Create: `services/api/src/topics/topics.service.ts`
- Create: `services/api/src/health-data/health-data.service.ts`
- Create: `services/api/src/alerts/alerts.service.ts`
- Test: `services/api/test/care-flow.e2e-spec.ts`

**Interfaces:**
- Produces: `GET /sparks/current`, `GET /topics/today`, `POST /health-data`, `GET /alerts`.

- [ ] **Step 1: Write care-flow tests**

```ts
expect(spark.body.streakDays).toBe(1);
expect(alert.body.message).toContain('请联系医生');
expect(alert.body.message).not.toContain('诊断');
```

- [ ] **Step 2: Run the tests and confirm failure**

Run: `npm.cmd test -- care-flow.e2e-spec.ts`
Expected: FAIL before care modules exist.

- [ ] **Step 3: Implement the approved business rules**

Light the spark when the elder completes at least one task and the child is active on the same local date; generate deterministic template topics; store confirmed readings; create only L1/L2 care reminders in V1.

- [ ] **Step 4: Run care-flow tests**

Run: `npm.cmd test -- care-flow.e2e-spec.ts`
Expected: PASS.

- [ ] **Step 5: Commit care services**

```bash
git add services/api/src/sparks services/api/src/topics services/api/src/health-data services/api/src/alerts services/api/test/care-flow.e2e-spec.ts services/api/prisma
git commit -m "feat: add spark topics and care alerts"
```

### Task 5: Privacy operations, adapters, OpenAPI, and deployment verification

**Files:**
- Create: `services/api/src/privacy/privacy.service.ts`
- Create: `services/api/src/integrations/notification-adapter.ts`
- Create: `services/api/src/integrations/device-adapter.ts`
- Create: `services/api/src/integrations/fake-notification.adapter.ts`
- Create: `services/api/src/integrations/fake-device.adapter.ts`
- Create: `services/api/Dockerfile`
- Create: `services/api/README.md`
- Test: `services/api/test/privacy.e2e-spec.ts`

**Interfaces:**
- Produces: `GET /privacy/export`, `DELETE /privacy/account`, `/docs` OpenAPI UI, `NotificationAdapter`, and `DeviceAdapter`.

- [ ] **Step 1: Write export and deletion tests**

```ts
expect(exportResponse.body.family).toBeDefined();
expect(deleteResponse.body.deleteAfter).toMatch(/^\d{4}-\d{2}-\d{2}/);
```

- [ ] **Step 2: Run privacy tests**

Run: `npm.cmd test -- privacy.e2e-spec.ts`
Expected: FAIL before privacy operations exist.

- [ ] **Step 3: Implement privacy and adapter boundaries**

Export the authenticated user's scoped data; schedule erasure exactly 30 days after account deletion; expose fake notification and device adapters in local development.

- [ ] **Step 4: Run full backend verification**

Run: `npm.cmd run lint; npm.cmd test; npm.cmd run build`
Expected: all checks PASS and TypeScript build succeeds.

- [ ] **Step 5: Commit the deployable backend**

```bash
git add services/api docker-compose.yml
git commit -m "feat: complete deployable fubao api"
```
