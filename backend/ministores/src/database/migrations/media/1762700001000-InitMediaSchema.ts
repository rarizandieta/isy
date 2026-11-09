import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitMediaSchema1762700001000 implements MigrationInterface {
  name = 'InitMediaSchema1762700001000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE media_asset_status AS ENUM ('processing', 'ready', 'failed', 'deleted');
      CREATE TYPE media_variant_type AS ENUM ('optimized', 'thumbnail', 'hd');
      CREATE TYPE media_quality_mode AS ENUM ('optimized_default', 'hd_default');
      CREATE TYPE media_owner_type AS ENUM ('mini_store', 'store_product', 'store_category', 'store_section');
    `);

    await queryRunner.query(`
      CREATE TABLE media_assets (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        owner_type media_owner_type NOT NULL,
        owner_id BIGINT NOT NULL,
        quality_mode media_quality_mode NOT NULL DEFAULT 'optimized_default',
        status media_asset_status NOT NULL DEFAULT 'processing',
        mime_type VARCHAR(100) NOT NULL,
        original_filename VARCHAR(255),
        checksum_sha256 CHAR(64),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT,
        deleted_at TIMESTAMPTZ
      );
    `);

    await queryRunner.query(`
      CREATE TABLE media_asset_variants (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        media_asset_id BIGINT NOT NULL REFERENCES media_assets(id) ON DELETE CASCADE,
        variant media_variant_type NOT NULL,
        bucket VARCHAR(120) NOT NULL,
        storage_key VARCHAR(400) NOT NULL,
        public_url TEXT NOT NULL,
        size_bytes BIGINT NOT NULL,
        width_px INT NOT NULL,
        height_px INT NOT NULL,
        is_default BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT,
        CONSTRAINT uq_media_asset_variant UNIQUE (media_asset_id, variant),
        CONSTRAINT uq_media_storage_object UNIQUE (bucket, storage_key),
        CONSTRAINT ck_media_size_bytes_non_negative CHECK (size_bytes >= 0),
        CONSTRAINT ck_media_width_positive CHECK (width_px > 0),
        CONSTRAINT ck_media_height_positive CHECK (height_px > 0)
      );
    `);

    await queryRunner.query(`
      CREATE TABLE media_processing_logs (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        media_asset_id BIGINT NOT NULL REFERENCES media_assets(id) ON DELETE CASCADE,
        message TEXT NOT NULL,
        metadata JSONB,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    await queryRunner.query(`
      CREATE INDEX idx_media_assets_owner ON media_assets(owner_type, owner_id);
      CREATE INDEX idx_media_assets_status ON media_assets(status);
      CREATE INDEX idx_media_assets_quality_mode ON media_assets(quality_mode);
      CREATE INDEX idx_media_variants_default ON media_asset_variants(media_asset_id, is_default);
      CREATE INDEX idx_media_processing_logs_asset ON media_processing_logs(media_asset_id);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_media_processing_logs_asset;
      DROP INDEX IF EXISTS idx_media_variants_default;
      DROP INDEX IF EXISTS idx_media_assets_quality_mode;
      DROP INDEX IF EXISTS idx_media_assets_status;
      DROP INDEX IF EXISTS idx_media_assets_owner;
    `);

    await queryRunner.query(`
      DROP TABLE IF EXISTS media_processing_logs;
      DROP TABLE IF EXISTS media_asset_variants;
      DROP TABLE IF EXISTS media_assets;
    `);

    await queryRunner.query(`
      DROP TYPE IF EXISTS media_owner_type;
      DROP TYPE IF EXISTS media_quality_mode;
      DROP TYPE IF EXISTS media_variant_type;
      DROP TYPE IF EXISTS media_asset_status;
    `);
  }
}
