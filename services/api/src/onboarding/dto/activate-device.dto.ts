import { IsString, Matches, MaxLength } from 'class-validator';

export class ActivateDeviceDto {
  @IsString()
  @Matches(/^FB-[A-Z0-9]{6}$/)
  serialNumber!: string;

  @IsString()
  @MaxLength(50)
  networkName!: string;
}
