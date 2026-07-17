export interface PushNotification {
  deviceToken: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface NotificationAdapter {
  send(notification: PushNotification): Promise<{ accepted: boolean; id: string }>;
}

export const NOTIFICATION_ADAPTER = Symbol('NOTIFICATION_ADAPTER');
