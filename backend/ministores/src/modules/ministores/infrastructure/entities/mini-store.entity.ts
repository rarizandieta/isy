import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { StoreStatus } from '../../domain/ministores.enums.js';

@Entity({ name: 'mini_stores' })
export class MiniStoreEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ name: 'seller_profile_id', type: 'bigint' })
  sellerProfileId!: string;

  @Column({ type: 'varchar', length: 120, unique: true })
  slug!: string;

  @Column({ type: 'varchar', length: 80 })
  name!: string;

  @Column({ type: 'varchar', length: 120, nullable: true })
  tagline!: string | null;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  @Column({ name: 'category_id', type: 'bigint' })
  categoryId!: string;

  @Column({ name: 'logo_url', type: 'text', nullable: true })
  logoUrl!: string | null;

  @Column({ name: 'cover_url', type: 'text', nullable: true })
  coverUrl!: string | null;

  @Column({ name: 'accent_color', type: 'char', length: 7 })
  accentColor!: string;

  @Column({ type: 'enum', enum: StoreStatus, default: StoreStatus.DRAFT })
  status!: StoreStatus;

  @Column({ name: 'is_open', type: 'boolean', default: false })
  isOpen!: boolean;

  @Column({ name: 'schedule_text', type: 'varchar', length: 120, nullable: true })
  scheduleText!: string | null;

  @Column({ name: 'zone_text', type: 'varchar', length: 120, nullable: true })
  zoneText!: string | null;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt!: Date | null;
}
