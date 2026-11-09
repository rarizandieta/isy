import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { AllExceptionsFilter } from './common/http-exception.filter.js';
import { runMigrations } from './database/migrate.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());
  app.enableShutdownHooks();

  const config = app.get(ConfigService);

  // Run DB migrations + idempotent role seed before accepting traffic.
  await runMigrations(config.getOrThrow<string>('DATABASE_URL'));

  const port = config.getOrThrow<number>('PORT');
  await app.listen(port);
}

await bootstrap();
