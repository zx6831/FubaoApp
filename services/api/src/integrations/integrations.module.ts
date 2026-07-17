import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ConfigModule } from '@nestjs/config';
import { ApnsNotificationAdapter } from './apns-notification.adapter';
import { FakeNotificationAdapter } from './fake-notification.adapter';
import { NOTIFICATION_ADAPTER } from './notification.adapter';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [
    FakeNotificationAdapter,
    ApnsNotificationAdapter,
    {
      provide: NOTIFICATION_ADAPTER,
      inject: [ConfigService, FakeNotificationAdapter, ApnsNotificationAdapter],
      useFactory: (
        config: ConfigService,
        fake: FakeNotificationAdapter,
        apns: ApnsNotificationAdapter,
      ) => config.get<string>('APNS_MODE') === 'apns' ? apns : fake,
    },
  ],
  exports: [NOTIFICATION_ADAPTER, FakeNotificationAdapter],
})
export class IntegrationsModule {}
