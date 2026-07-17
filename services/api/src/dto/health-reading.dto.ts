import { IsIn, IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';

export class HealthReadingDto {
  @IsString()
  @IsIn(['bloodPressure', 'bloodGlucose', 'mood', 'weight'])
  type!: string;

  @IsOptional()
  @IsNumber()
  systolic?: number;

  @IsOptional()
  @IsNumber()
  diastolic?: number;

  @IsOptional()
  @IsNumber()
  value?: number;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  textValue?: string;
}
