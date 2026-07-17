import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request = require('supertest');
import { AppModule } from '../src/app.module';

describe('API contract', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api');
    await app.init();
  });

  afterAll(async () => app.close());

  it('wraps successful responses in the public envelope', async () => {
    await request(app.getHttpServer()).get('/api/health').expect(200, {
      code: 0,
      msg: 'success',
      data: { status: 'ok', service: 'fubao-api' },
    });
  });

  it('wraps errors and rejects an invalid invitation code', async () => {
    const phone = '13800000201';
    await request(app.getHttpServer()).post('/api/auth/request-code').send({ phone }).expect(201);
    const login = await request(app.getHttpServer())
      .post('/api/auth/verify-code')
      .send({ phone, code: '2468', role: 'elder' })
      .expect(201);
    const response = await request(app.getHttpServer())
      .post('/api/families/join')
      .set('Authorization', `Bearer ${login.body.data.accessToken}`)
      .send({ code: '12' })
      .expect(400);

    expect(response.body).toEqual({
      code: 400,
      msg: expect.any(String),
      data: null,
    });
  });
});
