import { Column, Entity, PrimaryColumn } from 'typeorm';
import { DeliveryOption } from '../../domain/ministores.enums.js';

@Entity({ name: 'mini_store_delivery_options' })
export class MiniStoreDeliveryOptionEntity {
  @PrimaryColumn({ name: 'store_id', type: 'bigint' })
  storeId!: string;

  @PrimaryColumn({ type: 'enum', enum: DeliveryOption })
  option!: DeliveryOption;
}
