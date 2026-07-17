import { IsObject, IsOptional } from 'class-validator';

export class RecordTaskDto {
  @IsOptional()
  @IsObject()
  data?: Record<string, unknown>;
}
