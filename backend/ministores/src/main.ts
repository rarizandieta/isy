import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import express from 'express';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { AppModule } from './app.module.js';
import { DatabaseExceptionFilter } from './common/filters/database-exception.filter.js';

async function bootstrap() {
  // Desactivamos el body parser por defecto (límite 100 kb) para subirlo: las
  // imágenes de identidad de la tienda viajan en base64 dentro del JSON. El
  // tope real de cada imagen lo valida el servicio (3 MB decodificados); aquí
  // dejamos holgura para logo + portada en una sola petición.
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    bodyParser: false,
  });
  app.use(express.json({ limit: '12mb' }));
  app.use(express.urlencoded({ extended: true, limit: '12mb' }));

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
