import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request = require('supertest');
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/common/configure-app';
import { FakeNotificationAdapter } from '../src/integrations/fake-notification.adapter';

describe('Health readings, care alerts, and family spark', () => {
  let app: INestApplication;
  let childToken: string;
  let elderToken: string;
  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });
  const today = () => new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Shanghai', year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(new Date());

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    const login = async (phone: string, role: 'child' | 'elder') => {
      await request(app.getHttpServer()).post('/api/auth/request-code').send({ phone }).expect(201);
      const response = await request(app.getHttpServer()).post('/api/auth/verify-code')
        .send({ phone, code: '2468', role }).expect(201);
      return response.body.data.accessToken as string;
    };
    childToken = await login('13800000601', 'child');
    elderToken = await login('13800000602', 'elder');
    await request(app.getHttpServer()).post('/api/families').set(auth(childToken)).expect(201);
    const invitation = await request(app.getHttpServer()).post('/api/families/invitations').set(auth(childToken)).expect(201);
    await request(app.getHttpServer()).post('/api/families/join').set(auth(elderToken))
      .send({ code: invitation.body.data.code }).expect(201);
    await request(app.getHttpServer()).post('/api/notifications/device-token').set(auth(childToken))
      .send({ token: 'b'.repeat(64), platform: 'ios', environment: 'dev' }).expect(201);
  });

  afterAll(async () => app.close());

  it('requires confirmation and stores typed health readings', async () => {
    await request(app.getHttpServer()).post('/api/health-data').set(auth(elderToken))
      .send({ type: 'weight', value: 58.5 }).expect(400);
    const created = await request(app.getHttpServer()).post('/api/health-data').set(auth(elderToken))
      .send({ type: 'weight', value: 58.5, confirmedByUser: true }).expect(201);
    expect(created.body.data.reading).toMatchObject({ metric: 'weight', value: { value: 58.5, unit: 'kg' } });
    expect(created.body.data.alert).toBeNull();
    const id = created.body.data.reading.id as string;
    await request(app.getHttpServer()).get(`/api/health-data/${id}`).set(auth(childToken)).expect(200)
      .expect(({ body }) => expect(body.data.id).toBe(id));
  });

  it('deduplicates the same alert level for 24 hours and supports handling', async () => {
    for (const systolic of [168, 172]) {
      await request(app.getHttpServer()).post('/api/health-data').set(auth(elderToken))
        .send({ type: 'bloodPressure', systolic, diastolic: 102, confirmedByUser: true }).expect(201);
    }
    const alerts = await request(app.getHttpServer()).get('/api/alerts').set(auth(childToken)).expect(200);
    const bloodPressureAlerts = alerts.body.data.items.filter((item: { metric: string }) => item.metric === 'bloodPressure');
    expect(bloodPressureAlerts).toHaveLength(1);
    expect(bloodPressureAlerts[0].level).toBe('L2');
    const alertId = bloodPressureAlerts[0].id as string;
    const messages = await request(app.getHttpServer()).get('/api/messages?type=alert')
      .set(auth(childToken)).expect(200);
    expect(messages.body.data.items).toHaveLength(1);
    expect(messages.body.data.items[0].payload.alertId).toBe(alertId);
    const delivered = app.get(FakeNotificationAdapter).delivered
      .filter((item) => item.data?.alertId === alertId);
    expect(delivered).toHaveLength(1);
    await request(app.getHttpServer()).patch(`/api/alerts/${alertId}`).set(auth(childToken))
      .send({ status: 'closed' }).expect(400);
    await request(app.getHttpServer()).patch(`/api/alerts/${alertId}`).set(auth(childToken))
      .send({ status: 'closed', closeReason: '已电话确认并安排复测' }).expect(200)
      .expect(({ body }) => expect(body.data.status).toBe('closed'));
  });

  it('counts health recording as elder activity and lights after child activity', async () => {
    const child = await request(app.getHttpServer()).post('/api/sparks/activity').set(auth(childToken)).expect(201);
    expect(child.body.data).toMatchObject({ lit: true, childActive: true, elderActive: true, streakDays: 1 });
    const elder = await request(app.getHttpServer()).post('/api/sparks/activity').set(auth(elderToken)).expect(201);
    expect(elder.body.data).toMatchObject({ lit: true, childActive: true, elderActive: true, streakDays: 1 });
    const history = await request(app.getHttpServer())
      .get(`/api/sparks/history?from=${today()}&to=${today()}`).set(auth(childToken)).expect(200);
    expect(history.body.data.items).toEqual([
      { date: today(), childActive: true, elderActive: true, lit: true },
    ]);
  });
});
