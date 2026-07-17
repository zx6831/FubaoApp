import { IsArray, IsBoolean, IsNumber, IsObject, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class UpsertHealthProfileDto {
  @IsString()
  @MaxLength(20)
  relativeName!: string;

  @IsOptional()
  @IsNumber()
  @Min(80)
  @Max(250)
  heightCm?: number;

  @IsOptional()
  @IsNumber()
  @Min(20)
  @Max(300)
  weightKg?: number;

  @IsArray()
  @IsString({ each: true })
  chronicConditions!: string[];

  @IsOptional()
  @IsObject()
  medicationHistory?: Record<string, unknown>;

  @IsOptional()
  @IsObject()
  medicalHistory?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  emergencyContact?: string;

  @IsBoolean()
  consentConfirmed!: boolean;
}
