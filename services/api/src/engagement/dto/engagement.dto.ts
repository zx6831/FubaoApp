import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class MessagesQueryDto {
  @IsOptional()
  @IsIn(['weeklyReport', 'alert', 'system', 'insight'])
  type?: 'weeklyReport' | 'alert' | 'system' | 'insight';
}

export class FeedbackDto {
  @IsString()
  @MaxLength(1000)
  content!: string;
}
