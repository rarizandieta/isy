import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import {
  MediaAssetStatus,
  MediaOwnerType,
  MediaQualityMode,
} from '../../domain/media.enums.js';

@Entity({ name: 'media_assets' })
export class MediaAssetEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ name: 'owner_type', type: 'enum', enum: MediaOwnerType })
  ownerType!: MediaOwnerType;

  @Column({ name: 'owner_id', type: 'bigint' })
  ownerId!: string;

  @Column({
    name: 'quality_mode',
    type: 'enum',
    enum: MediaQualityMode,
    default: MediaQualityMode.OPTIMIZED_DEFAULT,
  })
  qualityMode!: MediaQualityMode;

  @Column({
    type: 'enum',
    enum: MediaAssetStatus,
    default: MediaAssetStatus.PROCESSING,
  })
  status!: MediaAssetStatus;

  @Column({ name: 'mime_type', type: 'varchar', length: 100 })
  mimeType!: string;

  @Column({ name: 'original_filename', type: 'varchar', length: 255, nullable: true })
  originalFilename!: string | null;

  @Column({ name: 'checksum_sha256', type: 'char', length: 64, nullable: true })
  checksumSha256!: string | null;
}
