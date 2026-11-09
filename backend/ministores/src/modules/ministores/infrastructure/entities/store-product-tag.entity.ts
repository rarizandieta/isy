import { Column, Entity, PrimaryColumn } from 'typeorm';

@Entity({ name: 'store_product_tags' })
export class StoreProductTagEntity {
  @PrimaryColumn({ name: 'product_id', type: 'bigint' })
  productId!: string;

  @PrimaryColumn({ name: 'tag_id', type: 'bigint' })
  tagId!: string;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @Column({ name: 'created_by', type: 'bigint', nullable: true })
  createdBy!: string | null;

  @Column({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;

  @Column({ name: 'updated_by', type: 'bigint', nullable: true })
  updatedBy!: string | null;
}
