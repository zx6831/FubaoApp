import { NotificationsService } from '../src/integrations/notifications.service';

describe('push token registration', () => {
  it('associates and removes a token for the authenticated user in memory mode', async () => {
    const service = new NotificationsService({ isEnabled: () => false } as any);
    const user = { sub: '11111111-1111-1111-1111-111111111111', role: 'child' as const };
    const token = 'a'.repeat(64);
    await expect(service.register(user, {
      token,
      platform: 'ios',
      environment: 'dev',
    })).resolves.toMatchObject({ registered: true });
    await expect(service.unregister(user, token)).resolves.toEqual({ removed: true });
  });
});
