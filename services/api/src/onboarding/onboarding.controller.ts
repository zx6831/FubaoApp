import { Body, Controller, Delete, Get, Patch, Post, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/current-user.decorator';
import { Roles } from '../auth/roles.decorator';
import { ActivateDeviceDto } from './dto/activate-device.dto';
import { DeviceStatusDto } from './dto/device-status.dto';
import { UpdateDeviceSettingsDto } from './dto/update-device-settings.dto';
import { UpsertHealthProfileDto } from './dto/upsert-health-profile.dto';
import { OnboardingService } from './onboarding.service';

@ApiBearerAuth()
@ApiTags('onboarding')
@Controller()
export class OnboardingController {
  constructor(private readonly onboarding: OnboardingService) {}

  @Get('onboarding/status')
  status(@CurrentUser() user: AuthenticatedUser) {
    return this.onboarding.status(user);
  }

  @Get('profiles/elder')
  profile(@CurrentUser() user: AuthenticatedUser) {
    return this.onboarding.getProfile(user);
  }

  @Roles('child')
  @Put('profiles/elder')
  upsertProfile(@CurrentUser() user: AuthenticatedUser, @Body() body: UpsertHealthProfileDto) {
    return this.onboarding.upsertProfile(user, body);
  }

  @Roles('child')
  @Post('devices/discover')
  discover(@CurrentUser() user: AuthenticatedUser) {
    return this.onboarding.discoverDevices(user);
  }

  @Roles('child')
  @Post('devices/activate')
  activate(@CurrentUser() user: AuthenticatedUser, @Body() body: ActivateDeviceDto) {
    return this.onboarding.activateDevice(user, body);
  }

  @Get('devices/current')
  currentDevice(@CurrentUser() user: AuthenticatedUser) {
    return this.onboarding.currentDevice(user);
  }

  @Roles('child')
  @Patch('devices/settings')
  updateSettings(@CurrentUser() user: AuthenticatedUser, @Body() body: UpdateDeviceSettingsDto) {
    return this.onboarding.updateSettings(user, body);
  }

  @Roles('child')
  @Patch('devices/status')
  deviceStatus(@CurrentUser() user: AuthenticatedUser, @Body() body: DeviceStatusDto) {
    return this.onboarding.setDeviceStatus(user, body.status);
  }

  @Roles('child')
  @Delete('devices/current')
  unbind(@CurrentUser() user: AuthenticatedUser) {
    return this.onboarding.unbindDevice(user);
  }

  @Roles('child')
  @Post('devices/factory-reset')
  factoryReset(@CurrentUser() user: AuthenticatedUser) {
    return this.onboarding.factoryReset(user);
  }
}
