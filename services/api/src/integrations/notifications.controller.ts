import { Body, Controller, Delete, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/current-user.decorator';
import { PushTokenDto } from './dto/push-token.dto';
import { NotificationsService } from './notifications.service';

@ApiBearerAuth()
@ApiTags('notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Post('device-token')
  register(@CurrentUser() user: AuthenticatedUser, @Body() body: PushTokenDto) {
    return this.notifications.register(user, body);
  }

  @Delete('device-token')
  unregister(@CurrentUser() user: AuthenticatedUser, @Query('token') token: string) {
    return this.notifications.unregister(user, token);
  }
}
