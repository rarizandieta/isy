import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MediaModule } from '../media/media.module.js';
import { MinistoresService } from './application/ministores.service.js';
import { AuditLogEntity } from './infrastructure/entities/audit-log.entity.js';
import { MiniStoreDeliveryOptionEntity } from './infrastructure/entities/mini-store-delivery-option.entity.js';
import { MiniStorePaymentMethodEntity } from './infrastructure/entities/mini-store-payment-method.entity.js';
import { MiniStoreEntity } from './infrastructure/entities/mini-store.entity.js';
import { ProductTagEntity } from './infrastructure/entities/product-tag.entity.js';
import { ProductUnitEntity } from './infrastructure/entities/product-unit.entity.js';
import { StoreCategoryEntity } from './infrastructure/entities/store-category.entity.js';
import { StoreProductEntity } from './infrastructure/entities/store-product.entity.js';
import { StoreProductTagEntity } from './infrastructure/entities/store-product-tag.entity.js';
import { StoreSectionEntity } from './infrastructure/entities/store-section.entity.js';
import { AuditLogsController } from './interfaces/http/audit-logs.controller.js';
import { CatalogsController } from './interfaces/http/catalogs.controller.js';
import { MinistoresController } from './interfaces/http/ministores.controller.js';

@Module({
  imports: [
    MediaModule,
    TypeOrmModule.forFeature(
      [
        MiniStoreEntity,
        StoreCategoryEntity,
        ProductUnitEntity,
        ProductTagEntity,
        StoreSectionEntity,
        StoreProductTagEntity,
        MiniStoreDeliveryOptionEntity,
        MiniStorePaymentMethodEntity,
        StoreProductEntity,
        AuditLogEntity,
      ],
      'ministores',
    ),
  ],
  controllers: [MinistoresController, CatalogsController, AuditLogsController],
  providers: [MinistoresService],
})
export class MinistoresModule {}
