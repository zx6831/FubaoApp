import { Injectable } from '@nestjs/common';
import { randomInt, randomUUID } from 'node:crypto';
import { CareAlert, DailyTask, HealthPlan, Role } from './fubao.types';

@Injectable()
export class FubaoService {
  private readonly familyId = 'family-demo';
  private invitation: { code: string; expiresAt: string } | null = null;
  private childActive = true;
  private readonly readings: Array<Record<string, unknown>> = [];
  private readonly alerts: CareAlert[] = [];
  private readonly completions = new Map<string, string>();

  readonly plans: HealthPlan[] = [
    { id: 'blood-pressure', title: '血压管理', status: 'active', completed: 3, total: 4 },
    { id: 'healthy-life', title: '健康生活习惯', status: 'active', completed: 1, total: 2 },
  ];

  readonly tasks: DailyTask[] = [
    { id: 'medicine', kind: 'medicine', title: '降压药 1 片', timeLabel: '上午 8:30', completedAt: null },
    { id: 'pressure', kind: 'bloodPressure', title: '记录血压', timeLabel: '上午 9:00', completedAt: new Date().toISOString() },
    { id: 'walk', kind: 'walk', title: '下午散步 20 分钟', timeLabel: '下午 3:30', completedAt: null },
    { id: 'mood', kind: 'mood', title: '记录今天心情', timeLabel: '晚上 8:30', completedAt: new Date().toISOString() },
  ];

  testLogin(role: Role) {
    if (role === 'child') this.childActive = true;
    return {
      accessToken: role === 'child' ? 'child-token' : 'elder-token',
      role,
      user: role === 'child' ? { id: 'child-demo', name: '小雨' } : { id: 'elder-demo', name: '王阿姨' },
    };
  }

  createFamily() {
    return { id: this.familyId, ownerId: 'child-demo', elderId: 'elder-demo' };
  }

  createInvitation() {
    const code = randomInt(1000, 10000).toString();
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString();
    this.invitation = { code, expiresAt };
    return { code, expiresAt };
  }

  joinFamily(code: string) {
    const valid = this.invitation && this.invitation.code === code && Date.parse(this.invitation.expiresAt) > Date.now();
    if (!valid) return { joined: false, reason: '邀请码无效或已过期' };
    this.invitation = null;
    return { joined: true, familyId: this.familyId, role: 'elder' as const };
  }

  createPlan(title: string) {
    const plan: HealthPlan = { id: randomUUID(), title, status: 'active', completed: 0, total: 1 };
    this.plans.push(plan);
    return plan;
  }

  completeTask(id: string, idempotencyKey: string | undefined) {
    const task = this.tasks.find((item) => item.id === id);
    if (!task) return null;
    if (idempotencyKey && this.completions.has(idempotencyKey)) {
      task.completedAt = this.completions.get(idempotencyKey) ?? task.completedAt;
      return task;
    }
    task.completedAt ??= new Date().toISOString();
    if (idempotencyKey) this.completions.set(idempotencyKey, task.completedAt);
    return task;
  }

  currentSpark() {
    const elderActive = this.tasks.some((task) => task.completedAt !== null);
    return { lit: elderActive && this.childActive, streakDays: elderActive && this.childActive ? 12 : 0 };
  }

  todayTopics() {
    return [
      { id: 'task-done', title: '妈妈今天按时完成了任务', suggestedWords: '妈，今天的任务完成得很棒，辛苦啦！' },
      { id: 'walk-chat', title: '从散步聊起', suggestedWords: '妈，下午散步时看到什么有意思的事了吗？' },
    ];
  }

  addHealthReading(body: Record<string, unknown>) {
    const reading = { id: randomUUID(), ...body, confirmedByUser: true, createdAt: new Date().toISOString() };
    this.readings.push(reading);
    const systolic = Number(body.systolic ?? 0);
    const diastolic = Number(body.diastolic ?? 0);
    if (systolic >= 160 || diastolic >= 100) {
      this.alerts.push({
        id: randomUUID(),
        level: 'L2',
        metric: 'bloodPressure',
        message: '本次记录偏高，请再次确认数据，并联系医生了解情况；如感到明显不适，请联系当地急救服务。',
        createdAt: new Date().toISOString(),
      });
    } else if (systolic >= 140 || diastolic >= 90) {
      this.alerts.push({
        id: randomUUID(),
        level: 'L1',
        metric: 'bloodPressure',
        message: '本次记录需要关注，请稍后复测并按医生建议管理。',
        createdAt: new Date().toISOString(),
      });
    }
    return reading;
  }

  exportData() {
    return {
      generatedAt: new Date().toISOString(),
      family: this.createFamily(),
      plans: this.plans,
      tasks: this.tasks,
      healthReadings: this.readings,
      alerts: this.alerts,
    };
  }

  scheduleDeletion() {
    return { status: 'scheduled', deleteAfter: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() };
  }
}
