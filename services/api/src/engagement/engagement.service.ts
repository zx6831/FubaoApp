import { Injectable, Logger, NotFoundException, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { AuthenticatedUser } from '../auth/auth.types';
import { MemoryIdentityState } from '../auth/memory-identity-state';
import { FamilyService } from '../families/family.service';
import { PrismaService } from '../infrastructure/prisma.service';

@Injectable()
export class EngagementService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(EngagementService.name);
  private deletionTimer?: NodeJS.Timeout;

  constructor(private readonly prisma: PrismaService, private readonly memory: MemoryIdentityState, private readonly families: FamilyService) {}

  onModuleInit() {
    this.deletionTimer = setInterval(() => {
      void this.runDeletionWorker();
    }, 60 * 60 * 1000);
    this.deletionTimer.unref();
    void this.runDeletionWorker();
  }

  onModuleDestroy() {
    if (this.deletionTimer) clearInterval(this.deletionTimer);
  }

  private async runDeletionWorker() {
    try {
      const { processed } = await this.processDueDeletionRequests();
      if (processed) this.logger.log(`Completed ${processed} account deletion request(s)`);
    } catch (error) {
      this.logger.error('Account deletion worker failed', error instanceof Error ? error.stack : String(error));
    }
  }

  async topics(user: AuthenticatedUser) {
    const family = await this.families.current(user);
    const date = this.utcToday();
    if (this.prisma.isEnabled()) {
      let items = await this.prisma.topic.findMany({ where: { familyId: family.id, date }, orderBy: { createdAt: 'asc' } });
      if (!items.length) {
        const templates = await this.topicTemplates(family.id);
        await this.prisma.topic.createMany({ data: templates.map((item) => ({ familyId: family.id, date, ...item })) });
        items = await this.prisma.topic.findMany({ where: { familyId: family.id, date }, orderBy: { createdAt: 'asc' } });
      }
      return { items: items.map((item) => this.topicJson(item)) };
    }
    const key = `${family.id}:${this.dateString(date)}`;
    let items = [...this.memory.engagementTopics.values()].filter((item) => item.key === key);
    if (!items.length) {
      items = (await this.topicTemplates(family.id)).map((item) => ({ id: randomUUID(), key, ...item, copiedAt: null, createdAt: new Date() }));
      for (const item of items) this.memory.engagementTopics.set(item.id, item);
    }
    return { items: items.map((item) => this.topicJson(item)) };
  }

  async copied(user: AuthenticatedUser, id: string) {
    const family = await this.families.current(user);
    if (this.prisma.isEnabled()) {
      const item = await this.prisma.topic.findFirst({ where: { id, familyId: family.id } });
      if (!item) throw new NotFoundException('话题不存在');
      await this.prisma.topic.update({ where: { id }, data: { copiedAt: new Date() } });
    } else {
      const item = this.memory.engagementTopics.get(id);
      if (!item || item.key.split(':')[0] !== family.id) throw new NotFoundException('话题不存在');
      item.copiedAt = new Date();
    }
    return { copied: true, topicId: id };
  }

  async messages(user: AuthenticatedUser, type?: 'weeklyReport' | 'alert' | 'system' | 'insight') {
    const family = await this.families.current(user);
    if (this.prisma.isEnabled()) {
      let items = await this.prisma.message.findMany({ where: { familyId: family.id, userId: user.sub, type }, orderBy: { createdAt: 'desc' } });
      if (!items.length && !type) {
        await this.prisma.message.createMany({ data: this.defaultMessages(family.id, user.sub) });
        items = await this.prisma.message.findMany({ where: { familyId: family.id, userId: user.sub }, orderBy: { createdAt: 'desc' } });
      }
      return { items: items.map((item) => this.messageJson(item)) };
    }
    let items = [...this.memory.engagementMessages.values()].filter((item) => item.familyId === family.id && item.userId === user.sub);
    if (!items.length) {
      items = this.defaultMessages(family.id, user.sub).map((item) => ({ id: randomUUID(), ...item, readAt: null, createdAt: new Date() }));
      for (const item of items) this.memory.engagementMessages.set(item.id, item);
    }
    if (type) items = items.filter((item) => item.type === type);
    return { items: items.map((item) => this.messageJson(item)) };
  }

  async readMessage(user: AuthenticatedUser, id: string) {
    if (this.prisma.isEnabled()) {
      const item = await this.prisma.message.findFirst({ where: { id, userId: user.sub } });
      if (!item) throw new NotFoundException('消息不存在');
      return this.messageJson(await this.prisma.message.update({ where: { id }, data: { readAt: new Date() } }));
    }
    const item = this.memory.engagementMessages.get(id);
    if (!item || item.userId !== user.sub) throw new NotFoundException('消息不存在');
    item.readAt = new Date();
    return this.messageJson(item);
  }

  async weeklyReport(user: AuthenticatedUser) {
    const family = await this.families.current(user);
    const from = new Date(Date.now() - 6 * 86400000);
    const tasks = this.prisma.isEnabled()
      ? await this.prisma.dailyTask.findMany({ where: { familyId: family.id, date: { gte: from } } })
      : [...this.memory.dailyTasks.values()].filter((item) => item.familyId === family.id && new Date(item.date) >= from);
    const completed = tasks.filter((item) => item.status === 'completed').length;
    return { from: this.dateString(from), to: this.dateString(new Date()), tasks: { completed, total: tasks.length }, completionRate: tasks.length ? completed / tasks.length : 0 };
  }

  async exportData(user: AuthenticatedUser) {
    const family = await this.families.current(user);
    if (!this.prisma.isEnabled()) return { generatedAt: new Date().toISOString(), family, plans: [...this.memory.plans.values()].filter((x) => x.familyId === family.id), tasks: [...this.memory.dailyTasks.values()].filter((x) => x.familyId === family.id), healthReadings: [...this.memory.healthReadingsV1.values()].filter((x) => x.familyId === family.id), alerts: [...this.memory.alertsV1.values()].filter((x) => x.familyId === family.id) };
    const [plans, tasks, healthReadings, alerts, devices, topics, messages] = await Promise.all([
      this.prisma.plan.findMany({ where: { familyId: family.id } }), this.prisma.dailyTask.findMany({ where: { familyId: family.id }, include: { record: true } }),
      this.prisma.healthReading.findMany({ where: { familyId: family.id } }), this.prisma.alert.findMany({ where: { familyId: family.id } }),
      this.prisma.device.findMany({ where: { familyId: family.id }, include: { settings: true } }), this.prisma.topic.findMany({ where: { familyId: family.id } }),
      this.prisma.message.findMany({ where: { familyId: family.id, userId: user.sub } }),
    ]);
    return { generatedAt: new Date().toISOString(), family, plans, tasks, healthReadings, alerts, devices, topics, messages };
  }

  async scheduleDeletion(user: AuthenticatedUser) {
    const deleteAfter = new Date(Date.now() + 30 * 86400000);
    if (this.prisma.isEnabled()) await this.prisma.deletionRequest.upsert({ where: { userId: user.sub }, create: { userId: user.sub, deleteAfter }, update: { requestedAt: new Date(), deleteAfter, completedAt: null } });
    else this.memory.deletionRequestsV1.set(user.sub, { requestedAt: new Date(), deleteAfter, completedAt: null });
    return { status: 'scheduled', deleteAfter: deleteAfter.toISOString() };
  }

  async deletionStatus(user: AuthenticatedUser) {
    const item = this.prisma.isEnabled() ? await this.prisma.deletionRequest.findUnique({ where: { userId: user.sub } }) : this.memory.deletionRequestsV1.get(user.sub);
    return item ? { status: item.completedAt ? 'completed' : 'scheduled', requestedAt: item.requestedAt.toISOString(), deleteAfter: item.deleteAfter.toISOString() } : { status: 'none' };
  }

  async processDueDeletionRequests(now = new Date()) {
    if (this.prisma.isEnabled()) {
      const due = await this.prisma.deletionRequest.findMany({
        where: { completedAt: null, deleteAfter: { lte: now } },
        select: { id: true, userId: true },
      });
      for (const request of due) {
        await this.prisma.$transaction(async (tx) => {
          const user = await tx.user.findUnique({ where: { id: request.userId } });
          if (!user || user.deletedAt) {
            await tx.deletionRequest.update({ where: { id: request.id }, data: { completedAt: now } });
            return;
          }
          const memberships = await tx.familyMember.findMany({
            where: { userId: user.id },
            select: { familyId: true },
          });
          const familyIds = memberships.map((item) => item.familyId);

          await tx.session.updateMany({ where: { userId: user.id, revokedAt: null }, data: { revokedAt: now } });
          await tx.pushToken.deleteMany({ where: { userId: user.id } });
          await tx.alert.deleteMany({ where: { userId: user.id } });
          await tx.healthReading.deleteMany({ where: { userId: user.id } });
          await tx.plan.deleteMany({ where: { OR: [{ subjectUserId: user.id }, { createdById: user.id }] } });
          await tx.dailyTask.deleteMany({ where: { userId: user.id } });
          await tx.message.deleteMany({ where: { userId: user.id } });
          await tx.healthProfile.deleteMany({ where: { userId: user.id } });
          await tx.familyMember.updateMany({ where: { userId: user.id }, data: { status: 'removed', exitedAt: now } });
          if (familyIds.length) {
            await tx.topic.deleteMany({ where: { familyId: { in: familyIds } } });
            await tx.sparkActivity.deleteMany({ where: { familyId: { in: familyIds } } });
            await tx.sparkStatus.deleteMany({ where: { familyId: { in: familyIds } } });
          }
          if (user.role === 'child') {
            await tx.family.updateMany({
              where: { ownerId: user.id, status: 'active' },
              data: { status: 'dissolved', dissolvedAt: now },
            });
          }
          await tx.auditLog.updateMany({ where: { actorId: user.id }, data: { actorId: null, metadata: { redacted: true } } });
          await tx.user.update({
            where: { id: user.id },
            data: {
              phoneHash: `deleted:${randomUUID()}`,
              phoneCiphertext: '',
              nickname: '已注销用户',
              deletedAt: now,
            },
          });
          await tx.deletionRequest.update({ where: { id: request.id }, data: { completedAt: now } });
          await tx.auditLog.create({
            data: {
              action: 'privacy.account_deleted',
              resourceType: 'user',
              resourceId: user.id,
              metadata: { completedAt: now.toISOString() },
            },
          });
        });
      }
      return { processed: due.length };
    }

    let processed = 0;
    for (const [userId, request] of this.memory.deletionRequestsV1) {
      if (request.completedAt || request.deleteAfter > now) continue;
      const user = this.memory.usersById.get(userId);
      if (!user) {
        request.completedAt = now;
        continue;
      }
      for (const [key, session] of this.memory.sessions) {
        if (session.userId === userId) this.memory.sessions.delete(key);
      }
      const familyIds = new Set<string>();
      for (const [id, family] of this.memory.families) {
        if (!family.members.some((member) => member.userId === userId)) continue;
        familyIds.add(id);
        family.members = family.members.filter((member) => member.userId !== userId);
        if (family.ownerId === userId) this.memory.families.delete(id);
      }
      this.memory.usersByPhoneHash.delete(user.phoneHash);
      user.phoneHash = `deleted:${randomUUID()}`;
      user.phoneCiphertext = '';
      user.nickname = '已注销用户';
      user.deletedAt = now;
      this.memory.healthProfiles.delete(userId);
      for (const [id, item] of this.memory.plans) {
        if (item.subjectUserId === userId || item.createdById === userId) this.memory.plans.delete(id);
      }
      for (const [id, item] of this.memory.dailyTasks) {
        if (item.userId === userId || familyIds.has(item.familyId) && user.role === 'child') this.memory.dailyTasks.delete(id);
      }
      for (const [id, item] of this.memory.healthReadingsV1) {
        if (item.userId === userId || familyIds.has(item.familyId) && user.role === 'child') this.memory.healthReadingsV1.delete(id);
      }
      for (const [id, item] of this.memory.alertsV1) {
        if (item.userId === userId || familyIds.has(item.familyId) && user.role === 'child') this.memory.alertsV1.delete(id);
      }
      for (const [id, item] of this.memory.engagementTopics) {
        if (familyIds.has(item.key?.split(':')[0])) this.memory.engagementTopics.delete(id);
      }
      for (const [id, item] of this.memory.engagementMessages) {
        if (item.userId === userId || familyIds.has(item.familyId) && user.role === 'child') this.memory.engagementMessages.delete(id);
      }
      request.completedAt = now;
      processed += 1;
    }
    return { processed };
  }

  async feedback(user: AuthenticatedUser, content: string) {
    const text = content.trim();
    if (this.prisma.isEnabled()) await this.prisma.auditLog.create({ data: { actorId: user.sub, action: 'feedback.created', resourceType: 'feedback', metadata: { content: text } } });
    else this.memory.feedbackV1.push({ userId: user.sub, content: text, createdAt: new Date() });
    return { submitted: true, id: randomUUID() };
  }

  private async topicTemplates(familyId: string) {
    const completed = this.prisma.isEnabled() ? await this.prisma.dailyTask.count({ where: { familyId, date: this.utcToday(), status: 'completed' } }) : [...this.memory.dailyTasks.values()].filter((x) => x.familyId === familyId && x.date === this.dateString(this.utcToday()) && x.status === 'completed').length;
    return [
      { title: completed ? '今天的任务完成得很棒' : '从今天的计划聊起', behavior: completed ? `今天已完成 ${completed} 项任务` : '今天还有任务可以一起关心', analysis: '肯定坚持和努力，让彼此感受到理解与支持。', suggestedWords: completed ? '妈，今天的任务完成得很棒，辛苦啦！' : '妈，今天感觉怎么样？任务慢慢来就好。' },
      { title: '从散步和心情聊起', behavior: '关注今天的小事和感受', analysis: '轻松分享日常，拉近彼此距离。', suggestedWords: '今天有没有一件让你觉得开心的事？' },
    ];
  }
  private defaultMessages(familyId: string, userId: string) { return [
    { familyId, userId, type: 'system' as const, title: '欢迎使用福豹', body: '家庭、健康档案和设备已准备好，可以开始今天的关怀计划。' },
    { familyId, userId, type: 'weeklyReport' as const, title: '本周健康周报已生成', body: '看看本周任务完成与健康记录变化。' },
    { familyId, userId, type: 'insight' as const, title: '健康小知识', body: '规律记录比单次数字更有参考价值。' },
  ]; }
  private topicJson(x: any) { return { id: x.id, title: x.title, description: x.analysis, behavior: x.behavior, suggestedWords: x.suggestedWords, copiedAt: x.copiedAt?.toISOString() ?? null }; }
  private messageJson(x: any) { return { id: x.id, type: x.type, title: x.title, body: x.body, payload: x.payload ?? null, readAt: x.readAt?.toISOString() ?? null, createdAt: x.createdAt.toISOString() }; }
  private utcToday() { const value = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Shanghai', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date()); return new Date(`${value}T00:00:00.000Z`); }
  private dateString(value: Date) { return value.toISOString().slice(0, 10); }
}
