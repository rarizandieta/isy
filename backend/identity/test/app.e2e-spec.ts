import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types.js';
import { AppModule } from './../src/app.module.js';

describe('HealthController (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(() => {
    // AppModule now validates env on init. /health does not touch the DB and
    // migrations only run in main.ts (not here), so a lazy pool is fine.
    process.env.DATABASE_URL ??= 'postgres://isy:isy@localhost:5432/identity';
    process.env.JWT_SECRET ??= 'test-secret';
  });

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/health (GET)', () => {
    return request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect({ status: 'ok', service: 'identity' });
  });

  afterEach(async () => {
    await app.close();
  });
});
