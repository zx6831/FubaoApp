import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request = require('supertest');
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/common/configure-app';
import { EngagementService } from '../src/engagement/engagement.service';

describe('Topics, messages, feedback, and privacy', () => {
  let app: INestApplication; let token: string; let userId: string;
  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication(); configureApp(app); await app.init();
    await request(app.getHttpServer()).post('/api/auth/request-code').send({ phone: '13800000701' }).expect(201);
    const login = await request(app.getHttpServer()).post('/api/auth/verify-code').send({ phone: '13800000701', code: '2468', role: 'child' }).expect(201);
    token = login.body.data.accessToken; userId = login.body.data.user.id; await request(app.getHttpServer()).post('/api/families').set('Authorization', `Bearer ${token}`).expect(201);
  });
  afterAll(async () => app.close());
  const auth = () => ({ Authorization: `Bearer ${token}` });

  it('generates topics and records copy events', async () => {
    const topics = await request(app.getHttpServer()).get('/api/topics/today').set(auth()).expect(200);
    expect(topics.body.data.items).toHaveLength(2);
    await request(app.getHttpServer()).post(`/api/topics/${topics.body.data.items[0].id}/copied`).set(auth()).expect(201)
      .expect(({ body }) => expect(body.data.copied).toBe(true));
  });

  it('provides typed messages and marks them read', async () => {
    const messages = await request(app.getHttpServer()).get('/api/messages').set(auth()).expect(200);
    expect(messages.body.data.items.map((item: { type: string }) => item.type)).toEqual(expect.arrayContaining(['weeklyReport', 'insight', 'system']));
    const id = messages.body.data.items[0].id;
    await request(app.getHttpServer()).patch(`/api/messages/${id}/read`).set(auth()).expect(200)
      .expect(({ body }) => expect(body.data.readAt).toBeTruthy());
  });

  it('submits feedback, exports data, and executes the 30-day deletion queue', async () => {
    await request(app.getHttpServer()).post('/api/feedback').set(auth()).send({ content: '希望增加更清晰的任务说明' }).expect(201);
    const exported = await request(app.getHttpServer()).get('/api/privacy/export').set(auth()).expect(200);
    expect(exported.body.data).toHaveProperty('healthReadings');
    await request(app.getHttpServer()).delete('/api/privacy/account').set(auth()).expect(200);
    await request(app.getHttpServer()).get('/api/privacy/account').set(auth()).expect(200)
      .expect(({ body }) => expect(body.data.status).toBe('scheduled'));
    const result = await app.get(EngagementService).processDueDeletionRequests(new Date(Date.now() + 31 * 86400000));
    expect(result.processed).toBe(1);
    await request(app.getHttpServer()).get('/api/privacy/account').set(auth()).expect(401);

    await request(app.getHttpServer()).post('/api/auth/request-code').send({ phone: '13800000701' }).expect(201);
    const newLogin = await request(app.getHttpServer()).post('/api/auth/verify-code')
      .send({ phone: '13800000701', code: '2468', role: 'child' }).expect(201);
    expect(newLogin.body.data.user.id).not.toBe(userId);
  });
});
