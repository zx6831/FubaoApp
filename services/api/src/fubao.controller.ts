import { Controller, Delete, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Public } from './auth/public.decorator';
import { FubaoService } from './fubao.service';

@ApiTags('fubao')
@Controller()
export class FubaoController {
  constructor(private readonly service: FubaoService) {}

  @Get('health')
  @Public()
  @ApiOperation({ summary: '服务健康检查' })
  health() {
    return { status: 'ok', service: 'fubao-api' };
  }

  @Get('topics/today')
  topics() {
    return this.service.todayTopics();
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
