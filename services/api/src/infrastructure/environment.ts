export type PersistenceDriver = 'memory' | 'postgres';

export interface AppEnvironment {
  NODE_ENV: 'development' | 'test' | 'production';
  PORT: number;
  PERSISTENCE_DRIVER: PersistenceDriver;
  DATABASE_URL?: string;
  REDIS_URL?: string;
  JWT_ACCESS_SECRET: string;
  HASH_PEPPER: string;
  DATA_ENCRYPTION_KEY: string;
  APNS_MODE: 'fake' | 'apns';
  APNS_TOPIC?: string;
  APNS_AUTH_TOKEN?: string;
  APNS_HOST?: string;
  SMS_MODE: 'fake' | 'http';
  SMS_PROVIDER_URL?: string;
  SMS_PROVIDER_TOKEN?: string;
  REVIEW_PHONE?: string;
  REVIEW_CODE?: string;
}

export function validateEnvironment(raw: Record<string, unknown>): AppEnvironment {
  const nodeEnv = stringValue(raw.NODE_ENV, 'development');
  if (!['development', 'test', 'production'].includes(nodeEnv)) {
    throw new Error('NODE_ENV must be development, test, or production');
  }

  const persistence =
    nodeEnv === 'test'
      ? 'memory'
      : stringValue(raw.PERSISTENCE_DRIVER, 'memory');
  if (!['memory', 'postgres'].includes(persistence)) {
    throw new Error('PERSISTENCE_DRIVER must be memory or postgres');
  }
  if (persistence === 'postgres' && !raw.DATABASE_URL) {
    throw new Error('DATABASE_URL is required for postgres persistence');
  }

  const jwtSecret = stringValue(raw.JWT_ACCESS_SECRET, 'dev-access-secret-change-before-production');
  const hashPepper = stringValue(raw.HASH_PEPPER, 'dev-hash-pepper-change-before-production');
  const encryptionKey = stringValue(raw.DATA_ENCRYPTION_KEY, 'dev-data-key-change-before-production');
  const apnsMode = stringValue(raw.APNS_MODE, 'fake');
  if (!['fake', 'apns'].includes(apnsMode)) {
    throw new Error('APNS_MODE must be fake or apns');
  }
  if (apnsMode === 'apns' && (!raw.APNS_TOPIC || !raw.APNS_AUTH_TOKEN)) {
    throw new Error('APNS_TOPIC and APNS_AUTH_TOKEN are required in apns mode');
  }
  const smsMode = stringValue(raw.SMS_MODE, 'fake');
  if (!['fake', 'http'].includes(smsMode)) throw new Error('SMS_MODE must be fake or http');
  if (smsMode === 'http' && (!raw.SMS_PROVIDER_URL || !raw.SMS_PROVIDER_TOKEN)) {
    throw new Error('SMS_PROVIDER_URL and SMS_PROVIDER_TOKEN are required in http mode');
  }
  if (Boolean(raw.REVIEW_PHONE) !== Boolean(raw.REVIEW_CODE)) {
    throw new Error('REVIEW_PHONE and REVIEW_CODE must be configured together');
  }
  const productionSecrets = [
    optionalString(raw.JWT_ACCESS_SECRET),
    optionalString(raw.HASH_PEPPER),
    optionalString(raw.DATA_ENCRYPTION_KEY),
  ];
  if (nodeEnv === 'production' && productionSecrets.some((value) => !value || value.length < 32)) {
    throw new Error('Production security secrets must contain at least 32 characters');
  }

  return {
    NODE_ENV: nodeEnv as AppEnvironment['NODE_ENV'],
    PORT: numberValue(raw.PORT, 3000),
    PERSISTENCE_DRIVER: persistence as PersistenceDriver,
    DATABASE_URL: optionalString(raw.DATABASE_URL),
    REDIS_URL: optionalString(raw.REDIS_URL),
    JWT_ACCESS_SECRET: jwtSecret,
    HASH_PEPPER: hashPepper,
    DATA_ENCRYPTION_KEY: encryptionKey,
    APNS_MODE: apnsMode as AppEnvironment['APNS_MODE'],
    APNS_TOPIC: optionalString(raw.APNS_TOPIC),
    APNS_AUTH_TOKEN: optionalString(raw.APNS_AUTH_TOKEN),
    APNS_HOST: optionalString(raw.APNS_HOST),
    SMS_MODE: smsMode as AppEnvironment['SMS_MODE'],
    SMS_PROVIDER_URL: optionalString(raw.SMS_PROVIDER_URL),
    SMS_PROVIDER_TOKEN: optionalString(raw.SMS_PROVIDER_TOKEN),
    REVIEW_PHONE: optionalString(raw.REVIEW_PHONE),
    REVIEW_CODE: optionalString(raw.REVIEW_CODE),
  };
}

function stringValue(value: unknown, fallback: string): string {
  return typeof value === 'string' && value.length > 0 ? value : fallback;
}

function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.length > 0 ? value : undefined;
}

function numberValue(value: unknown, fallback: number): number {
  const parsed = Number(value ?? fallback);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535');
  }
  return parsed;
}
