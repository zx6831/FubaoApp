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

@Injectable()
export class MemoryIdentityState {
  readonly verificationCodes = new Map<string, { code: string; expiresAt: Date }>();
  readonly usersByPhoneHash = new Map<string, MemoryUser>();
  readonly usersById = new Map<string, MemoryUser>();
  readonly sessions = new Map<string, MemorySession>();
  readonly families = new Map<string, MemoryFamily>();
  readonly invitations = new Map<string, MemoryInvitation>();
}
