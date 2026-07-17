import { validateEnvironment } from '../src/infrastructure/environment';

describe('production environment validation', () => {
  it('rejects production startup without explicit security secrets', () => {
    expect(() =>
      validateEnvironment({
        NODE_ENV: 'production',
        PERSISTENCE_DRIVER: 'postgres',
        DATABASE_URL: 'postgresql://example',
      }),
    ).toThrow('Production security secrets');
  });

  it('accepts explicit production secrets of at least 32 characters', () => {
    const environment = validateEnvironment({
      NODE_ENV: 'production',
      PERSISTENCE_DRIVER: 'postgres',
      DATABASE_URL: 'postgresql://example',
      JWT_ACCESS_SECRET: 'a'.repeat(32),
      HASH_PEPPER: 'b'.repeat(32),
      DATA_ENCRYPTION_KEY: 'c'.repeat(32),
    });
    expect(environment.NODE_ENV).toBe('production');
  });
});
