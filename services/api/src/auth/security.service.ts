import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, createHmac, createHash, randomBytes, timingSafeEqual } from 'node:crypto';
import { AccessTokenPayload, AppRole } from './auth.types';

@Injectable()
export class SecurityService {
  private readonly accessSecret: string;
  private readonly hashPepper: string;
  private readonly encryptionKey: Buffer;

  constructor(config: ConfigService) {
    this.accessSecret = config.getOrThrow<string>('JWT_ACCESS_SECRET');
    this.hashPepper = config.getOrThrow<string>('HASH_PEPPER');
    this.encryptionKey = createHash('sha256').update(config.getOrThrow<string>('DATA_ENCRYPTION_KEY')).digest();
  }

  hash(value: string): string {
    return createHmac('sha256', this.hashPepper).update(value).digest('hex');
  }

  encrypt(value: string): string {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    const ciphertext = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
    return [iv, cipher.getAuthTag(), ciphertext].map((part) => part.toString('base64url')).join('.');
  }

  decrypt(value: string): string {
    const [iv, tag, ciphertext] = value.split('.').map((part) => Buffer.from(part, 'base64url'));
    const decipher = createDecipheriv('aes-256-gcm', this.encryptionKey, iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(ciphertext), decipher.final()]).toString('utf8');
  }

  createRefreshToken(): string {
    return randomBytes(48).toString('base64url');
  }

  signAccessToken(userId: string, role: AppRole): { token: string; expiresAt: string } {
    const now = Math.floor(Date.now() / 1000);
    const payload: AccessTokenPayload = { sub: userId, role, type: 'access', iat: now, exp: now + 15 * 60 };
    const encodedHeader = this.encode({ alg: 'HS256', typ: 'JWT' });
    const encodedPayload = this.encode(payload);
    const content = `${encodedHeader}.${encodedPayload}`;
    const signature = createHmac('sha256', this.accessSecret).update(content).digest('base64url');
    return { token: `${content}.${signature}`, expiresAt: new Date(payload.exp * 1000).toISOString() };
  }

  verifyAccessToken(token: string): AccessTokenPayload {
    const parts = token.split('.');
    if (parts.length !== 3) throw new UnauthorizedException('登录状态无效');
    const content = `${parts[0]}.${parts[1]}`;
    const expected = createHmac('sha256', this.accessSecret).update(content).digest();
    const actual = Buffer.from(parts[2], 'base64url');
    if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) {
      throw new UnauthorizedException('登录状态无效');
    }
    try {
      const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8')) as AccessTokenPayload;
      if (payload.type !== 'access' || payload.exp <= Math.floor(Date.now() / 1000) || !['child', 'elder'].includes(payload.role)) {
        throw new Error('invalid payload');
      }
      return payload;
    } catch {
      throw new UnauthorizedException('登录状态已失效，请重新登录');
    }
  }

  private encode(value: object): string {
    return Buffer.from(JSON.stringify(value)).toString('base64url');
  }
}
