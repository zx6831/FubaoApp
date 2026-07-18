import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { AuthenticatedUser } from '../auth/auth.types';
import {
  MemoryDailyTask,
  MemoryIdentityState,
  MemoryPlan,
  MemoryPlanStatus,
  MemoryTaskStatus,
} from '../auth/memory-identity-state';
import { FamilyService } from '../families/family.service';
import { Prisma } from '../generated/prisma/client';
import { PrismaService } from '../infrastructure/prisma.service';
import { HealthService } from '../health/health.service';
import { CreatePlanV1Dto } from './dto/create-plan-v1.dto';

const shanghaiTimezone = 'Asia/Shanghai' as const;

@Injectable()
export class PlansService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly memory: MemoryIdentityState,
    private readonly families: FamilyService,
    private readonly health: HealthService,
  ) {}

  async create(user: AuthenticatedUser, body: CreatePlanV1Dto) {
    this.assertChild(user);
    const family = await this.families.current(user);
    const elder = family.members.find((member: { role: string }) => member.role === 'elder');
    if (!elder) throw new NotFoundException('家庭尚未绑定长辈');
    this.assertDate(body.startsOn);
    const startsAt = this.shanghaiStart(body.startsOn);
    const title = body.title.trim();
    if (!title) throw new BadRequestException('计划名称不能为空');

    if (this.prisma.isEnabled()) {
      const plan = await this.prisma.plan.create({
        data: {
          familyId: family.id,
          subjectUserId: elder.userId,
          createdById: user.sub,
          kind: body.kind,
          title,
          subtitle: body.subtitle?.trim() || null,
          timezone: body.timezone,
          schedule: body.schedule as unknown as Prisma.InputJsonValue,
          enrollmentData: body.enrollmentData as Prisma.InputJsonValue | undefined,
          startsAt,
        },
      });
      return this.serializePlan(plan);
    }

    const now = new Date();
    const plan: MemoryPlan = {
      id: randomUUID(),
      familyId: family.id,
      subjectUserId: elder.userId,
      createdById: user.sub,
      kind: body.kind,
      title,
      subtitle: body.subtitle?.trim() || undefined,
      timezone: shanghaiTimezone,
      schedule: { time: body.schedule.time, daysOfWeek: [...body.schedule.daysOfWeek] },
      enrollmentData: body.enrollmentData,
      status: 'active',
      startsAt,
      pausedAt: null,
      endedAt: null,
      createdAt: now,
      updatedAt: now,
    };
    this.memory.plans.set(plan.id, plan);
    return this.serializePlan(plan);
  }

  async list(user: AuthenticatedUser) {
    const family = await this.families.current(user);
    const plans = this.prisma.isEnabled()
      ? await this.prisma.plan.findMany({ where: { familyId: family.id }, orderBy: { createdAt: 'desc' } })
      : [...this.memory.plans.values()]
          .filter((plan) => plan.familyId === family.id)
          .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return { items: plans.map((plan) => this.serializePlan(plan)) };
  }

  async get(user: AuthenticatedUser, id: string) {
    const family = await this.families.current(user);
    const plan = this.prisma.isEnabled()
      ? await this.prisma.plan.findFirst({ where: { id, familyId: family.id } })
      : [...this.memory.plans.values()].find((item) => item.id === id && item.familyId === family.id);
    if (!plan) throw new NotFoundException('计划不存在');
    return this.serializePlan(plan);
  }

  async updateStatus(user: AuthenticatedUser, id: string, status: MemoryPlanStatus) {
    this.assertChild(user);
    const family = await this.families.current(user);
    if (this.prisma.isEnabled()) {
      const plan = await this.prisma.plan.findFirst({ where: { id, familyId: family.id } });
      if (!plan) throw new NotFoundException('计划不存在');
      if (plan.status === 'ended' && status !== 'ended') throw new ConflictException('已结束的计划不能重新启用');
      const now = new Date();
      return this.serializePlan(await this.prisma.plan.update({
        where: { id },
        data: {
          status,
          pausedAt: status === 'paused' ? now : status === 'active' ? null : plan.pausedAt,
          endedAt: status === 'ended' ? now : plan.endedAt,
        },
      }));
    }
    const plan = [...this.memory.plans.values()].find((item) => item.id === id && item.familyId === family.id);
    if (!plan) throw new NotFoundException('计划不存在');
    if (plan.status === 'ended' && status !== 'ended') throw new ConflictException('已结束的计划不能重新启用');
    const now = new Date();
    plan.status = status;
    plan.pausedAt = status === 'paused' ? now : status === 'active' ? null : plan.pausedAt;
    plan.endedAt = status === 'ended' ? now : plan.endedAt;
    plan.updatedAt = now;
    return this.serializePlan(plan);
  }

  async tasksForDate(user: AuthenticatedUser, requestedDate?: string) {
    const date = requestedDate ?? this.todayInShanghai();
    this.assertDate(date);
    const family = await this.families.current(user);
    await this.generateDailyTasks(family.id, date);
    const items = this.prisma.isEnabled()
      ? await this.prisma.dailyTask.findMany({
          where: { familyId: family.id, date: this.utcDate(date) },
          include: { record: true },
          orderBy: [{ reminderAt: 'asc' }, { createdAt: 'asc' }],
        })
      : [...this.memory.dailyTasks.values()]
          .filter((task) => task.familyId === family.id && task.date === date)
          .sort((a, b) => a.reminderAt.getTime() - b.reminderAt.getTime());
    return this.taskCollection(date, items);
  }

  async history(user: AuthenticatedUser, from: string, to: string) {
    this.assertDate(from);
    this.assertDate(to);
    if (from > to) throw new BadRequestException('开始日期不能晚于结束日期');
    if ((this.utcDate(to).getTime() - this.utcDate(from).getTime()) / 86400000 > 92) {
      throw new BadRequestException('单次最多查询93天');
    }
    const family = await this.families.current(user);
    const items = this.prisma.isEnabled()
      ? await this.prisma.dailyTask.findMany({
          where: { familyId: family.id, date: { gte: this.utcDate(from), lte: this.utcDate(to) } },
          include: { record: true },
          orderBy: [{ date: 'desc' }, { reminderAt: 'asc' }],
        })
      : [...this.memory.dailyTasks.values()]
          .filter((task) => task.familyId === family.id && task.date >= from && task.date <= to)
          .sort((a, b) => b.date.localeCompare(a.date));
    return { from, to, items: items.map((task) => this.serializeTask(task)) };
  }

  async record(
    user: AuthenticatedUser,
    taskId: string,
    status: 'completed' | 'skipped',
    idempotencyKey?: string,
    data?: Record<string, unknown>,
  ) {
    if (user.role !== 'elder') throw new ForbiddenException('只有长辈端可以记录任务结果');
    const key = idempotencyKey?.trim();
    if (!key) throw new BadRequestException('缺少 Idempotency-Key');
    if (key.length > 120) throw new BadRequestException('Idempotency-Key 过长');
    const family = await this.families.current(user);

    if (this.prisma.isEnabled()) {
      const task = await this.prisma.dailyTask.findFirst({
        where: { id: taskId, familyId: family.id, userId: user.sub },
        include: { record: true },
      });
      if (!task) throw new NotFoundException('任务不存在');
      const existingByKey = await this.prisma.taskRecord.findUnique({ where: { idempotencyKey: key }, include: { task: true } });
      if (existingByKey) {
        if (existingByKey.taskId !== taskId) throw new ConflictException('幂等键已用于其他任务');
        if (status === 'completed') await this.health.markActivity(family.id, 'elder');
        return this.serializeTask({ ...existingByKey.task, record: existingByKey });
      }
      if (task.record) {
        if (status === 'completed') await this.health.markActivity(family.id, 'elder');
        return this.serializeTask(task);
      }
      const completedAt = new Date();
      const result = await this.prisma.$transaction(async (tx) => {
        const record = await tx.taskRecord.create({
          data: {
            taskId,
            userId: user.sub,
            idempotencyKey: key,
            status,
            source: 'app',
            data: data as Prisma.InputJsonValue | undefined,
            completedAt,
          },
        });
        const updated = await tx.dailyTask.update({ where: { id: taskId }, data: { status } });
        return { ...updated, record };
      });
      if (status === 'completed') await this.health.markActivity(family.id, 'elder');
      return this.serializeTask(result);
    }

    const task = [...this.memory.dailyTasks.values()].find(
      (item) => item.id === taskId && item.familyId === family.id && item.userId === user.sub,
    );
    if (!task) throw new NotFoundException('任务不存在');
    const existingByKey = this.memory.taskRecordsByIdempotencyKey.get(key);
    if (existingByKey) {
      if (task.record?.id !== existingByKey.id) throw new ConflictException('幂等键已用于其他任务');
      if (status === 'completed') await this.health.markActivity(family.id, 'elder');
      return this.serializeTask(task);
    }
    if (task.record) {
      if (status === 'completed') await this.health.markActivity(family.id, 'elder');
      return this.serializeTask(task);
    }
    const record = {
      id: randomUUID(),
      idempotencyKey: key,
      status,
      source: 'app',
      data,
      completedAt: new Date(),
    };
    task.status = status;
    task.record = record;
    task.updatedAt = new Date();
    this.memory.taskRecordsByIdempotencyKey.set(key, record);
    if (status === 'completed') await this.health.markActivity(family.id, 'elder');
    return this.serializeTask(task);
  }

  async remind(user: AuthenticatedUser, taskId: string) {
    this.assertChild(user);
    const family = await this.families.current(user);
    if (this.prisma.isEnabled()) {
      const task = await this.prisma.dailyTask.findFirst({ where: { id: taskId, familyId: family.id } });
      if (!task) throw new NotFoundException('任务不存在');
      const device = await this.prisma.device.findUnique({ where: { familyId: family.id } });
      if (!device || device.status === 'unbound') throw new NotFoundException('尚未绑定设备');
      const text = `温馨提醒，现在该${task.title}了`;
      await this.prisma.deviceEvent.create({
        data: { deviceId: device.id, type: 'tts.taskReminder', payload: { taskId, text, simulated: true } },
      });
      return { accepted: device.status === 'online', channel: 'simulatedTts', deviceStatus: device.status, text };
    }
    const task = [...this.memory.dailyTasks.values()].find((item) => item.id === taskId && item.familyId === family.id);
    if (!task) throw new NotFoundException('任务不存在');
    const device = this.memory.devices.get(family.id);
    if (!device || device.status === 'unbound') throw new NotFoundException('尚未绑定设备');
    const text = `温馨提醒，现在该${task.title}了`;
    return { accepted: device.status === 'online', channel: 'simulatedTts', deviceStatus: device.status, text };
  }

  private async generateDailyTasks(familyId: string, date: string) {
    const weekday = this.weekday(date);
    const endOfDay = new Date(`${date}T23:59:59.999+08:00`);
    if (this.prisma.isEnabled()) {
      const plans = await this.prisma.plan.findMany({
        where: { familyId, status: 'active', startsAt: { lte: endOfDay } },
      });
      for (const plan of plans) {
        const schedule = this.scheduleOf(plan.schedule);
        if (!schedule.daysOfWeek.includes(weekday)) continue;
        await this.prisma.dailyTask.upsert({
          where: { planId_date: { planId: plan.id, date: this.utcDate(date) } },
          create: {
            familyId,
            planId: plan.id,
            userId: plan.subjectUserId,
            date: this.utcDate(date),
            kind: plan.kind,
            title: plan.title,
            subtitle: plan.subtitle,
            reminderAt: this.shanghaiTime(date, schedule.time),
          },
          update: {},
        });
      }
      return;
    }
    const plans = [...this.memory.plans.values()].filter(
      (plan) => plan.familyId === familyId && plan.status === 'active' && plan.startsAt <= endOfDay,
    );
    for (const plan of plans) {
      if (!plan.schedule.daysOfWeek.includes(weekday)) continue;
      const uniqueKey = `${plan.id}:${date}`;
      if ([...this.memory.dailyTasks.values()].some((task) => `${task.planId}:${task.date}` === uniqueKey)) continue;
      const now = new Date();
      const task: MemoryDailyTask = {
        id: randomUUID(), familyId, planId: plan.id, userId: plan.subjectUserId, date, kind: plan.kind,
        title: plan.title, subtitle: plan.subtitle, reminderAt: this.shanghaiTime(date, plan.schedule.time),
        status: 'pending', createdAt: now, updatedAt: now,
      };
      this.memory.dailyTasks.set(task.id, task);
    }
  }

  private taskCollection(date: string, items: any[]) {
    const serialized = items.map((task) => this.serializeTask(task));
    return {
      date,
      items: serialized,
      progress: {
        total: serialized.length,
        completed: serialized.filter((task) => task.status === 'completed').length,
        skipped: serialized.filter((task) => task.status === 'skipped').length,
        pending: serialized.filter((task) => task.status === 'pending').length,
      },
    };
  }

  private serializePlan(plan: any) {
    return {
      id: plan.id,
      kind: plan.kind,
      title: plan.title,
      subtitle: plan.subtitle ?? null,
      timezone: plan.timezone,
      schedule: this.scheduleOf(plan.schedule),
      enrollmentData: plan.enrollmentData ?? null,
      status: plan.status,
      startsAt: plan.startsAt.toISOString(),
      pausedAt: plan.pausedAt?.toISOString() ?? null,
      endedAt: plan.endedAt?.toISOString() ?? null,
      createdAt: plan.createdAt.toISOString(),
      updatedAt: plan.updatedAt.toISOString(),
    };
  }

  private serializeTask(task: any) {
    const date = task.date instanceof Date ? task.date.toISOString().slice(0, 10) : task.date;
    return {
      id: task.id,
      planId: task.planId,
      date,
      kind: task.kind,
      title: task.title,
      subtitle: task.subtitle ?? null,
      reminderAt: task.reminderAt?.toISOString() ?? null,
      status: task.status,
      record: task.record ? {
        status: task.record.status,
        source: task.record.source,
        data: task.record.data ?? null,
        completedAt: task.record.completedAt.toISOString(),
      } : null,
    };
  }

  private scheduleOf(value: unknown): { time: string; daysOfWeek: number[] } {
    const candidate = value as { time?: unknown; daysOfWeek?: unknown } | null;
    if (!candidate || typeof candidate.time !== 'string' || !Array.isArray(candidate.daysOfWeek)) {
      return { time: '08:00', daysOfWeek: [1, 2, 3, 4, 5, 6, 7] };
    }
    return { time: candidate.time, daysOfWeek: candidate.daysOfWeek.filter((day): day is number => Number.isInteger(day)) };
  }

  private todayInShanghai() {
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: shanghaiTimezone, year: 'numeric', month: '2-digit', day: '2-digit',
    }).format(new Date());
  }

  private assertDate(value: string) {
    const parsed = this.utcDate(value);
    if (Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
      throw new BadRequestException('日期格式无效');
    }
  }

  private utcDate(date: string) {
    return new Date(`${date}T00:00:00.000Z`);
  }

  private shanghaiStart(date: string) {
    return new Date(`${date}T00:00:00+08:00`);
  }

  private shanghaiTime(date: string, time: string) {
    return new Date(`${date}T${time}:00+08:00`);
  }

  private weekday(date: string) {
    const day = this.utcDate(date).getUTCDay();
    return day === 0 ? 7 : day;
  }

  private assertChild(user: AuthenticatedUser) {
    if (user.role !== 'child') throw new ForbiddenException('只有子女端可以管理计划');
  }
}
