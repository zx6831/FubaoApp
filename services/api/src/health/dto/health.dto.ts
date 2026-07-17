import { Type } from 'class-transformer';
import {
  Equals, IsBoolean, IsDateString, IsIn, IsNumber, IsObject, IsOptional,
  IsString, MaxLength, ValidateIf,
} from 'class-validator';

export class CreateHealthReadingDto {
  @IsIn(['bloodPressure', 'bloodGlucose', 'mood', 'weight'])
  type!: 'bloodPressure' | 'bloodGlucose' | 'mood' | 'weight';

  @ValidateIf((body: CreateHealthReadingDto) => body.type === 'bloodPressure')
  @Type(() => Number)
  @IsNumber()
  systolic?: number;

  @ValidateIf((body: CreateHealthReadingDto) => body.type === 'bloodPressure')
  @Type(() => Number)
  @IsNumber()
  diastolic?: number;

  @ValidateIf((body: CreateHealthReadingDto) => ['bloodGlucose', 'weight'].includes(body.type))
  @Type(() => Number)
  @IsNumber()
  value?: number;

  @ValidateIf((body: CreateHealthReadingDto) => body.type === 'mood')
  @IsString()
  @MaxLength(40)
  textValue?: string;

  @IsBoolean()
  @Equals(true)
  confirmedByUser!: true;

  @IsOptional()
  @IsDateString()
  recordedAt?: string;
}

export class HealthReadingsQueryDto {
  @IsOptional()
  @IsIn(['bloodPressure', 'bloodGlucose', 'mood', 'weight'])
  metric?: 'bloodPressure' | 'bloodGlucose' | 'mood' | 'weight';

  @IsOptional()
  @IsDateString()
  from?: string;

  @IsOptional()
  @IsDateString()
  to?: string;
}

export class UpdateAlertDto {
  @IsIn(['handled', 'closed'])
  status!: 'handled' | 'closed';

  @ValidateIf((body: UpdateAlertDto) => body.status === 'closed')
  @IsString()
  @MaxLength(120)
  closeReason?: string;
}

export class SparkHistoryQueryDto {
  @IsString()
  from!: string;

  @IsString()
  to!: string;
}
