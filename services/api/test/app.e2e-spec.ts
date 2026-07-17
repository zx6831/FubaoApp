import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request = require('supertest');
import { AppModule } from '../src/app.module';

describe('Fubao API', () => {
  let app: INestApplication;
  let childToken: string;
  let elderToken: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api');
    await app.init();

    const login = async (phone: string, role: 'child' | 'elder') => {
      await request(app.getHttpServer()).post('/api/auth/request-code').send({ phone }).expect(201);
      const response = await request(app.getHttpServer())
        .post('/api/auth/verify-code')
        .send({ phone, code: '2468', role })
        .expect(201);
      return response.body.data.accessToken as string;
    };
    childToken = await login('13800000101', 'child');
    elderToken = await login('13800000102', 'elder');
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
    await request(app.getHttpServer()).post('/api/families').set('Authorization', `Bearer ${childToken}`).expect(201);
    const invitation = await request(app.getHttpServer())
      .post('/api/families/invitations')
      .set('Authorization', `Bearer ${childToken}`)
      .expect(201);
    expect(invitation.body.data.code).toMatch(/^\d{4}$/);

    const joined = await request(app.getHttpServer())
      .post('/api/families/join')
      .set('Authorization', `Bearer ${elderToken}`)
      .send({ code: invitation.body.data.code })
      .expect(201);
    expect(joined.body.data.role).toBe('elder');
  });

  it('prevents a child from completing an elder task', async () => {
    await request(app.getHttpServer())
      .post('/api/tasks/medicine/complete')
      .set('Authorization', `Bearer ${childToken}`)
      .set('Idempotency-Key', 'medicine-demo')
      .send({})
      .expect(403);
  });

  it('creates a care reminder without diagnosis wording', async () => {
    await request(app.getHttpServer()).post('/api/health-data').set('Authorization', `Bearer ${childToken}`).send({ type: 'bloodPressure', systolic: 168, diastolic: 102, confirmedByUser: true }).expect(201);
    const alerts = await request(app.getHttpServer()).get('/api/alerts').set('Authorization', `Bearer ${childToken}`).expect(200);
    expect(alerts.body.data.items[0].level).toBe('L2');
    expect(alerts.body.data.items[0].message).toContain('联系医生');
    expect(alerts.body.data.items[0].message).not.toContain('诊断为');
  });

  it('exports scoped demo data and schedules 30-day deletion', async () => {
    const exported = await request(app.getHttpServer()).get('/api/privacy/export').set('Authorization', `Bearer ${childToken}`).expect(200);
    expect(exported.body.data.family.id).toBe('family-demo');
    const deletion = await request(app.getHttpServer()).delete('/api/privacy/account').set('Authorization', `Bearer ${childToken}`).expect(200);
    const days = (Date.parse(deletion.body.data.deleteAfter) - Date.now()) / 86400000;
    expect(days).toBeGreaterThan(29.9);
  });
});
