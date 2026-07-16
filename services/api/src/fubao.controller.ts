import { Body, Controller, Delete, Get, Headers, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { FubaoService } from './fubao.service';
import { Role } from './fubao.types';

@ApiTags('fubao')
@Controller()
export class FubaoController {
  constructor(private readonly service: FubaoService) {}

  @Get('health')
  @ApiOperation({ summary: '服务健康检查' })
  health() {
    return { status: 'ok', service: 'fubao-api' };
  }

  @Post('auth/test-login')
  testLogin(@Body() body: { role?: Role }) {
    return this.service.testLogin(body.role === 'elder' ? 'elder' : 'child');
  }

  @ApiBearerAuth()
  @Post('families')
  createFamily() {
    return this.service.createFamily();
  }

  @ApiBearerAuth()
  @Post('families/invitations')
  createInvitation() {
    return this.service.createInvitation();
  }

  @Post('families/join')
  joinFamily(@Body() body: { code: string }) {
    return this.service.joinFamily(body.code);
  }

  @Get('plans')
  plans() {
    return this.service.plans;
  }

  @Post('plans')
  createPlan(@Body() body: { title?: string }) {
    return this.service.createPlan(body.title?.trim() || '自定义计划');
  }

  @Get('tasks/today')
  tasks() {
    return this.service.tasks;
  }

  @Post('tasks/:id/complete')
  completeTask(@Param('id') id: string, @Headers('idempotency-key') key?: string) {
    return this.service.completeTask(id, key);
  }

  @Get('sparks/current')
  spark() {
    return this.service.currentSpark();
  }

  @Get('topics/today')
  topics() {
    return this.service.todayTopics();
  }

  @Post('health-data')
  healthData(@Body() body: Record<string, unknown>) {
    return this.service.addHealthReading(body);
  }

  @Get('alerts')
  alerts() {
    return this.service.exportData().alerts;
  }

  @Get('privacy/export')
  exportData() {
    return this.service.exportData();
  }

  @Delete('privacy/account')
  deleteAccount() {
    return this.service.scheduleDeletion();
  }
}
