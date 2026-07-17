import { Global, Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { MemoryIdentityState } from './memory-identity-state';
import { SecurityService } from './security.service';

@Global()
@Module({
  controllers: [AuthController],
  providers: [AuthService, MemoryIdentityState, SecurityService],
  exports: [MemoryIdentityState, SecurityService],
})
export class AuthModule {}
