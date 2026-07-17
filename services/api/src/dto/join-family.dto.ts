import { Matches } from 'class-validator';

export class JoinFamilyDto {
  @Matches(/^\d{4}$/, { message: '邀请码必须是4位数字' })
  code!: string;
}
