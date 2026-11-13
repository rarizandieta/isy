import { Entity, PrimaryColumn } from 'typeorm';

/**
 * Zonas de cobertura seleccionadas por una tienda (puente N:M entre
 * `mini_stores` y `coverage_zones`). Mismo patrón que las opciones de entrega y
 * los métodos de pago.
 */
@Entity({ name: 'mini_store_coverage_zones' })
export class MiniStoreCoverageZoneEntity {
  @PrimaryColumn({ name: 'store_id', type: 'bigint' })
  storeId!: string;

  @PrimaryColumn({ name: 'zone_id', type: 'bigint' })
  zoneId!: string;
}
