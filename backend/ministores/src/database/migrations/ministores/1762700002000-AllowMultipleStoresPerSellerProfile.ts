import { MigrationInterface, QueryRunner } from 'typeorm';

export class AllowMultipleStoresPerSellerProfile1762700002000
  implements MigrationInterface
{
  name = 'AllowMultipleStoresPerSellerProfile1762700002000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE mini_stores
      DROP CONSTRAINT IF EXISTS mini_stores_seller_profile_id_key
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE mini_stores
      ADD CONSTRAINT mini_stores_seller_profile_id_key UNIQUE (seller_profile_id)
    `);
  }
}
