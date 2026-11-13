import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Zonas de cobertura: catálogo fijo de ubicaciones (con coordenadas) y la tabla
 * puente que indica qué zonas cubre cada tienda. Sustituye al texto libre de
 * "zona de cobertura": el vendedor marca en el mapa entre estas zonas fijas.
 */
export class AddCoverageZones1762700005000 implements MigrationInterface {
  name = 'AddCoverageZones1762700005000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE coverage_zones (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        code VARCHAR(40) NOT NULL UNIQUE,
        name VARCHAR(80) NOT NULL UNIQUE,
        latitude DOUBLE PRECISION NOT NULL,
        longitude DOUBLE PRECISION NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT
      );
    `);

    await queryRunner.query(`
      CREATE TABLE mini_store_coverage_zones (
        store_id BIGINT NOT NULL REFERENCES mini_stores(id) ON DELETE CASCADE,
        zone_id BIGINT NOT NULL REFERENCES coverage_zones(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        created_by BIGINT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_by BIGINT,
        PRIMARY KEY (store_id, zone_id)
      );
    `);

    await queryRunner.query(
      `CREATE INDEX idx_mini_store_coverage_zones_store ON mini_store_coverage_zones (store_id);`,
    );

    // Semilla: las 5 zonas fijas acordadas (con coordenadas corregidas).
    await queryRunner.query(`
      INSERT INTO coverage_zones (code, name, latitude, longitude) VALUES
        ('condado_almeria', 'Condado Almería', 14.539941456707698, -90.39232340617353),
        ('montecastelo', 'Montecastelo', 14.538249524887405, -90.38766485732958),
        ('condado_florenza', 'Condado Florenza', 14.54225129053299, -90.38462502105834),
        ('condominio_valle_navarra', 'Condominio Valle de Navarra', 14.538389293650923, -90.3812584025236),
        ('pasaje_navarra', 'Pasaje de Navarra', 14.536991601954561, -90.38062763655164);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS mini_store_coverage_zones;`);
    await queryRunner.query(`DROP TABLE IF EXISTS coverage_zones;`);
  }
}
