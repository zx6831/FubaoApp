import { INestApplication } from '@nestjs/common';

export function configureApp(app: INestApplication): void {
  app.enableCors({ origin: true, credentials: true });
  app.setGlobalPrefix('api');
}
