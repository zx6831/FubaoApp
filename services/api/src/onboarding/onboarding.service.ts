import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { AuthenticatedUser } from '../auth/auth.types';
import { MemoryDevice, MemoryIdentityState } from '../auth/memory-identity-state';
import { SecurityService } from '../auth/security.service';
import { Prisma } from '../generated/prisma/client';
import { PrismaService } from '../infrastructure/prisma.service';
import { ActivateDeviceDto } from './dto/activate-device.dto';
import { UpdateDeviceSettingsDto } from './dto/update-device-settings.dto';
import { UpsertHealthProfileDto } from './dto/upsert-health-profile.dto';
import { DeviceAdapter } from './device-adapter';

@Injectable()
export class OnboardingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly memory: MemoryIdentityState,
    private readonly security: SecurityService,
    private readonly deviceAdapter: DeviceAdapter,
  ) {}

  async status(user: AuthenticatedUser) {
    const context = await this.familyContext(user);
    if (this.prisma.isEnabled()) {
      const [profile, device] = await Promise.all([
        context.elderUserId ? this.prisma.healthProfile.findUnique({ where: { userId: context.elderUserId } }) : null,
        this.prisma.device.findUnique({ where: { familyId: context.familyId } }),
      ]);
      return this.statusResult(context.elderUserId !== null, profile !== null, device?.activatedAt != null && device.status !== 'unbound');
    }
    const profile = context.elderUserId ? this.memory.healthProfiles.get(context.elderUserId) : null;
    const device = this.memory.devices.get(context.familyId);
    return this.statusResult(context.elderUserId !== null, profile != null, device?.activatedAt != null && device.status !== 'unbound');
  }

  async getProfile(user: AuthenticatedUser) {
    const context = await this.familyContext(user);
    if (!context.elderUserId) throw new NotFoundException('家庭尚未绑定长辈');
    if (this.prisma.isEnabled()) {
      const profile = await this.prisma.healthProfile.findUnique({ where: { userId: context.elderUserId } });
      if (!profile) throw new NotFoundException('尚未建立健康档案');
      return this.serializeProfile(profile);
    }
    const profile = this.memory.healthProfiles.get(context.elderUserId);
    if (!profile) throw new NotFoundException('尚未建立健康档案');
    return this.serializeProfile(profile);
  }

  async upsertProfile(user: AuthenticatedUser, body: UpsertHealthProfileDto) {
    if (user.role !== 'child') throw new ForbiddenException('只有子女端可以编辑健康档案');
    if (!body.consentConfirmed) throw new BadRequestException('请先确认已获得长辈授权');
    const context = await this.familyContext(user);
    if (!context.elderUserId) throw new NotFoundException('家庭尚未绑定长辈');
    const data = {
      familyId: context.familyId,
      relativeName: body.relativeName.trim(),
      heightCm: body.heightCm,
      weightKg: body.weightKg,
      chronicConditions: body.chronicConditions,
      medicationHistory: body.medicationHistory as Prisma.InputJsonValue | undefined,
      medicalHistory: body.medicalHistory as Prisma.InputJsonValue | undefined,
      emergencyContactCiphertext: body.emergencyContact ? this.security.encrypt(body.emergencyContact) : undefined,
      consentAt: new Date(),
    };
    if (this.prisma.isEnabled()) {
      const profile = await this.prisma.healthProfile.upsert({
        where: { userId: context.elderUserId },
        create: { ...data, userId: context.elderUserId },
        update: data,
      });
      return this.serializeProfile(profile);
    }
    const profile = { ...data, userId: context.elderUserId };
    this.memory.healthProfiles.set(context.elderUserId, profile);
    return this.serializeProfile(profile);
  }

  async discoverDevices(user: AuthenticatedUser) {
    this.assertChild(user);
    const context = await this.familyContext(user);
    const [candidate] = await this.deviceAdapter.discover(context.familyId);
    const { serialNumber, firmware } = candidate;
    if (this.prisma.isEnabled()) {
      const device = await this.prisma.device.upsert({
        where: { familyId: context.familyId },
        create: { familyId: context.familyId, serialNumber, firmware, status: 'discovered' },
        update: { serialNumber, firmware, status: 'discovered', unboundAt: null },
        include: { settings: true },
      });
      return { devices: [this.serializeDevice(device)] };
    }
    const existing = this.memory.devices.get(context.familyId);
    const device = existing ?? this.newMemoryDevice(context.familyId, serialNumber);
    device.status = 'discovered';
    device.unboundAt = null;
    this.memory.devices.set(context.familyId, device);
    return { devices: [this.serializeDevice(device)] };
  }

  async activateDevice(user: AuthenticatedUser, body: ActivateDeviceDto) {
    this.assertChild(user);
    const context = await this.familyContext(user);
    const provisioned = await this.deviceAdapter.provision(body.serialNumber, body.networkName);
    if (!provisioned.online) throw new BadRequestException('设备配网失败，请检查网络名称');
    if (this.prisma.isEnabled()) {
      const existing = await this.prisma.device.findUnique({ where: { familyId: context.familyId } });
      if (!existing || existing.serialNumber !== body.serialNumber) throw new NotFoundException('请先发现并选择设备');
      const now = new Date();
      const device = await this.prisma.device.update({
        where: { id: existing.id },
        data: {
          status: 'online',
          activatedAt: now,
          lastOnlineAt: now,
          unboundAt: null,
          settings: { upsert: { create: {}, update: {} } },
          events: { create: { type: 'activated', payload: { networkName: body.networkName } } },
        },
        include: { settings: true },
      });
      return this.serializeDevice(device);
    }
    const device = this.memory.devices.get(context.familyId);
    if (!device || device.serialNumber !== body.serialNumber) throw new NotFoundException('请先发现并选择设备');
    device.status = 'online';
    device.activatedAt = new Date();
    device.lastOnlineAt = new Date();
    return this.serializeDevice(device);
  }

  async currentDevice(user: AuthenticatedUser) {
    const context = await this.familyContext(user);
    if (this.prisma.isEnabled()) {
      const device = await this.prisma.device.findUnique({ where: { familyId: context.familyId }, include: { settings: true } });
      if (!device) throw new NotFoundException('尚未绑定设备');
      if (device.status === 'unbound') return { status: 'unbound' };
      return this.serializeDevice(device);
    }
    const device = this.memory.devices.get(context.familyId);
    if (!device) throw new NotFoundException('尚未绑定设备');
    if (device.status === 'unbound') return { status: 'unbound' };
    return this.serializeDevice(device);
  }

  async updateSettings(user: AuthenticatedUser, body: UpdateDeviceSettingsDto) {
    this.assertChild(user);
    const context = await this.familyContext(user);
    if (this.prisma.isEnabled()) {
      const device = await this.prisma.device.findUnique({ where: { familyId: context.familyId } });
      if (!device || device.status === 'unbound') throw new NotFoundException('尚未绑定设备');
      const settings = await this.prisma.deviceSettings.upsert({
        where: { deviceId: device.id },
        create: { deviceId: device.id, ...body },
        update: body,
      });
      return settings;
    }
    const device = this.memory.devices.get(context.familyId);
    if (!device || device.status === 'unbound') throw new NotFoundException('尚未绑定设备');
    device.settings = { ...body };
    return device.settings;
  }

  async setDeviceStatus(user: AuthenticatedUser, status: 'online' | 'offline') {
    this.assertChild(user);
    const context = await this.familyContext(user);
    if (this.prisma.isEnabled()) {
      const device = await this.prisma.device.findUnique({ where: { familyId: context.familyId } });
      if (!device || device.status === 'unbound') throw new NotFoundException('尚未绑定设备');
      return this.serializeDevice(await this.prisma.device.update({
        where: { id: device.id },
        data: { status, lastOnlineAt: status === 'online' ? new Date() : device.lastOnlineAt, events: { create: { type: `status.${status}` } } },
        include: { settings: true },
      }));
    }
    const device = this.memory.devices.get(context.familyId);
    if (!device || device.status === 'unbound') throw new NotFoundException('尚未绑定设备');
    device.status = status;
    if (status === 'online') device.lastOnlineAt = new Date();
    return this.serializeDevice(device);
  }

  async unbindDevice(user: AuthenticatedUser) {
    this.assertChild(user);
    const context = await this.familyContext(user);
    const retainUntil = new Date(Date.now() + 90 * 24 * 60 * 60 * 1000);
    if (this.prisma.isEnabled()) {
      const device = await this.prisma.device.findUnique({ where: { familyId: context.familyId } });
      if (!device) throw new NotFoundException('尚未绑定设备');
      await this.prisma.device.update({ where: { id: device.id }, data: { status: 'unbound', unboundAt: new Date(), events: { create: { type: 'unbound' } } } });
    } else {
      const device = this.memory.devices.get(context.familyId);
      if (!device) throw new NotFoundException('尚未绑定设备');
      device.status = 'unbound';
      device.unboundAt = new Date();
    }
    return { unbound: true, dataRetainedUntil: retainUntil.toISOString() };
  }

  async factoryReset(user: AuthenticatedUser) {
    this.assertChild(user);
    const context = await this.familyContext(user);
    const defaults = { volume: 60, speechRate: 50, dndEnabled: true, dndStart: '22:00', dndEnd: '07:00' };
    if (this.prisma.isEnabled()) {
      const device = await this.prisma.device.findUnique({ where: { familyId: context.familyId } });
      if (!device) throw new NotFoundException('尚未绑定设备');
      return this.serializeDevice(await this.prisma.device.update({
        where: { id: device.id },
        data: { settings: { upsert: { create: defaults, update: defaults } }, events: { create: { type: 'factoryReset' } } },
        include: { settings: true },
      }));
    }
    const device = this.memory.devices.get(context.familyId);
    if (!device) throw new NotFoundException('尚未绑定设备');
    device.settings = defaults;
    return this.serializeDevice(device);
  }

  private async familyContext(user: AuthenticatedUser): Promise<{ familyId: string; elderUserId: string | null }> {
    if (this.prisma.isEnabled()) {
      const membership = await this.prisma.familyMember.findFirst({
        where: { userId: user.sub, status: 'active', family: { status: 'active' } },
        include: { family: { include: { members: { where: { status: 'active' } } } } },
      });
      if (!membership) throw new NotFoundException('尚未加入家庭');
      return { familyId: membership.familyId, elderUserId: membership.family.members.find((member) => member.role === 'elder')?.userId ?? null };
    }
    const family = [...this.memory.families.values()].find((item) => item.members.some((member) => member.userId === user.sub));
    if (!family) throw new NotFoundException('尚未加入家庭');
    return { familyId: family.id, elderUserId: family.members.find((member) => member.role === 'elder')?.userId ?? null };
  }

  private statusResult(familyBound: boolean, profileComplete: boolean, deviceActive: boolean) {
    return { familyBound, profileComplete, deviceActive, complete: familyBound && profileComplete && deviceActive };
  }

  private assertChild(user: AuthenticatedUser) {
    if (user.role !== 'child') throw new ForbiddenException('只有子女端可以管理设备');
  }

  private serializeProfile(profile: any) {
    return {
      userId: profile.userId,
      relativeName: profile.relativeName,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg == null ? null : Number(profile.weightKg),
      chronicConditions: profile.chronicConditions,
      medicationHistory: profile.medicationHistory ?? null,
      medicalHistory: profile.medicalHistory ?? null,
      emergencyContact: profile.emergencyContactCiphertext ? this.security.decrypt(profile.emergencyContactCiphertext) : null,
      consentAt: profile.consentAt.toISOString(),
    };
  }

  private serializeDevice(device: any) {
    return {
      id: device.id,
      serialNumber: device.serialNumber,
      firmware: device.firmware,
      status: device.status,
      lastOnlineAt: device.lastOnlineAt?.toISOString() ?? null,
      activatedAt: device.activatedAt?.toISOString() ?? null,
      settings: device.settings ?? null,
    };
  }

  private newMemoryDevice(familyId: string, serialNumber: string): MemoryDevice {
    return {
      id: randomUUID(), familyId, serialNumber, firmware: '1.0.0', status: 'discovered', lastOnlineAt: null, activatedAt: null, unboundAt: null,
      settings: { volume: 60, speechRate: 50, dndEnabled: true, dndStart: '22:00', dndEnd: '07:00' },
    };
  }
}
