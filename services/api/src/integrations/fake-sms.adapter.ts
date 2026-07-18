import { Injectable } from '@nestjs/common';
import { SmsAdapter } from './sms.adapter';

@Injectable()
export class FakeSmsAdapter implements SmsAdapter {
  readonly delivered = new Map<string, string>();

  async sendCode(phone: string, code: string) {
    this.delivered.set(phone, code);
    return { accepted: true };
  }
}
