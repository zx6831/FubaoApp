import { Injectable } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { NotificationAdapter, PushNotification } from './notification.adapter';

@Injectable()
export class FakeNotificationAdapter implements NotificationAdapter {
  readonly delivered: Array<PushNotification & { id: string; sentAt: Date }> = [];

  async send(notification: PushNotification) {
    const id = randomUUID();
    this.delivered.push({ ...notification, id, sentAt: new Date() });
    return { accepted: true, id };
  }
}
