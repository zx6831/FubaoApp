import { Injectable } from '@nestjs/common';
import { AppRole } from './auth.types';

export interface MemoryUser {
  id: string;
  phoneHash: string;
  phoneCiphertext: string;
  nickname: string;
  role: AppRole;
  deletedAt: Date | null;
}

export interface MemorySession {
  userId: string;
  refreshTokenHash: string;
  expiresAt: Date;
  revokedAt: Date | null;
}

export interface MemoryFamily {
  id: string;
  ownerId: string;
  members: Array<{ userId: string; role: AppRole; nickname: string }>;
}

export interface MemoryInvitation {
  familyId: string;
  codeDigest: string;
  expiresAt: Date;
  usedAt: Date | null;
}

export interface MemoryHealthProfile {
  familyId: string;
  userId: string;
  relativeName: string;
  heightCm?: number;
  weightKg?: number;
  chronicConditions: string[];
  medicationHistory?: unknown;
  medicalHistory?: unknown;
  emergencyContactCiphertext?: string;
  consentAt: Date;
}

export interface MemoryDevice {
  id: string;
  familyId: string;
  serialNumber: string;
  firmware: string;
  status: 'discovered' | 'provisioning' | 'online' | 'offline' | 'unbound';
  lastOnlineAt: Date | null;
  activatedAt: Date | null;
  unboundAt: Date | null;
  settings: {
    volume: number;
    speechRate: number;
    dndEnabled: boolean;
    dndStart: string;
    dndEnd: string;
  };
}

export type MemoryTaskKind = 'medicine' | 'bloodPressure' | 'bloodGlucose' | 'walk' | 'mood' | 'weight' | 'custom';
export type MemoryPlanStatus = 'active' | 'paused' | 'ended';
export type MemoryTaskStatus = 'pending' | 'completed' | 'skipped' | 'abnormal';

export interface MemoryPlan {
  id: string;
  familyId: string;
  subjectUserId: string;
  createdById: string;
  kind: MemoryTaskKind;
  title: string;
  subtitle?: string;
  timezone: 'Asia/Shanghai';
  schedule: { time: string; daysOfWeek: number[] };
  enrollmentData?: unknown;
  status: MemoryPlanStatus;
  startsAt: Date;
  pausedAt: Date | null;
  endedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface MemoryDailyTask {
  id: string;
  familyId: string;
  planId: string;
  userId: string;
  date: string;
  kind: MemoryTaskKind;
  title: string;
  subtitle?: string;
  reminderAt: Date;
  remindedAt: Date | null;
  status: MemoryTaskStatus;
  createdAt: Date;
  updatedAt: Date;
  record?: {
    id: string;
    idempotencyKey: string;
    status: MemoryTaskStatus;
    source: string;
    data?: unknown;
    completedAt: Date;
  };
}

export interface MemoryHealthReadingV1 {
  id: string;
  familyId: string;
  userId: string;
  metric: 'bloodPressure' | 'bloodGlucose' | 'mood' | 'weight';
  value: Record<string, unknown>;
  source: string;
  confirmedByUser: boolean;
  recordedAt: Date;
  createdAt: Date;
}

export interface MemoryAlertV1 {
  id: string;
  familyId: string;
  userId: string;
  healthReadingId: string;
  level: 'L1' | 'L2';
  metric: 'bloodPressure' | 'bloodGlucose' | 'mood' | 'weight';
  message: string;
  status: 'pending' | 'handled' | 'closed';
  closeReason?: string;
  dedupeKey: string;
  handledAt?: Date;
  createdAt: Date;
}

export interface MemorySparkActivityV1 {
  familyId: string;
  date: string;
  childActive: boolean;
  elderActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class MemoryIdentityState {
  readonly verificationCodes = new Map<string, { code: string; expiresAt: Date }>();
  readonly usersByPhoneHash = new Map<string, MemoryUser>();
  readonly usersById = new Map<string, MemoryUser>();
  readonly sessions = new Map<string, MemorySession>();
  readonly families = new Map<string, MemoryFamily>();
  readonly invitations = new Map<string, MemoryInvitation>();
  readonly healthProfiles = new Map<string, MemoryHealthProfile>();
  readonly devices = new Map<string, MemoryDevice>();
  readonly plans = new Map<string, MemoryPlan>();
  readonly dailyTasks = new Map<string, MemoryDailyTask>();
  readonly taskRecordsByIdempotencyKey = new Map<string, MemoryDailyTask['record']>();
  readonly healthReadingsV1 = new Map<string, MemoryHealthReadingV1>();
  readonly alertsV1 = new Map<string, MemoryAlertV1>();
  readonly sparkActivitiesV1 = new Map<string, MemorySparkActivityV1>();
  readonly engagementTopics = new Map<string, Record<string, any>>();
  readonly engagementMessages = new Map<string, Record<string, any>>();
  readonly deletionRequestsV1 = new Map<string, { requestedAt: Date; deleteAfter: Date; completedAt: Date | null }>();
  readonly feedbackV1: Array<{ userId: string; content: string; createdAt: Date }> = [];
}
