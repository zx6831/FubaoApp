import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request = require('supertest');
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/common/configure-app';

describe('Authentication and family binding', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterAll(async () => app.close());

  async function login(phone: string, role: 'child' | 'elder') {
    const requested = await request(app.getHttpServer())
      .post('/api/auth/request-code')
      .send({ phone })
      .expect(201);
    expect(requested.body.data.testCode).toBe('2468');

    const verified = await request(app.getHttpServer())
      .post('/api/auth/verify-code')
      .send({ phone, code: '2468', role })
      .expect(201);
    return verified.body.data as {
      accessToken: string;
      refreshToken: string;
      user: { id: string; role: string };
    };
  }

  it('creates and restores a rotating token session', async () => {
    const session = await login('13800000001', 'child');

    const refreshed = await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(200);
    expect(refreshed.body.data.refreshToken).not.toBe(session.refreshToken);

    await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(401);

    await request(app.getHttpServer())
      .post('/api/auth/logout')
      .set('Authorization', `Bearer ${refreshed.body.data.accessToken}`)
      .send({ refreshToken: refreshed.body.data.refreshToken })
      .expect(200);

    await request(app.getHttpServer())
      .post('/api/auth/refresh')
      .send({ refreshToken: refreshed.body.data.refreshToken })
      .expect(401);
  });

  it('binds one child and one elder through a 30-minute invitation', async () => {
    const child = await login('13800000002', 'child');
    const elder = await login('13800000003', 'elder');

    const family = await request(app.getHttpServer())
      .post('/api/families')
      .set('Authorization', `Bearer ${child.accessToken}`)
      .expect(201);
    expect(family.body.data.ownerId).toBe(child.user.id);

    const invitation = await request(app.getHttpServer())
      .post('/api/families/invitations')
      .set('Authorization', `Bearer ${child.accessToken}`)
      .expect(201);
    expect(invitation.body.data.code).toMatch(/^\d{4}$/);
    expect(Date.parse(invitation.body.data.expiresAt) - Date.now()).toBeGreaterThan(29 * 60 * 1000);

    const joined = await request(app.getHttpServer())
      .post('/api/families/join')
      .set('Authorization', `Bearer ${elder.accessToken}`)
      .send({ code: invitation.body.data.code })
      .expect(201);
    expect(joined.body.data.familyId).toBe(family.body.data.id);
    expect(joined.body.data.role).toBe('elder');

    const current = await request(app.getHttpServer())
      .get('/api/families/current')
      .set('Authorization', `Bearer ${elder.accessToken}`)
      .expect(200);
    expect(current.body.data.members).toHaveLength(2);

    await request(app.getHttpServer())
      .post('/api/families/invitations')
      .set('Authorization', `Bearer ${elder.accessToken}`)
      .expect(403);

    await request(app.getHttpServer())
      .post('/api/families/invitations')
      .set('Authorization', `Bearer ${child.accessToken}`)
      .expect(409);

    const left = await request(app.getHttpServer())
      .delete('/api/families/current/membership')
      .set('Authorization', `Bearer ${elder.accessToken}`)
      .expect(200);
    expect(left.body.data).toMatchObject({ left: true, sessionActive: true });
    await request(app.getHttpServer())
      .get('/api/families/current')
      .set('Authorization', `Bearer ${elder.accessToken}`)
      .expect(404);
  });

  it('rejects invalid verification codes and unauthenticated family access', async () => {
    await request(app.getHttpServer())
      .post('/api/auth/request-code')
      .send({ phone: '13800000004' })
      .expect(201);
    await request(app.getHttpServer())
      .post('/api/auth/verify-code')
      .send({ phone: '13800000004', code: '0000', role: 'child' })
      .expect(401);
    await request(app.getHttpServer()).post('/api/families').expect(401);
  });
});
