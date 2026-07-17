import { Module, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR, APP_PIPE } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AllExceptionsFilter } from './common/all-exceptions.filter';
import { ApiResponseInterceptor } from './common/api-response.interceptor';
import { AuditInterceptor } from './common/audit.interceptor';
import { AccessTokenGuard } from './auth/access-token.guard';
import { AuthModule } from './auth/auth.module';
import { RolesGuard } from './auth/roles.guard';
import { FamilyModule } from './families/family.module';
import { OnboardingModule } from './onboarding/onboarding.module';
import { PlansModule } from './plans/plans.module';
import { HealthModule } from './health/health.module';
import { EngagementModule } from './engagement/engagement.module';
import { FubaoController } from './fubao.controller';
import { FubaoService } from './fubao.service';
import { validateEnvironment } from './infrastructure/environment';
import { InfrastructureModule } from './infrastructure/infrastructure.module';
import { IntegrationsModule } from './integrations/integrations.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      validate: validateEnvironment,
    }),
    ThrottlerModule.forRoot([
      { name: 'per-second', ttl: 1_000, limit: 10 },
      { name: 'per-minute', ttl: 60_000, limit: 100 },
    ]),
    InfrastructureModule,
    IntegrationsModule,
    AuthModule,
    FamilyModule,
    OnboardingModule,
    PlansModule,
    HealthModule,
    EngagementModule,
  ],
  controllers: [FubaoController],
  providers: [
    FubaoService,
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: AccessTokenGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    { provide: APP_INTERCEPTOR, useClass: ApiResponseInterceptor },
    { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({
        transform: true,
        whitelist: true,
        forbidNonWhitelisted: true,
      }),
    },
  ],
})
export class AppModule {}
