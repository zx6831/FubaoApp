import { Body, Controller, Get, Headers, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthenticatedUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/current-user.decorator';
import { Roles } from '../auth/roles.decorator';
import { CreatePlanV1Dto } from './dto/create-plan-v1.dto';
import { TaskDateQueryDto, TaskHistoryQueryDto, UpdatePlanStatusDto } from './dto/plan-query.dto';
import { RecordTaskDto } from './dto/record-task.dto';
import { PlansService } from './plans.service';

@ApiBearerAuth()
@ApiTags('plans-and-tasks')
@Controller()
export class PlansController {
  constructor(private readonly plans: PlansService) {}

  @Get('plans')
  @ApiOperation({ summary: '查看家庭计划，历史计划不会被删除' })
  listPlans(@CurrentUser() user: AuthenticatedUser) {
    return this.plans.list(user);
  }

  @Get('plans/:id')
  plan(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.plans.get(user, id);
  }

  @Roles('child')
  @Post('plans')
  createPlan(@CurrentUser() user: AuthenticatedUser, @Body() body: CreatePlanV1Dto) {
    return this.plans.create(user, body);
  }

  @Roles('child')
  @Patch('plans/:id/status')
  updatePlanStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: UpdatePlanStatusDto,
  ) {
    return this.plans.updateStatus(user, id, body.status);
  }

  @Get('tasks')
  tasks(@CurrentUser() user: AuthenticatedUser, @Query() query: TaskDateQueryDto) {
    return this.plans.tasksForDate(user, query.date);
  }

  @Get('tasks/today')
  today(@CurrentUser() user: AuthenticatedUser) {
    return this.plans.tasksForDate(user);
  }

  @Get('tasks/history')
  history(@CurrentUser() user: AuthenticatedUser, @Query() query: TaskHistoryQueryDto) {
    return this.plans.history(user, query.from, query.to);
  }

  @Roles('elder')
  @Post('tasks/:id/complete')
  complete(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Headers('idempotency-key') key: string | undefined,
    @Body() body: RecordTaskDto,
  ) {
    return this.plans.record(user, id, 'completed', key, body.data);
  }

  @Roles('elder')
  @Post('tasks/:id/skip')
  skip(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Headers('idempotency-key') key: string | undefined,
    @Body() body: RecordTaskDto,
  ) {
    return this.plans.record(user, id, 'skipped', key, body.data);
  }

  @Roles('child')
  @Post('tasks/:id/remind')
  remind(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.plans.remind(user, id);
  }
}
