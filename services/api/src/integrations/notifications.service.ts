import { Injectable } from '@nestjs/common';
import { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../infrastructure/prisma.service';
import { PushTokenDto } from './dto/push-token.dto';

@Injectable()
export class NotificationsService {
  private readonly memory = new Map<string, PushTokenDto & { userId: string }>();

  constructor(private readonly prisma: PrismaService) {}

  async register(user: AuthenticatedUser, body: PushTokenDto) {
    if (this.prisma.isEnabled()) {
      const item = await this.prisma.pushToken.upsert({
        where: { token: body.token },
        create: { userId: user.sub, ...body },
        update: { userId: user.sub, platform: body.platform, environment: body.environment },
      });
      return { registered: true, id: item.id };
    }
    this.memory.set(body.token, { ...body, userId: user.sub });
    return { registered: true, id: body.token };
  }

  async unregister(user: AuthenticatedUser, token: string) {
    if (this.prisma.isEnabled()) {
      await this.prisma.pushToken.deleteMany({ where: { userId: user.sub, token } });
    } else if (this.memory.get(token)?.userId === user.sub) {
      this.memory.delete(token);
    }
    return { removed: true };
  }

  async tokensForUser(userId: string): Promise<string[]> {
    if (this.prisma.isEnabled()) {
      const items = await this.prisma.pushToken.findMany({
        where: { userId },
        select: { token: true },
      });
      return items.map((item) => item.token);
    }
    return [...this.memory.entries()]
      .filter(([, item]) => item.userId === userId)
      .map(([token]) => token);
  }
}
