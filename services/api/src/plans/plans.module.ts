import { Module } from '@nestjs/common';
import { FamilyModule } from '../families/family.module';
import { HealthModule } from '../health/health.module';
import { PlansController } from './plans.controller';
import { PlansService } from './plans.service';

@Module({
  imports: [FamilyModule, HealthModule],
  controllers: [PlansController],
  providers: [PlansService],
})
export class PlansModule {}
