import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly enabled: boolean;
  private readonly client: Redis;

  constructor(config: ConfigService) {
    const redisUrl = config.get<string>('REDIS_URL') ?? 'redis://127.0.0.1:6379';
    this.enabled =
      config.get('PERSISTENCE_DRIVER') === 'postgres' &&
      config.get<string>('REDIS_URL') !== undefined;
    this.client = new Redis(redisUrl, {
      lazyConnect: true,
      maxRetriesPerRequest: 1,
      enableOfflineQueue: false,
    });
  }

  async onModuleInit(): Promise<void> {
    if (this.enabled) await this.client.connect();
  }

  async onModuleDestroy(): Promise<void> {
    if (!this.enabled) return;
    if (this.client.status === 'ready') {
      await this.client.quit();
    } else if (this.client.status !== 'end') {
      this.client.disconnect();
    }
  }

  connection(): Redis {
    return this.client;
  }
}
