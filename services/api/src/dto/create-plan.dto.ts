import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CreatePlanDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  title?: string;
}
