import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { AuthenticatedUser } from '../auth/auth.types';
import { MemoryIdentityState } from '../auth/memory-identity-state';
import { FamilyService } from '../families/family.service';
import { PrismaService } from '../infrastructure/prisma.service';

@Injectable()
export class EngagementService {
  constructor(private readonly prisma: PrismaService, private readonly memory: MemoryIdentityState, private readonly families: FamilyService) {}

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
    { familyId, userId, type: 'weeklyReport' as const, title: '本周健康周报已生成', body: '看看本周任务完成与健康记录变化。' },
    { familyId, userId, type: 'insight' as const, title: '健康小知识', body: '规律记录比单次数字更有参考价值。' },
  ]; }
  private topicJson(x: any) { return { id: x.id, title: x.title, description: x.analysis, behavior: x.behavior, suggestedWords: x.suggestedWords, copiedAt: x.copiedAt?.toISOString() ?? null }; }
  private messageJson(x: any) { return { id: x.id, type: x.type, title: x.title, body: x.body, payload: x.payload ?? null, readAt: x.readAt?.toISOString() ?? null, createdAt: x.createdAt.toISOString() }; }
  private utcToday() { const value = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Shanghai', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date()); return new Date(`${value}T00:00:00.000Z`); }
  private dateString(value: Date) { return value.toISOString().slice(0, 10); }
}
