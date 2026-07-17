export interface DeviceCandidate {
  serialNumber: string;
  firmware: string;
}

export abstract class DeviceAdapter {
  abstract discover(familyId: string): Promise<DeviceCandidate[]>;
  abstract provision(serialNumber: string, networkName: string): Promise<{ online: boolean }>;
}
