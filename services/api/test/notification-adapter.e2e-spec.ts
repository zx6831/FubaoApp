import { Test } from '@nestjs/testing';
import { ConfigModule } from '@nestjs/config';
import { FakeNotificationAdapter } from '../src/integrations/fake-notification.adapter';
import { IntegrationsModule } from '../src/integrations/integrations.module';
import { NOTIFICATION_ADAPTER, NotificationAdapter } from '../src/integrations/notification.adapter';
import { FakeSmsAdapter } from '../src/integrations/fake-sms.adapter';
import { SMS_ADAPTER, SmsAdapter } from '../src/integrations/sms.adapter';

describe('notification adapter', () => {
  it('uses a deterministic in-memory adapter without production APNs credentials', async () => {
    const module = await Test.createTestingModule({
      imports: [ConfigModule.forRoot({ ignoreEnvFile: true }), IntegrationsModule],
    }).compile();
    const adapter = module.get<NotificationAdapter>(NOTIFICATION_ADAPTER);
    const fake = module.get(FakeNotificationAdapter);
    const result = await adapter.send({
      deviceToken: 'local-device-token',
      title: '任务提醒',
      body: '该记录血压了',
    });
    expect(result.accepted).toBe(true);
    expect(fake.delivered).toHaveLength(1);
    expect(fake.delivered[0].body).toBe('该记录血压了');
    const sms = module.get<SmsAdapter>(SMS_ADAPTER);
    const fakeSms = module.get(FakeSmsAdapter);
    await sms.sendCode('13800000000', '2468');
    expect(fakeSms.delivered.get('13800000000')).toBe('2468');
    await module.close();
  });
});
