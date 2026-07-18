import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ConfigModule } from '@nestjs/config';
import { ApnsNotificationAdapter } from './apns-notification.adapter';
import { FakeNotificationAdapter } from './fake-notification.adapter';
import { NOTIFICATION_ADAPTER } from './notification.adapter';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { FakeSmsAdapter } from './fake-sms.adapter';
import { HttpSmsAdapter } from './http-sms.adapter';
import { SMS_ADAPTER } from './sms.adapter';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';

@Global()
@Module({
  imports: [ConfigModule, InfrastructureModule],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    FakeSmsAdapter,
    HttpSmsAdapter,
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
    {
      provide: SMS_ADAPTER,
      inject: [ConfigService, FakeSmsAdapter, HttpSmsAdapter],
      useFactory: (config: ConfigService, fake: FakeSmsAdapter, http: HttpSmsAdapter) =>
        config.get<string>('SMS_MODE') === 'http' ? http : fake,
    },
  ],
  exports: [NOTIFICATION_ADAPTER, SMS_ADAPTER, NotificationsService, FakeNotificationAdapter, FakeSmsAdapter],
})
export class IntegrationsModule {}
