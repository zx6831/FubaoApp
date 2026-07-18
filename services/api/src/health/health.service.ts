import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { AuthenticatedUser } from '../auth/auth.types';
import { MemoryAlertV1, MemoryHealthReadingV1, MemoryIdentityState } from '../auth/memory-identity-state';
import { FamilyService } from '../families/family.service';
import { Prisma } from '../generated/prisma/client';
import { PrismaService } from '../infrastructure/prisma.service';
import { NOTIFICATION_ADAPTER, NotificationAdapter } from '../integrations/notification.adapter';
import { NotificationsService } from '../integrations/notifications.service';
import { CreateHealthReadingDto, HealthReadingsQueryDto, UpdateAlertDto } from './dto/health.dto';

type Metric = 'bloodPressure' | 'bloodGlucose' | 'mood' | 'weight';

@Injectable()
export class HealthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly memory: MemoryIdentityState,
    private readonly families: FamilyService,
    private readonly notifications: NotificationsService,
    @Inject(NOTIFICATION_ADAPTER)
    private readonly notificationAdapter: NotificationAdapter,
  ) {}

  async createReading(user: AuthenticatedUser, body: CreateHealthReadingDto) {
    const family = await this.families.current(user);
    const elder = family.members.find((member: { role: string }) => member.role === 'elder');
    const child = family.members.find((member: { role: string }) => member.role === 'child');
    if (!elder) throw new NotFoundException('家庭尚未绑定长辈');
    const value = this.readingValue(body);
    const recordedAt = body.recordedAt ? new Date(body.recordedAt) : new Date();
    if (recordedAt > new Date(Date.now() + 5 * 60 * 1000)) throw new BadRequestException('记录时间不能晚于当前时间');

    let reading: any;
    if (this.prisma.isEnabled()) {
      reading = await this.prisma.healthReading.create({
        data: {
          familyId: family.id,
          userId: elder.userId,
          metric: body.type,
          value: value as Prisma.InputJsonValue,
          source: `${user.role}App`,
          confirmedByUser: body.confirmedByUser,
          recordedAt,
        },
      });
    } else {
      reading = {
        id: randomUUID(), familyId: family.id, userId: elder.userId, metric: body.type,
        value, source: `${user.role}App`, confirmedByUser: true, recordedAt, createdAt: new Date(),
      } satisfies MemoryHealthReadingV1;
      this.memory.healthReadingsV1.set(reading.id, reading);
    }
    const alert = await this.maybeCreateAlert(family.id, elder.userId, child?.userId, reading.id, body.type, value);
    if (user.role === 'child') await this.markActivity(family.id, 'child');
    return { reading: this.serializeReading(reading), alert: alert ? this.serializeAlert(alert) : null };
  }

  async readings(user: AuthenticatedUser, query: HealthReadingsQueryDto) {
    const family = await this.families.current(user);
    const from = query.from ? new Date(query.from) : undefined;
    const to = query.to ? new Date(query.to) : undefined;
    if (from && to && from > to) throw new BadRequestException('开始时间不能晚于结束时间');
    const items = this.prisma.isEnabled()
      ? await this.prisma.healthReading.findMany({
          where: {
            familyId: family.id,
            metric: query.metric,
            recordedAt: { gte: from, lte: to },
          },
          orderBy: { recordedAt: 'desc' },
          take: 500,
        })
      : [...this.memory.healthReadingsV1.values()]
          .filter((item) => item.familyId === family.id)
          .filter((item) => !query.metric || item.metric === query.metric)
          .filter((item) => !from || item.recordedAt >= from)
          .filter((item) => !to || item.recordedAt <= to)
          .sort((a, b) => b.recordedAt.getTime() - a.recordedAt.getTime())
          .slice(0, 500);
    return { items: items.map((item) => this.serializeReading(item)) };
  }

  async reading(user: AuthenticatedUser, id: string) {
    const family = await this.families.current(user);
    const item = this.prisma.isEnabled()
      ? await this.prisma.healthReading.findFirst({ where: { id, familyId: family.id } })
      : [...this.memory.healthReadingsV1.values()].find((reading) => reading.id === id && reading.familyId === family.id);
    if (!item) throw new NotFoundException('健康记录不存在');
    return this.serializeReading(item);
  }

  async alerts(user: AuthenticatedUser) {
    const family = await this.families.current(user);
    const items = this.prisma.isEnabled()
      ? await this.prisma.alert.findMany({ where: { familyId: family.id }, orderBy: { createdAt: 'desc' }, take: 100 })
      : [...this.memory.alertsV1.values()]
          .filter((alert) => alert.familyId === family.id)
          .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
          .slice(0, 100);
    return { items: items.map((item) => this.serializeAlert(item)) };
  }

  async updateAlert(user: AuthenticatedUser, id: string, body: UpdateAlertDto) {
    const family = await this.families.current(user);
    if (this.prisma.isEnabled()) {
      const alert = await this.prisma.alert.findFirst({ where: { id, familyId: family.id } });
      if (!alert) throw new NotFoundException('告警不存在');
      return this.serializeAlert(await this.prisma.alert.update({
        where: { id },
        data: { status: body.status, closeReason: body.closeReason, handledAt: new Date() },
      }));
    }
    const alert = [...this.memory.alertsV1.values()].find((item) => item.id === id && item.familyId === family.id);
    if (!alert) throw new NotFoundException('告警不存在');
    alert.status = body.status;
    alert.closeReason = body.closeReason;
    alert.handledAt = new Date();
    return this.serializeAlert(alert);
  }

  async currentSpark(user: AuthenticatedUser) {
    const family = await this.families.current(user);
    if (user.role === 'child') await this.markActivity(family.id, 'child');
    const activities = await this.activities(family.id);
    const today = this.today();
    const todayActivity = activities.find((item) => this.dateString(item.date) === today);
    const lit = todayActivity?.childActive === true && todayActivity?.elderActive === true;
    let streakDays = 0;
    let cursor = this.utcDate(lit ? today : this.previousDate(today));
    while (true) {
      const key = this.dateString(cursor);
      const activity = activities.find((item) => this.dateString(item.date) === key);
      if (!activity?.childActive || !activity.elderActive) break;
      streakDays++;
      cursor = new Date(cursor.getTime() - 86400000);
    }
    const lastLit = activities.find((item) => item.childActive && item.elderActive);
    if (!lastLit || (this.utcDate(today).getTime() - this.utcDate(this.dateString(lastLit.date)).getTime()) / 86400000 >= 7) {
      streakDays = 0;
    }
    if (this.prisma.isEnabled()) {
      await this.prisma.sparkStatus.upsert({
        where: { familyId: family.id },
        create: { familyId: family.id, state: lit ? 'lit' : 'unlit', streakDays, lastLitDate: lastLit ? this.utcDate(this.dateString(lastLit.date)) : null },
        update: { state: lit ? 'lit' : 'unlit', streakDays, lastLitDate: lastLit ? this.utcDate(this.dateString(lastLit.date)) : null },
      });
    }
    return { lit, streakDays, date: today, childActive: todayActivity?.childActive ?? false, elderActive: todayActivity?.elderActive ?? false };
  }

  async sparkHistory(user: AuthenticatedUser, from: string, to: string) {
    const family = await this.families.current(user);
    this.assertDate(from);
    this.assertDate(to);
    if (from > to) throw new BadRequestException('开始日期不能晚于结束日期');
    const activities = (await this.activities(family.id)).filter((item) => {
      const date = this.dateString(item.date);
      return date >= from && date <= to;
    });
    return { from, to, items: activities.map((item) => ({
      date: this.dateString(item.date), childActive: item.childActive, elderActive: item.elderActive,
      lit: item.childActive && item.elderActive,
    })) };
  }

  async markActivity(familyId: string, role: 'child' | 'elder') {
    const date = this.today();
    if (this.prisma.isEnabled()) {
      await this.prisma.sparkActivity.upsert({
        where: { familyId_date: { familyId, date: this.utcDate(date) } },
        create: { familyId, date: this.utcDate(date), childActive: role === 'child', elderActive: role === 'elder' },
        update: role === 'child' ? { childActive: true } : { elderActive: true },
      });
      return;
    }
    const key = `${familyId}:${date}`;
    const activity = this.memory.sparkActivitiesV1.get(key) ?? {
      familyId, date, childActive: false, elderActive: false, createdAt: new Date(), updatedAt: new Date(),
    };
    if (role === 'child') activity.childActive = true;
    if (role === 'elder') activity.elderActive = true;
    activity.updatedAt = new Date();
    this.memory.sparkActivitiesV1.set(key, activity);
  }

  private async maybeCreateAlert(familyId: string, userId: string, childUserId: string | undefined, readingId: string, metric: Metric, value: Record<string, unknown>) {
    const assessment = this.assess(metric, value);
    if (!assessment) return null;
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
    if (this.prisma.isEnabled()) {
      const existing = await this.prisma.alert.findFirst({
        where: { familyId, metric, level: assessment.level, createdAt: { gte: since } },
        orderBy: { createdAt: 'desc' },
      });
      if (existing) return existing;
      const alert = await this.prisma.alert.create({ data: {
        familyId, userId, healthReadingId: readingId, level: assessment.level, metric,
        message: assessment.message, dedupeKey: `${familyId}:${metric}:${assessment.level}:${Date.now()}`,
      } });
      await this.publishAlertMessage(familyId, childUserId, alert);
      return alert;
    }
    const existing = [...this.memory.alertsV1.values()].find((alert) =>
      alert.familyId === familyId && alert.metric === metric && alert.level === assessment.level && alert.createdAt >= since);
    if (existing) return existing;
    const alert: MemoryAlertV1 = {
      id: randomUUID(), familyId, userId, healthReadingId: readingId, metric, level: assessment.level,
      message: assessment.message, status: 'pending', dedupeKey: randomUUID(), createdAt: new Date(),
    };
    this.memory.alertsV1.set(alert.id, alert);
    await this.publishAlertMessage(familyId, childUserId, alert);
    return alert;
  }

  private async publishAlertMessage(
    familyId: string,
    childUserId: string | undefined,
    alert: { id: string; level: 'L1' | 'L2' | 'L3'; message: string },
  ) {
    if (!childUserId) return;
    const title = alert.level === 'L2' ? '需要及时关注的健康提醒' : '新的健康提醒';
    if (this.prisma.isEnabled()) {
      await this.prisma.message.create({
        data: {
          familyId,
          userId: childUserId,
          type: 'alert',
          title,
          body: alert.message,
          payload: { alertId: alert.id, level: alert.level },
        },
      });
    } else {
      const id = randomUUID();
      this.memory.engagementMessages.set(id, {
        id,
        familyId,
        userId: childUserId,
        type: 'alert',
        title,
        body: alert.message,
        payload: { alertId: alert.id, level: alert.level },
        readAt: null,
        createdAt: new Date(),
      });
    }
    const tokens = await this.notifications.tokensForUser(childUserId);
    await Promise.allSettled(tokens.map((deviceToken) =>
      this.notificationAdapter.send({
        deviceToken,
        title,
        body: alert.message,
        data: { alertId: alert.id, level: alert.level },
      })));
  }

  private assess(metric: Metric, value: Record<string, unknown>): { level: 'L1' | 'L2'; message: string } | null {
    if (metric === 'bloodPressure') {
      const systolic = Number(value.systolic);
      const diastolic = Number(value.diastolic);
      if (systolic >= 160 || diastolic >= 100) return { level: 'L2', message: '本次记录偏高，请再次确认数据，并联系医生了解情况；如感到明显不适，请联系当地急救服务。' };
      if (systolic >= 140 || diastolic >= 90) return { level: 'L1', message: '本次记录需要关注，请稍后复测并按医生建议管理。' };
    }
    if (metric === 'bloodGlucose') {
      const glucose = Number(value.value);
      if (glucose >= 13.9) return { level: 'L2', message: '本次血糖记录偏高，请确认数据并尽快联系医生了解情况。' };
      if (glucose >= 7) return { level: 'L1', message: '本次血糖记录需要关注，请按医生建议复测和管理。' };
    }
    return null;
  }

  private readingValue(body: CreateHealthReadingDto): Record<string, unknown> {
    if (body.type === 'bloodPressure') return { systolic: body.systolic, diastolic: body.diastolic, unit: 'mmHg' };
    if (body.type === 'bloodGlucose') return { value: body.value, unit: 'mmol/L' };
    if (body.type === 'weight') return { value: body.value, unit: 'kg' };
    return { text: body.textValue };
  }

  private async activities(familyId: string): Promise<any[]> {
    return this.prisma.isEnabled()
      ? this.prisma.sparkActivity.findMany({ where: { familyId }, orderBy: { date: 'desc' }, take: 400 })
      : [...this.memory.sparkActivitiesV1.values()]
          .filter((item) => item.familyId === familyId)
          .sort((a, b) => b.date.localeCompare(a.date));
  }

  private serializeReading(item: any) {
    return { id: item.id, metric: item.metric, value: item.value, source: item.source,
      confirmedByUser: item.confirmedByUser, recordedAt: item.recordedAt.toISOString(), createdAt: item.createdAt.toISOString() };
  }

  private serializeAlert(item: any) {
    return { id: item.id, healthReadingId: item.healthReadingId, level: item.level, metric: item.metric,
      message: item.message, status: item.status, closeReason: item.closeReason ?? null,
      handledAt: item.handledAt?.toISOString() ?? null, createdAt: item.createdAt.toISOString() };
  }

  private today() {
    return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Shanghai', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
  }
  private previousDate(date: string) { return this.dateString(new Date(this.utcDate(date).getTime() - 86400000)); }
  private dateString(value: Date | string) { return value instanceof Date ? value.toISOString().slice(0, 10) : value; }
  private utcDate(value: string) { return new Date(`${value}T00:00:00.000Z`); }
  private assertDate(value: string) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value) || this.dateString(this.utcDate(value)) !== value) throw new BadRequestException('日期格式无效');
  }
}
