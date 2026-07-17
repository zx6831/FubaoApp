import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request = require('supertest');
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/common/configure-app';

describe('Health profile and simulated device onboarding', () => {
  let app: INestApplication;
  let childToken: string;
  let elderToken: string;

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
    childToken = await login('13800000401', 'child');
    elderToken = await login('13800000402', 'elder');
    await request(app.getHttpServer()).post('/api/families').set('Authorization', `Bearer ${childToken}`).expect(201);
    const invitation = await request(app.getHttpServer())
      .post('/api/families/invitations')
      .set('Authorization', `Bearer ${childToken}`)
      .expect(201);
    await request(app.getHttpServer())
      .post('/api/families/join')
      .set('Authorization', `Bearer ${elderToken}`)
      .send({ code: invitation.body.data.code })
      .expect(201);
  });

  afterAll(async () => app.close());

  it('completes profile and simulated device activation', async () => {
    const auth = { Authorization: `Bearer ${childToken}` };
    const initial = await request(app.getHttpServer()).get('/api/onboarding/status').set(auth).expect(200);
    expect(initial.body.data).toMatchObject({ familyBound: true, profileComplete: false, deviceActive: false, complete: false });

    const profile = await request(app.getHttpServer())
      .put('/api/profiles/elder')
      .set(auth)
      .send({
        relativeName: '妈妈',
        heightCm: 162,
        weightKg: 58.5,
        chronicConditions: ['高血压'],
        medicationHistory: { summary: '遵医嘱用药' },
        medicalHistory: { summary: '无其他补充' },
        emergencyContact: '小雨 13800000401',
        consentConfirmed: true,
      })
      .expect(200);
    expect(profile.body.data.emergencyContact).toBe('小雨 13800000401');

    const discovered = await request(app.getHttpServer()).post('/api/devices/discover').set(auth).expect(201);
    const serialNumber = discovered.body.data.devices[0].serialNumber as string;
    expect(serialNumber).toMatch(/^FB-[A-Z0-9]{6}$/);

    const activated = await request(app.getHttpServer())
      .post('/api/devices/activate')
      .set(auth)
      .send({ serialNumber, networkName: 'Fubao-Test-WiFi' })
      .expect(201);
    expect(activated.body.data.status).toBe('online');

    const settings = await request(app.getHttpServer())
      .patch('/api/devices/settings')
      .set(auth)
      .send({ volume: 72, speechRate: 45, dndEnabled: true, dndStart: '21:30', dndEnd: '07:30' })
      .expect(200);
    expect(settings.body.data.volume).toBe(72);

    await request(app.getHttpServer())
      .patch('/api/devices/status')
      .set(auth)
      .send({ status: 'offline' })
      .expect(200)
      .expect(({ body }) => expect(body.data.status).toBe('offline'));

    const completed = await request(app.getHttpServer()).get('/api/onboarding/status').set(auth).expect(200);
    expect(completed.body.data.complete).toBe(true);
  });

  it('prevents elder-side device administration and retains data after unbind', async () => {
    await request(app.getHttpServer())
      .post('/api/devices/discover')
      .set('Authorization', `Bearer ${elderToken}`)
      .expect(403);

    const response = await request(app.getHttpServer())
      .delete('/api/devices/current')
      .set('Authorization', `Bearer ${childToken}`)
      .expect(200);
    const retentionDays = (Date.parse(response.body.data.dataRetainedUntil) - Date.now()) / 86400000;
    expect(retentionDays).toBeGreaterThan(89.9);
  });
});
