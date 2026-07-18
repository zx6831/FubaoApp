import { ConflictException, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomInt, randomUUID } from 'node:crypto';
import { PrismaService } from '../infrastructure/prisma.service';
import { RedisService } from '../infrastructure/redis.service';
import { AppRole, PublicUser } from './auth.types';
import { MemoryIdentityState, MemoryUser } from './memory-identity-state';
import { SecurityService } from './security.service';
import { SMS_ADAPTER, SmsAdapter } from '../integrations/sms.adapter';

const VERIFICATION_TTL_SECONDS = 5 * 60;
const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;

@Injectable()
export class AuthService {
  private readonly isProduction: boolean;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly memory: MemoryIdentityState,
    private readonly security: SecurityService,
    @Inject(SMS_ADAPTER) private readonly sms: SmsAdapter,
  ) {
    this.isProduction = config.get('NODE_ENV') === 'production';
  }

  async requestCode(phone: string) {
    const reviewPhone = this.config.get<string>('REVIEW_PHONE');
    const reviewCode = this.config.get<string>('REVIEW_CODE');
    const isReviewAccount = this.isProduction && phone === reviewPhone && reviewCode;
    const code = isReviewAccount
      ? reviewCode
      : this.isProduction
        ? randomInt(100000, 1000000).toString()
        : '2468';
    const expiresAt = new Date(Date.now() + VERIFICATION_TTL_SECONDS * 1000);
    const key = this.verificationKey(phone);
    if (this.redis.isEnabled()) {
      await this.redis.connection().set(key, code, 'EX', VERIFICATION_TTL_SECONDS);
    } else {
      this.memory.verificationCodes.set(key, { code, expiresAt });
    }
    await this.sms.sendCode(phone, code);
    return {
      expiresAt: expiresAt.toISOString(),
      ...(this.isProduction ? {} : { testCode: code }),
    };
  }

  async verifyCode(phone: string, code: string, role: AppRole) {
    if (!(await this.consumeCode(phone, code))) throw new UnauthorizedException('验证码错误或已过期');
    const user = await this.findOrCreateUser(phone, role);
    return this.issueSession(user);
  }

  async refresh(refreshToken: string) {
    const tokenHash = this.security.hash(refreshToken);
    if (this.prisma.isEnabled()) {
      const session = await this.prisma.session.findUnique({ where: { refreshTokenHash: tokenHash }, include: { user: true } });
      if (!session || session.revokedAt || session.expiresAt <= new Date() || session.user.deletedAt) {
        throw new UnauthorizedException('登录状态已失效，请重新登录');
      }
      const revoked = await this.prisma.session.updateMany({
        where: { id: session.id, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      if (revoked.count !== 1) throw new UnauthorizedException('登录状态已失效，请重新登录');
      return this.issueSession(this.toPublicUser(session.user));
    }

    const session = this.memory.sessions.get(tokenHash);
    if (!session || session.revokedAt || session.expiresAt <= new Date()) {
      throw new UnauthorizedException('登录状态已失效，请重新登录');
    }
    session.revokedAt = new Date();
    const user = this.memory.usersById.get(session.userId);
    if (!user) throw new UnauthorizedException('用户不存在');
    return this.issueSession(this.toPublicUser(user));
  }

  async logout(userId: string, refreshToken: string) {
    const tokenHash = this.security.hash(refreshToken);
    if (this.prisma.isEnabled()) {
      await this.prisma.session.updateMany({
        where: { userId, refreshTokenHash: tokenHash, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    } else {
      const session = this.memory.sessions.get(tokenHash);
      if (session?.userId === userId) session.revokedAt = new Date();
    }
    return { loggedOut: true };
  }

  private async consumeCode(phone: string, submitted: string): Promise<boolean> {
    const key = this.verificationKey(phone);
    if (this.redis.isEnabled()) {
      const expected = await this.redis.connection().get(key);
      if (expected !== submitted) return false;
      await this.redis.connection().del(key);
      return true;
    }
    const entry = this.memory.verificationCodes.get(key);
    if (!entry || entry.expiresAt <= new Date() || entry.code !== submitted) return false;
    this.memory.verificationCodes.delete(key);
    return true;
  }

  private async findOrCreateUser(phone: string, role: AppRole): Promise<PublicUser> {
    const phoneHash = this.security.hash(phone);
    if (this.prisma.isEnabled()) {
      const existing = await this.prisma.user.findUnique({ where: { phoneHash } });
      if (existing) {
        if (existing.role !== role) throw new ConflictException('该手机号已注册为另一种角色');
        return this.toPublicUser(existing);
      }
      const user = await this.prisma.user.create({
        data: {
          phoneHash,
          phoneCiphertext: this.security.encrypt(phone),
          nickname: role === 'child' ? '子女用户' : '长辈用户',
          role,
        },
      });
      return this.toPublicUser(user);
    }

    const existing = this.memory.usersByPhoneHash.get(phoneHash);
    if (existing) {
      if (existing.role !== role) throw new ConflictException('该手机号已注册为另一种角色');
      return this.toPublicUser(existing);
    }
    const user: MemoryUser = {
      id: randomUUID(),
      phoneHash,
      phoneCiphertext: this.security.encrypt(phone),
      nickname: role === 'child' ? '子女用户' : '长辈用户',
      role,
    };
    this.memory.usersByPhoneHash.set(phoneHash, user);
    this.memory.usersById.set(user.id, user);
    return this.toPublicUser(user);
  }

  private async issueSession(user: PublicUser) {
    const refreshToken = this.security.createRefreshToken();
    const refreshTokenHash = this.security.hash(refreshToken);
    const refreshExpiresAt = new Date(Date.now() + REFRESH_TTL_MS);
    if (this.prisma.isEnabled()) {
      await this.prisma.session.create({ data: { userId: user.id, refreshTokenHash, expiresAt: refreshExpiresAt } });
    } else {
      this.memory.sessions.set(refreshTokenHash, { userId: user.id, refreshTokenHash, expiresAt: refreshExpiresAt, revokedAt: null });
    }
    const access = this.security.signAccessToken(user.id, user.role);
    return {
      accessToken: access.token,
      accessTokenExpiresAt: access.expiresAt,
      refreshToken,
      refreshTokenExpiresAt: refreshExpiresAt.toISOString(),
      user,
    };
  }

  private verificationKey(phone: string): string {
    return `auth:code:${this.security.hash(phone)}`;
  }

  private toPublicUser(user: { id: string; role: AppRole; nickname: string }): PublicUser {
    return { id: user.id, role: user.role, nickname: user.nickname };
  }
}
