import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Imágenes de identidad de la Mini Tienda (portada + logo/perfil) guardadas como
 * BLOB (bytea) directamente en la fila de la tienda. Se reciben y entregan como
 * base64 (data URI). Alternativa simple al módulo media (archivos + URLs), para
 * la personalización de la tienda.
 */
export class AddStoreIdentityImages1762700003000 implements MigrationInterface {
  name = 'AddStoreIdentityImages1762700003000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE mini_stores
        ADD COLUMN IF NOT EXISTS logo_image bytea,
        ADD COLUMN IF NOT EXISTS logo_image_mime varchar(64),
        ADD COLUMN IF NOT EXISTS cover_image bytea,
        ADD COLUMN IF NOT EXISTS cover_image_mime varchar(64)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE mini_stores
        DROP COLUMN IF EXISTS logo_image,
        DROP COLUMN IF EXISTS logo_image_mime,
        DROP COLUMN IF EXISTS cover_image,
        DROP COLUMN IF EXISTS cover_image_mime
    `);
  }
}
