import { IsIn } from 'class-validator';

export class DeviceStatusDto {
  @IsIn(['online', 'offline'])
  status!: 'online' | 'offline';
}
