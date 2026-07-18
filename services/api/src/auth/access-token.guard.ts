import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { IS_PUBLIC_KEY } from './public.decorator';
import { MemoryIdentityState } from './memory-identity-state';
import { SecurityService } from './security.service';
import { PrismaService } from '../infrastructure/prisma.service';

@Injectable()
export class AccessTokenGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly security: SecurityService,
    private readonly prisma: PrismaService,
    private readonly memory: MemoryIdentityState,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [context.getHandler(), context.getClass()])) return true;
    const request = context.switchToHttp().getRequest<Request>() as Request & { user?: unknown };
    const authorization = request.headers.authorization;
    if (!authorization?.startsWith('Bearer ')) throw new UnauthorizedException('请先登录');
    const user = this.security.verifyAccessToken(authorization.slice(7));
    const active = this.prisma.isEnabled()
      ? await this.prisma.user.findFirst({ where: { id: user.sub, deletedAt: null }, select: { id: true, deletedAt: true } })
      : this.memory.usersById.get(user.sub);
    if (!active || active.deletedAt) throw new UnauthorizedException('账号已注销或登录状态已失效');
    request.user = user;
    return true;
  }
}
