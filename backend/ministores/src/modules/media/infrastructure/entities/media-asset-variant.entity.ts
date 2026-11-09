import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { MediaVariantType } from '../../domain/media.enums.js';

@Entity({ name: 'media_asset_variants' })
export class MediaAssetVariantEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ name: 'media_asset_id', type: 'bigint' })
  mediaAssetId!: string;

  @Column({ type: 'enum', enum: MediaVariantType })
  variant!: MediaVariantType;

  @Column({ type: 'varchar', length: 120 })
  bucket!: string;

  @Column({ name: 'storage_key', type: 'varchar', length: 400 })
  storageKey!: string;

  @Column({ name: 'public_url', type: 'text' })
  publicUrl!: string;

  @Column({ name: 'size_bytes', type: 'bigint' })
  sizeBytes!: string;

  @Column({ name: 'width_px', type: 'int' })
  widthPx!: number;

  @Column({ name: 'height_px', type: 'int' })
  heightPx!: number;

  @Column({ name: 'is_default', type: 'boolean', default: false })
  isDefault!: boolean;
}
