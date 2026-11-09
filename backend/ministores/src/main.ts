import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { AppModule } from './app.module.js';
import { DatabaseExceptionFilter } from './common/filters/database-exception.filter.js';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const mediaStorageDir = resolve(
    process.cwd(),
    process.env.MEDIA_STORAGE_DIR ?? './storage/media',
  );
  mkdirSync(mediaStorageDir, { recursive: true });
  app.useStaticAssets(mediaStorageDir, {
    prefix: '/media/files/',
  });
  app.useGlobalFilters(new DatabaseExceptionFilter());
  await app.listen(process.env.PORT ?? 3002);
}
await bootstrap();
