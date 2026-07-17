import { IsIn, IsOptional } from 'class-validator';
import { Role } from '../fubao.types';

export class TestLoginDto {
  @IsOptional()
  @IsIn(['child', 'elder'])
  role?: Role;
}
