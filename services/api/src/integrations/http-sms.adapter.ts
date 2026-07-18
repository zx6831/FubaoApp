import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SmsAdapter } from './sms.adapter';

@Injectable()
export class HttpSmsAdapter implements SmsAdapter {
  constructor(private readonly config: ConfigService) {}

  async sendCode(phone: string, code: string) {
    const url = this.config.get<string>('SMS_PROVIDER_URL');
    const token = this.config.get<string>('SMS_PROVIDER_TOKEN');
    if (!url || !token) throw new ServiceUnavailableException('短信供应商尚未配置');
    const response = await fetch(url, {
      method: 'POST',
      headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
      body: JSON.stringify({ phone, template: 'verification_code', parameters: { code } }),
    });
    if (!response.ok) throw new ServiceUnavailableException(`短信发送失败 (${response.status})`);
    return { accepted: true };
  }
}
