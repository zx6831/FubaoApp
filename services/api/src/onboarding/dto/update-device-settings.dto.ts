import { IsBoolean, IsInt, IsString, Matches, Max, Min } from 'class-validator';

export class UpdateDeviceSettingsDto {
  @IsInt()
  @Min(0)
  @Max(100)
  volume!: number;

  @IsInt()
  @Min(0)
  @Max(100)
  speechRate!: number;

  @IsBoolean()
  dndEnabled!: boolean;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/)
  dndStart!: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/)
  dndEnd!: string;
}
