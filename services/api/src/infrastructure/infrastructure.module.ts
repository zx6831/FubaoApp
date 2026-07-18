import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaService } from './prisma.service';
import { RedisService } from './redis.service';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [PrismaService, RedisService],
  exports: [PrismaService, RedisService],
})
export class InfrastructureModule {}
