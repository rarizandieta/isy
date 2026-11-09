import 'reflect-metadata';
import { DataSource } from 'typeorm';

const mediaDatabaseUrl = process.env.MEDIA_DATABASE_URL;

if (!mediaDatabaseUrl) {
  throw new Error('MEDIA_DATABASE_URL is required for media migrations');
}

export default new DataSource({
  type: 'postgres',
  url: mediaDatabaseUrl,
  entities: [],
  migrations: ['src/database/migrations/media/*.ts'],
  synchronize: false,
  logging: false,
});
