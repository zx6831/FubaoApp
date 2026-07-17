import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomInt, randomUUID } from 'node:crypto';
import { AuthenticatedUser } from '../auth/auth.types';
import { MemoryFamily, MemoryIdentityState } from '../auth/memory-identity-state';
import { SecurityService } from '../auth/security.service';
import { PrismaService } from '../infrastructure/prisma.service';

@Injectable()
export class FamilyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly memory: MemoryIdentityState,
    private readonly security: SecurityService,
  ) {}

  async create(user: AuthenticatedUser) {
    if (user.role !== 'child') throw new ForbiddenException('只有子女端可以创建家庭');
    if (this.prisma.isEnabled()) {
      const existing = await this.prisma.family.findFirst({
        where: { ownerId: user.sub, status: 'active' },
        include: { members: { where: { status: 'active' }, include: { user: true } } },
      });
      if (existing) return this.serialize(existing);
      const family = await this.prisma.family.create({
        data: {
          ownerId: user.sub,
          members: { create: { userId: user.sub, role: 'child' } },
        },
        include: { members: { where: { status: 'active' }, include: { user: true } } },
      });
      return this.serialize(family);
    }

    const existing = [...this.memory.families.values()].find((family) => family.ownerId === user.sub);
    if (existing) return existing;
    const owner = this.memory.usersById.get(user.sub);
    if (!owner) throw new NotFoundException('用户不存在');
    const family: MemoryFamily = {
      id: randomUUID(),
      ownerId: user.sub,
      members: [{ userId: user.sub, role: 'child', nickname: owner.nickname }],
    };
    this.memory.families.set(family.id, family);
    return family;
  }

  async current(user: AuthenticatedUser) {
    if (this.prisma.isEnabled()) {
      const membership = await this.prisma.familyMember.findFirst({
        where: { userId: user.sub, status: 'active', family: { status: 'active' } },
        include: { family: { include: { members: { where: { status: 'active' }, include: { user: true } } } } },
      });
      if (!membership) throw new NotFoundException('尚未加入家庭');
      return this.serialize(membership.family);
    }
    const family = [...this.memory.families.values()].find((item) => item.members.some((member) => member.userId === user.sub));
    if (!family) throw new NotFoundException('尚未加入家庭');
    return family;
  }

  async createInvitation(user: AuthenticatedUser) {
    if (user.role !== 'child') throw new ForbiddenException('只有子女端可以生成邀请码');
    const family = await this.current(user);
    if (family.ownerId !== user.sub) throw new ForbiddenException('只有家庭主账号可以生成邀请码');
    if (family.members.some((member: { role: string }) => member.role === 'elder')) {
      throw new ConflictException('当前家庭已绑定长辈账号');
    }
    const code = randomInt(1000, 10000).toString();
    const codeDigest = this.security.hash(`invitation:${code}`);
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000);
    if (this.prisma.isEnabled()) {
      await this.prisma.invitation.create({ data: { familyId: family.id, codeDigest, expiresAt } });
    } else {
      this.memory.invitations.set(codeDigest, { familyId: family.id, codeDigest, expiresAt, usedAt: null });
    }
    return { code, expiresAt: expiresAt.toISOString() };
  }

  async join(user: AuthenticatedUser, code: string) {
    if (user.role !== 'elder') throw new ForbiddenException('只有长辈端可以接受邀请');
    const codeDigest = this.security.hash(`invitation:${code}`);
    if (this.prisma.isEnabled()) {
      return this.prisma.$transaction(async (tx) => {
        const invitation = await tx.invitation.findUnique({
          where: { codeDigest },
          include: { family: { include: { members: { where: { status: 'active' } } } } },
        });
        if (!invitation || invitation.usedAt || invitation.expiresAt <= new Date() || invitation.family.status !== 'active') {
          throw new BadRequestException('邀请码无效或已过期');
        }
        const existing = await tx.familyMember.findFirst({ where: { userId: user.sub, status: 'active' } });
        if (existing) throw new ConflictException('该账号已加入家庭');
        if (invitation.family.members.some((member) => member.role === 'elder')) {
          throw new ConflictException('当前家庭已绑定长辈账号');
        }
        await tx.familyMember.create({ data: { familyId: invitation.familyId, userId: user.sub, role: 'elder' } });
        await tx.invitation.update({ where: { id: invitation.id }, data: { usedAt: new Date() } });
        return { joined: true, familyId: invitation.familyId, role: 'elder' as const };
      });
    }

    const invitation = this.memory.invitations.get(codeDigest);
    if (!invitation || invitation.usedAt || invitation.expiresAt <= new Date()) {
      throw new BadRequestException('邀请码无效或已过期');
    }
    if ([...this.memory.families.values()].some((family) => family.members.some((member) => member.userId === user.sub))) {
      throw new ConflictException('该账号已加入家庭');
    }
    const family = this.memory.families.get(invitation.familyId);
    const elder = this.memory.usersById.get(user.sub);
    if (!family || !elder) throw new NotFoundException('家庭或用户不存在');
    if (family.members.some((member) => member.role === 'elder')) throw new ConflictException('当前家庭已绑定长辈账号');
    family.members.push({ userId: user.sub, role: 'elder', nickname: elder.nickname });
    invitation.usedAt = new Date();
    return { joined: true, familyId: family.id, role: 'elder' as const };
  }

  private serialize(family: {
    id: string;
    ownerId: string;
    members: Array<{ userId: string; role: 'child' | 'elder'; user: { nickname: string } }>;
  }) {
    return {
      id: family.id,
      ownerId: family.ownerId,
      members: family.members.map((member) => ({ userId: member.userId, role: member.role, nickname: member.user.nickname })),
    };
  }
}
