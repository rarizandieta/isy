import { Column, Entity, PrimaryColumn } from 'typeorm';
import { PaymentMethod } from '../../domain/ministores.enums.js';

@Entity({ name: 'mini_store_payment_methods' })
export class MiniStorePaymentMethodEntity {
  @PrimaryColumn({ name: 'store_id', type: 'bigint' })
  storeId!: string;

  @PrimaryColumn({ type: 'enum', enum: PaymentMethod })
  method!: PaymentMethod;
}
