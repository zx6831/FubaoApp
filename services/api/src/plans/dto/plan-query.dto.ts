import { IsIn, IsOptional, IsString, Matches } from 'class-validator';

export class TaskDateQueryDto {
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  date?: string;
}

export class TaskHistoryQueryDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  from!: string;

  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  to!: string;
}

export class UpdatePlanStatusDto {
  @IsIn(['active', 'paused', 'ended'])
  status!: 'active' | 'paused' | 'ended';
}
