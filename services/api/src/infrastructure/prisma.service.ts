import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly enabled: boolean;

  constructor(config: ConfigService) {
    const connectionString =
      config.get<string>('DATABASE_URL') ??
      'postgresql://fubao:fubao@127.0.0.1:5432/fubao';
    super({ adapter: new PrismaPg({ connectionString }) });
    this.enabled = config.get('PERSISTENCE_DRIVER') === 'postgres';
  }

  async onModuleInit(): Promise<void> {
    if (this.enabled) await this.$connect();
  }

  async onModuleDestroy(): Promise<void> {
    if (this.enabled) await this.$disconnect();
  }
}
