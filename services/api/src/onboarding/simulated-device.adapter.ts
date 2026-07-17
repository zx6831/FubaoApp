import { Injectable } from '@nestjs/common';
import { DeviceAdapter, DeviceCandidate } from './device-adapter';

@Injectable()
export class SimulatedDeviceAdapter implements DeviceAdapter {
  async discover(familyId: string): Promise<DeviceCandidate[]> {
    return [{
      serialNumber: `FB-${familyId.replaceAll('-', '').slice(0, 6).toUpperCase()}`,
      firmware: '1.0.0',
    }];
  }

  async provision(_serialNumber: string, networkName: string): Promise<{ online: boolean }> {
    return { online: networkName.trim().length > 0 };
  }
}
