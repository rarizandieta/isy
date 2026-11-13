import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

/**
 * Zona de cobertura (catálogo fijo de ubicaciones donde una tienda puede marcar
 * que entrega). Tiene coordenadas para pintarse como pin en el mapa. El usuario
 * solo puede elegir entre estas zonas predefinidas (la tabla puente referencia
 * a este catálogo).
 */
@Entity({ name: 'coverage_zones' })
export class CoverageZoneEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ type: 'varchar', length: 40, unique: true })
  code!: string;

  @Column({ type: 'varchar', length: 80, unique: true })
  name!: string;

  @Column({ type: 'double precision' })
  latitude!: number;

  @Column({ type: 'double precision' })
  longitude!: number;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive!: boolean;
}
