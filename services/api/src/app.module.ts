import { Module } from '@nestjs/common';
import { FubaoController } from './fubao.controller';
import { FubaoService } from './fubao.service';

@Module({
  controllers: [FubaoController],
  providers: [FubaoService],
})
export class AppModule {}
