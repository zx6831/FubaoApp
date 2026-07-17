import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request = require('supertest');
import { AppModule } from '../src/app.module';

describe('Fubao API', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api');
    await app.init();
  });

  afterAll(async () => app.close());

  it('reports service health', async () => {
    await request(app.getHttpServer()).get('/api/health').expect(200, {
      code: 0,
      msg: 'success',
      data: { status: 'ok', service: 'fubao-api' },
    });
  });

  it('runs child login and family invitation flow', async () => {
    const login = await request(app.getHttpServer()).post('/api/auth/test-login').send({ role: 'child' }).expect(201);
    expect(login.body.data.accessToken).toBe('child-token');

    const invitation = await request(app.getHttpServer()).post('/api/families/invitations').expect(201);
    expect(invitation.body.data.code).toMatch(/^\d{4}$/);

    const joined = await request(app.getHttpServer()).post('/api/families/join').send({ code: invitation.body.data.code }).expect(201);
    expect(joined.body.data.role).toBe('elder');
  });

  it('completes a task idempotently', async () => {
    const first = await request(app.getHttpServer()).post('/api/tasks/medicine/complete').set('Idempotency-Key', 'medicine-demo').expect(201);
    const second = await request(app.getHttpServer()).post('/api/tasks/medicine/complete').set('Idempotency-Key', 'medicine-demo').expect(201);
    expect(second.body.data.completedAt).toBe(first.body.data.completedAt);
  });

  it('creates a care reminder without diagnosis wording', async () => {
    await request(app.getHttpServer()).post('/api/health-data').send({ type: 'bloodPressure', systolic: 168, diastolic: 102 }).expect(201);
    const alerts = await request(app.getHttpServer()).get('/api/alerts').expect(200);
    expect(alerts.body.data[0].level).toBe('L2');
    expect(alerts.body.data[0].message).toContain('联系医生');
    expect(alerts.body.data[0].message).not.toContain('诊断为');
  });

  it('exports scoped demo data and schedules 30-day deletion', async () => {
    const exported = await request(app.getHttpServer()).get('/api/privacy/export').expect(200);
    expect(exported.body.data.family.id).toBe('family-demo');
    const deletion = await request(app.getHttpServer()).delete('/api/privacy/account').expect(200);
    const days = (Date.parse(deletion.body.data.deleteAfter) - Date.now()) / 86400000;
    expect(days).toBeGreaterThan(29.9);
  });
});
