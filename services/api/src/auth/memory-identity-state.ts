import { Injectable } from '@nestjs/common';
import { AppRole } from './auth.types';

export interface MemoryUser {
  id: string;
  phoneHash: string;
  phoneCiphertext: string;
  nickname: string;
  role: AppRole;
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
}
