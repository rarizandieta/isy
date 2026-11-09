import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitMinistoresSchema1762700000000 implements MigrationInterface {
  name = 'InitMinistoresSchema1762700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TYPE store_status AS ENUM ('draft', 'active', 'inactive', 'suspended');
      CREATE TYPE product_status AS ENUM ('draft', 'published', 'archived');
      CREATE TYPE stock_status AS ENUM ('available', 'sold_out', 'made_to_order');
      CREATE TYPE delivery_option AS ENUM ('pickup', 'delivery', 'shipping');
      CREATE TYPE payment_method AS ENUM ('cash', 'transfer', 'card');
      CREATE TYPE audit_action AS ENUM ('insert', 'update', 'delete', 'status_change');
    `);

    await queryRunner.query(`
      CREATE TABLE store_categories (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        code VARCHAR(40) NOT NULL UNIQUE,
        name VARCHAR(80) NOT NULL UNIQUE,
        description TEXT,
        image_url TEXT,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT
      );
    `);

    await queryRunner.query(`
      CREATE TABLE product_units (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        code VARCHAR(30) NOT NULL UNIQUE,
        name VARCHAR(60) NOT NULL UNIQUE,
        description TEXT,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT
      );
    `);

    await queryRunner.query(`
      CREATE TABLE product_tags (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        code VARCHAR(40) NOT NULL UNIQUE,
        name VARCHAR(80) NOT NULL UNIQUE,
        description TEXT,
        image_url TEXT,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT
      );
    `);

    await queryRunner.query(`
      CREATE TABLE mini_stores (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        seller_profile_id BIGINT NOT NULL UNIQUE,
        slug VARCHAR(120) NOT NULL UNIQUE,
        name VARCHAR(80) NOT NULL,
        tagline VARCHAR(120),
        description TEXT,
        category_id BIGINT NOT NULL REFERENCES store_categories(id),
        logo_url TEXT,
        cover_url TEXT,
        accent_color CHAR(7) NOT NULL,
        status store_status NOT NULL DEFAULT 'draft',
        is_open BOOLEAN NOT NULL DEFAULT FALSE,
        schedule_text VARCHAR(120),
        zone_text VARCHAR(120),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT,
        deleted_at TIMESTAMPTZ,
        CONSTRAINT ck_mini_stores_accent_color_hex CHECK (accent_color ~ '^#[0-9A-Fa-f]{6}$')
      );
    `);

    await queryRunner.query(`
      CREATE TABLE mini_store_delivery_options (
        store_id BIGINT NOT NULL REFERENCES mini_stores(id) ON DELETE CASCADE,
        option delivery_option NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT,
        PRIMARY KEY (store_id, option)
      );
    `);

    await queryRunner.query(`
      CREATE TABLE mini_store_payment_methods (
        store_id BIGINT NOT NULL REFERENCES mini_stores(id) ON DELETE CASCADE,
        method payment_method NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT,
        PRIMARY KEY (store_id, method)
      );
    `);

    await queryRunner.query(`
      CREATE TABLE store_sections (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        store_id BIGINT NOT NULL REFERENCES mini_stores(id) ON DELETE CASCADE,
        name VARCHAR(60) NOT NULL,
        description TEXT,
        image_url TEXT,
        position INT NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT,
        deleted_at TIMESTAMPTZ,
        CONSTRAINT uq_store_sections_name UNIQUE (store_id, name),
        CONSTRAINT uq_store_sections_position UNIQUE (store_id, position),
        CONSTRAINT ck_store_sections_position CHECK (position > 0)
      );
    `);

    await queryRunner.query(`
      CREATE TABLE store_products (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        store_id BIGINT NOT NULL REFERENCES mini_stores(id) ON DELETE CASCADE,
        section_id BIGINT REFERENCES store_sections(id) ON DELETE SET NULL,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        price NUMERIC(12,2) NOT NULL,
        offer_price NUMERIC(12,2),
        unit_id BIGINT NOT NULL REFERENCES product_units(id),
        image_url TEXT,
        stock stock_status NOT NULL DEFAULT 'available',
        status product_status NOT NULL DEFAULT 'draft',
        is_featured BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT,
        deleted_at TIMESTAMPTZ,
        CONSTRAINT ck_store_products_price_non_negative CHECK (price >= 0),
        CONSTRAINT ck_store_products_offer_price_valid
          CHECK (offer_price IS NULL OR (offer_price >= 0 AND offer_price <= price))
      );
    `);

    await queryRunner.query(`
      CREATE TABLE store_product_tags (
        product_id BIGINT NOT NULL REFERENCES store_products(id) ON DELETE CASCADE,
        tag_id BIGINT NOT NULL REFERENCES product_tags(id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT,
        PRIMARY KEY (product_id, tag_id)
      );
    `);

    await queryRunner.query(`
      CREATE TABLE audit_logs (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        entity_name VARCHAR(80) NOT NULL,
        entity_id BIGINT NOT NULL,
        action audit_action NOT NULL,
        actor_profile_id BIGINT,
        request_id VARCHAR(100),
        changes JSONB,
        metadata JSONB,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    await queryRunner.query(`
      CREATE INDEX idx_mini_stores_status ON mini_stores(status);
      CREATE INDEX idx_mini_stores_is_open ON mini_stores(is_open);
      CREATE INDEX idx_mini_stores_seller_profile ON mini_stores(seller_profile_id);
      CREATE INDEX idx_store_sections_store ON store_sections(store_id);
      CREATE INDEX idx_store_products_store ON store_products(store_id);
      CREATE INDEX idx_store_products_section ON store_products(section_id);
      CREATE INDEX idx_store_products_status ON store_products(status);
      CREATE INDEX idx_store_products_stock ON store_products(stock);
      CREATE INDEX idx_store_products_featured ON store_products(is_featured);
      CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_name, entity_id);
      CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_profile_id);
      CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_audit_logs_created_at;
      DROP INDEX IF EXISTS idx_audit_logs_actor;
      DROP INDEX IF EXISTS idx_audit_logs_entity;
      DROP INDEX IF EXISTS idx_store_products_featured;
      DROP INDEX IF EXISTS idx_store_products_stock;
      DROP INDEX IF EXISTS idx_store_products_status;
      DROP INDEX IF EXISTS idx_store_products_section;
      DROP INDEX IF EXISTS idx_store_products_store;
      DROP INDEX IF EXISTS idx_store_sections_store;
      DROP INDEX IF EXISTS idx_mini_stores_seller_profile;
      DROP INDEX IF EXISTS idx_mini_stores_is_open;
      DROP INDEX IF EXISTS idx_mini_stores_status;
    `);

    await queryRunner.query(`
      DROP TABLE IF EXISTS audit_logs;
      DROP TABLE IF EXISTS store_product_tags;
      DROP TABLE IF EXISTS store_products;
      DROP TABLE IF EXISTS store_sections;
      DROP TABLE IF EXISTS mini_store_payment_methods;
      DROP TABLE IF EXISTS mini_store_delivery_options;
      DROP TABLE IF EXISTS mini_stores;
      DROP TABLE IF EXISTS product_tags;
      DROP TABLE IF EXISTS product_units;
      DROP TABLE IF EXISTS store_categories;
    `);

    await queryRunner.query(`
      DROP TYPE IF EXISTS audit_action;
      DROP TYPE IF EXISTS payment_method;
      DROP TYPE IF EXISTS delivery_option;
      DROP TYPE IF EXISTS stock_status;
      DROP TYPE IF EXISTS product_status;
      DROP TYPE IF EXISTS store_status;
    `);
  }
}
