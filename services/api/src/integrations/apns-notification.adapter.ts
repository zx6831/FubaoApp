import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { connect } from 'node:http2';
import { randomUUID } from 'node:crypto';
import { NotificationAdapter, PushNotification } from './notification.adapter';

@Injectable()
export class ApnsNotificationAdapter implements NotificationAdapter {
  constructor(private readonly config: ConfigService) {}

  async send(notification: PushNotification): Promise<{ accepted: boolean; id: string }> {
    const topic = this.config.get<string>('APNS_TOPIC');
    const token = this.config.get<string>('APNS_AUTH_TOKEN');
    const host = this.config.get<string>('APNS_HOST') ?? 'https://api.push.apple.com';
    if (!topic || !token) throw new ServiceUnavailableException('APNs 生产凭据尚未配置');
    const id = randomUUID();
    const client = connect(host);
    try {
      return await new Promise((resolve, reject) => {
        const request = client.request({
          ':method': 'POST',
          ':path': `/3/device/${notification.deviceToken}`,
          authorization: `bearer ${token}`,
          'apns-topic': topic,
          'apns-push-type': 'alert',
          'apns-id': id,
        });
        let status = 0;
        let response = '';
        request.setEncoding('utf8');
        request.on('response', (headers) => {
          status = Number(headers[':status'] ?? 0);
        });
        request.on('data', (chunk) => (response += chunk));
        request.on('error', reject);
        request.on('end', () => {
          if (status >= 200 && status < 300) resolve({ accepted: true, id });
          else reject(new ServiceUnavailableException(`APNs ${status}: ${response}`));
        });
        request.end(JSON.stringify({
          aps: { alert: { title: notification.title, body: notification.body }, sound: 'default' },
          ...notification.data,
        }));
      });
    } finally {
      client.close();
    }
  }
}
