import { IsIn, IsString, Matches } from 'class-validator';
import { AppRole } from '../auth.types';

export class VerifyCodeDto {
  @IsString()
  @Matches(/^1\d{10}$/)
  phone!: string;

  @IsString()
  @Matches(/^\d{4,6}$/)
  code!: string;

  @IsIn(['child', 'elder'])
  role!: AppRole;
}
