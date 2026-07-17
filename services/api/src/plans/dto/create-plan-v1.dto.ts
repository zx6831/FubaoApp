import { Type } from 'class-transformer';
import {
  ArrayMaxSize, ArrayMinSize, ArrayUnique, IsArray, IsIn, IsInt,
  IsObject, IsOptional, IsString, Matches, Max, MaxLength, Min, ValidateNested,
} from 'class-validator';

export const taskKinds = ['medicine', 'bloodPressure', 'bloodGlucose', 'walk', 'mood', 'weight', 'custom'] as const;
export type PlanTaskKind = (typeof taskKinds)[number];

export class PlanScheduleDto {
  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/)
  time!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(7)
  @ArrayUnique()
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(7, { each: true })
  daysOfWeek!: number[];
}

export class CreatePlanV1Dto {
  @IsIn(taskKinds)
  kind!: PlanTaskKind;

  @IsString()
  @MaxLength(80)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  subtitle?: string;

  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  startsOn!: string;

  @IsIn(['Asia/Shanghai'])
  timezone!: 'Asia/Shanghai';

  @ValidateNested()
  @Type(() => PlanScheduleDto)
  schedule!: PlanScheduleDto;

  @IsOptional()
  @IsObject()
  enrollmentData?: Record<string, unknown>;
}
