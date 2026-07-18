export interface SmsAdapter {
  sendCode(phone: string, code: string): Promise<{ accepted: boolean }>;
}

export const SMS_ADAPTER = Symbol('SMS_ADAPTER');
