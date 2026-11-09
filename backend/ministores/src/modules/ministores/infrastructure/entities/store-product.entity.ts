import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { ProductStatus, StockStatus } from '../../domain/ministores.enums.js';

@Entity({ name: 'store_products' })
export class StoreProductEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ name: 'store_id', type: 'bigint' })
  storeId!: string;

  @Column({ name: 'section_id', type: 'bigint', nullable: true })
  sectionId!: string | null;

  @Column({ type: 'varchar', length: 100 })
  name!: string;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  @Column({ type: 'numeric', precision: 12, scale: 2 })
  price!: string;

  @Column({ name: 'offer_price', type: 'numeric', precision: 12, scale: 2, nullable: true })
  offerPrice!: string | null;

  @Column({ name: 'unit_id', type: 'bigint' })
  unitId!: string;

  @Column({ name: 'image_url', type: 'text', nullable: true })
  imageUrl!: string | null;

  @Column({ type: 'enum', enum: StockStatus, default: StockStatus.AVAILABLE })
  stock!: StockStatus;

  @Column({ type: 'enum', enum: ProductStatus, default: ProductStatus.DRAFT })
  status!: ProductStatus;

  @Column({ name: 'is_featured', type: 'boolean', default: false })
  isFeatured!: boolean;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt!: Date | null;
}
