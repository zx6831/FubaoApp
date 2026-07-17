import { Module } from '@nestjs/common';
import { FamilyModule } from '../families/family.module';
import { EngagementController } from './engagement.controller';
import { EngagementService } from './engagement.service';

@Module({ imports: [FamilyModule], controllers: [EngagementController], providers: [EngagementService] })
export class EngagementModule {}
