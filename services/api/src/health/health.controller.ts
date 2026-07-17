import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/current-user.decorator';
import { CreateHealthReadingDto, HealthReadingsQueryDto, SparkHistoryQueryDto, UpdateAlertDto } from './dto/health.dto';
import { HealthService } from './health.service';

@ApiBearerAuth()
@ApiTags('health-sparks-alerts')
@Controller()
export class HealthController {
  constructor(private readonly health: HealthService) {}

  @Post('health-data')
  create(@CurrentUser() user: AuthenticatedUser, @Body() body: CreateHealthReadingDto) {
    return this.health.createReading(user, body);
  }

  @Get('health-data')
  readings(@CurrentUser() user: AuthenticatedUser, @Query() query: HealthReadingsQueryDto) {
    return this.health.readings(user, query);
  }

  @Get('health-data/:id')
  reading(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.health.reading(user, id);
  }

  @Get('alerts')
  alerts(@CurrentUser() user: AuthenticatedUser) {
    return this.health.alerts(user);
  }

  @Patch('alerts/:id')
  updateAlert(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Body() body: UpdateAlertDto) {
    return this.health.updateAlert(user, id, body);
  }

  @Get('sparks/current')
  spark(@CurrentUser() user: AuthenticatedUser) {
    return this.health.currentSpark(user);
  }

  @Post('sparks/activity')
  activity(@CurrentUser() user: AuthenticatedUser) {
    return this.health.currentSpark(user);
  }

  @Get('sparks/history')
  sparkHistory(@CurrentUser() user: AuthenticatedUser, @Query() query: SparkHistoryQueryDto) {
    return this.health.sparkHistory(user, query.from, query.to);
  }
}
