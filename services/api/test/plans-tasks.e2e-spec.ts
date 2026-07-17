import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request = require('supertest');
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/common/configure-app';

describe('Plans and daily task lifecycle', () => {
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
      const response = await request(app.getHttpServer())
        .post('/api/auth/verify-code')
        .send({ phone, code: '2468', role })
        .expect(201);
      return response.body.data.accessToken as string;
    };
    childToken = await login('13800000501', 'child');
    elderToken = await login('13800000502', 'elder');
    await request(app.getHttpServer()).post('/api/families').set(auth(childToken)).expect(201);
    const invitation = await request(app.getHttpServer())
      .post('/api/families/invitations').set(auth(childToken)).expect(201);
    await request(app.getHttpServer())
      .post('/api/families/join').set(auth(elderToken))
      .send({ code: invitation.body.data.code }).expect(201);
  });

  afterAll(async () => app.close());

  it('creates a scheduled plan and exposes the same daily task to both roles', async () => {
    await request(app.getHttpServer())
      .post('/api/plans')
      .set(auth(elderToken))
      .send({
        kind: 'bloodPressure', title: '血压管理', startsOn: today(), timezone: 'Asia/Shanghai',
        schedule: { time: '08:30', daysOfWeek: [1, 2, 3, 4, 5, 6, 7] },
      })
      .expect(403);

    const created = await request(app.getHttpServer())
      .post('/api/plans')
      .set(auth(childToken))
      .send({
        kind: 'bloodPressure',
        title: '血压管理',
        subtitle: '记录血压，关注变化',
        startsOn: today(),
        timezone: 'Asia/Shanghai',
        schedule: { time: '08:30', daysOfWeek: [1, 2, 3, 4, 5, 6, 7] },
        enrollmentData: { target: '按时测量' },
      })
      .expect(201);
    expect(created.body.data).toMatchObject({ kind: 'bloodPressure', status: 'active' });

    const elderTasks = await request(app.getHttpServer())
      .get(`/api/tasks?date=${today()}`).set(auth(elderToken)).expect(200);
    expect(elderTasks.body.data.progress).toEqual({ total: 1, completed: 0, skipped: 0, pending: 1 });
    expect(elderTasks.body.data.items[0]).toMatchObject({ title: '血压管理', status: 'pending' });

    const childTasks = await request(app.getHttpServer())
      .get('/api/tasks/today').set(auth(childToken)).expect(200);
    expect(childTasks.body.data.items[0].id).toBe(elderTasks.body.data.items[0].id);
  });

  it('records completion idempotently and synchronizes progress to child', async () => {
    const tasks = await request(app.getHttpServer()).get('/api/tasks/today').set(auth(elderToken)).expect(200);
    const taskId = tasks.body.data.items[0].id as string;
    const key = `test-complete-${taskId}`;

    const completed = await request(app.getHttpServer())
      .post(`/api/tasks/${taskId}/complete`)
      .set(auth(elderToken))
      .set('Idempotency-Key', key)
      .send({ data: { systolic: 128, diastolic: 82 } })
      .expect(201);
    expect(completed.body.data).toMatchObject({ status: 'completed', record: { data: { systolic: 128, diastolic: 82 } } });

    await request(app.getHttpServer())
      .post(`/api/tasks/${taskId}/complete`)
      .set(auth(elderToken))
      .set('Idempotency-Key', key)
      .send({ data: { systolic: 999 } })
      .expect(201)
      .expect(({ body }) => expect(body.data.record.data.systolic).toBe(128));

    const synced = await request(app.getHttpServer()).get('/api/tasks/today').set(auth(childToken)).expect(200);
    expect(synced.body.data.progress).toEqual({ total: 1, completed: 1, skipped: 0, pending: 0 });
  });

  it('records skipped tasks, sends simulated TTS, and preserves ended plans', async () => {
    const created = await request(app.getHttpServer())
      .post('/api/plans').set(auth(childToken))
      .send({
        kind: 'medicine', title: '晚间用药', startsOn: today(), timezone: 'Asia/Shanghai',
        schedule: { time: '20:00', daysOfWeek: [1, 2, 3, 4, 5, 6, 7] },
      }).expect(201);
    const planId = created.body.data.id as string;
    const tasks = await request(app.getHttpServer()).get('/api/tasks/today').set(auth(elderToken)).expect(200);
    const medicine = tasks.body.data.items.find((item: { planId: string }) => item.planId === planId);

    await request(app.getHttpServer())
      .post(`/api/tasks/${medicine.id}/skip`).set(auth(elderToken))
      .set('Idempotency-Key', `test-skip-${medicine.id}`).send({}).expect(201)
      .expect(({ body }) => expect(body.data.status).toBe('skipped'));

    const discovered = await request(app.getHttpServer()).post('/api/devices/discover').set(auth(childToken)).expect(201);
    await request(app.getHttpServer()).post('/api/devices/activate').set(auth(childToken))
      .send({ serialNumber: discovered.body.data.devices[0].serialNumber, networkName: 'Fubao-Test-WiFi' }).expect(201);
    await request(app.getHttpServer()).post(`/api/tasks/${medicine.id}/remind`).set(auth(childToken)).expect(201)
      .expect(({ body }) => expect(body.data).toMatchObject({ accepted: true, channel: 'simulatedTts' }));

    await request(app.getHttpServer()).patch(`/api/plans/${planId}/status`).set(auth(childToken))
      .send({ status: 'paused' }).expect(200)
      .expect(({ body }) => expect(body.data.status).toBe('paused'));
    await request(app.getHttpServer()).patch(`/api/plans/${planId}/status`).set(auth(childToken))
      .send({ status: 'ended' }).expect(200);
    await request(app.getHttpServer()).patch(`/api/plans/${planId}/status`).set(auth(childToken))
      .send({ status: 'active' }).expect(409);

    const history = await request(app.getHttpServer())
      .get(`/api/tasks/history?from=${today()}&to=${today()}`).set(auth(childToken)).expect(200);
    expect(history.body.data.items).toHaveLength(2);
    await request(app.getHttpServer()).delete(`/api/plans/${planId}`).set(auth(childToken)).expect(404);
  });
});
