import 'reflect-metadata';
import { DataSource } from 'typeorm';

const ministoresDatabaseUrl = process.env.DATABASE_URL;

if (!ministoresDatabaseUrl) {
  throw new Error('DATABASE_URL is required for ministores migrations');
}

export default new DataSource({
  type: 'postgres',
  url: ministoresDatabaseUrl,
  entities: [],
  migrations: ['src/database/migrations/ministores/*.ts'],
  synchronize: false,
  logging: false,
});
