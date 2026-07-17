import { Module } from '@nestjs/common';
import { FamilyModule } from '../families/family.module';
import { PlansController } from './plans.controller';
import { PlansService } from './plans.service';

@Module({
  imports: [FamilyModule],
  controllers: [PlansController],
  providers: [PlansService],
})
export class PlansModule {}
