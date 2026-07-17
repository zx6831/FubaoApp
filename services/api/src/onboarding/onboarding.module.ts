import { Module } from '@nestjs/common';
import { OnboardingController } from './onboarding.controller';
import { OnboardingService } from './onboarding.service';
import { DeviceAdapter } from './device-adapter';
import { SimulatedDeviceAdapter } from './simulated-device.adapter';

@Module({
  controllers: [OnboardingController],
  providers: [
    OnboardingService,
    { provide: DeviceAdapter, useClass: SimulatedDeviceAdapter },
  ],
})
export class OnboardingModule {}
