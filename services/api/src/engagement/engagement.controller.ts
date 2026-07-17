import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/current-user.decorator';
import { EngagementService } from './engagement.service';
import { FeedbackDto, MessagesQueryDto } from './dto/engagement.dto';

@ApiBearerAuth()
@ApiTags('topics-messages-privacy')
@Controller()
export class EngagementController {
  constructor(private readonly engagement: EngagementService) {}
  @Get('topics/today') topics(@CurrentUser() user: AuthenticatedUser) { return this.engagement.topics(user); }
  @Post('topics/:id/copied') copied(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) { return this.engagement.copied(user, id); }
  @Get('messages') messages(@CurrentUser() user: AuthenticatedUser, @Query() query: MessagesQueryDto) { return this.engagement.messages(user, query.type); }
  @Patch('messages/:id/read') read(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) { return this.engagement.readMessage(user, id); }
  @Get('reports/weekly') report(@CurrentUser() user: AuthenticatedUser) { return this.engagement.weeklyReport(user); }
  @Get('privacy/export') exportData(@CurrentUser() user: AuthenticatedUser) { return this.engagement.exportData(user); }
  @Delete('privacy/account') deleteAccount(@CurrentUser() user: AuthenticatedUser) { return this.engagement.scheduleDeletion(user); }
  @Get('privacy/account') deletion(@CurrentUser() user: AuthenticatedUser) { return this.engagement.deletionStatus(user); }
  @Post('feedback') feedback(@CurrentUser() user: AuthenticatedUser, @Body() body: FeedbackDto) { return this.engagement.feedback(user, body.content); }
}
