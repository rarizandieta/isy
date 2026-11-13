import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Imagen del producto guardada como BLOB (bytea) en la fila del producto,
 * recibida y entregada en base64 (data URI). Mismo enfoque que las imágenes de
 * identidad de la tienda.
 */
export class AddProductImage1762700004000 implements MigrationInterface {
  name = 'AddProductImage1762700004000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE store_products
        ADD COLUMN IF NOT EXISTS image_blob bytea,
        ADD COLUMN IF NOT EXISTS image_mime varchar(64)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE store_products
        DROP COLUMN IF EXISTS image_blob,
        DROP COLUMN IF EXISTS image_mime
    `);
  }
}
