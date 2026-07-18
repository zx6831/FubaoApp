import { IsIn, IsString, Matches } from 'class-validator';

export class PushTokenDto {
  @IsString()
  @Matches(/^[a-fA-F0-9]{32,256}$/)
  token!: string;

  @IsIn(['ios'])
  platform!: 'ios';

  @IsIn(['demo', 'dev', 'production'])
  environment!: 'demo' | 'dev' | 'production';
}
