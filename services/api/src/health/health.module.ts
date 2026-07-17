import { Module } from '@nestjs/common';
import { FamilyModule } from '../families/family.module';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';

@Module({
  imports: [FamilyModule],
  controllers: [HealthController],
  providers: [HealthService],
  exports: [HealthService],
})
export class HealthModule {}
