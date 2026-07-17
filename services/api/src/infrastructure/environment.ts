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
