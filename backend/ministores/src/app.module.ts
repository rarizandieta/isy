import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HealthController } from './health.controller.js';
import { MediaAssetEntity } from './modules/media/infrastructure/entities/media-asset.entity.js';
import { MediaAssetVariantEntity } from './modules/media/infrastructure/entities/media-asset-variant.entity.js';
import { AuditLogEntity } from './modules/ministores/infrastructure/entities/audit-log.entity.js';
import { CoverageZoneEntity } from './modules/ministores/infrastructure/entities/coverage-zone.entity.js';
import { MiniStoreCoverageZoneEntity } from './modules/ministores/infrastructure/entities/mini-store-coverage-zone.entity.js';
import { MiniStoreDeliveryOptionEntity } from './modules/ministores/infrastructure/entities/mini-store-delivery-option.entity.js';
import { MiniStorePaymentMethodEntity } from './modules/ministores/infrastructure/entities/mini-store-payment-method.entity.js';
import { MiniStoreEntity } from './modules/ministores/infrastructure/entities/mini-store.entity.js';
import { ProductTagEntity } from './modules/ministores/infrastructure/entities/product-tag.entity.js';
import { ProductUnitEntity } from './modules/ministores/infrastructure/entities/product-unit.entity.js';
import { StoreCategoryEntity } from './modules/ministores/infrastructure/entities/store-category.entity.js';
import { StoreProductEntity } from './modules/ministores/infrastructure/entities/store-product.entity.js';
import { StoreProductTagEntity } from './modules/ministores/infrastructure/entities/store-product-tag.entity.js';
import { StoreSectionEntity } from './modules/ministores/infrastructure/entities/store-section.entity.js';
import { MinistoresModule } from './modules/ministores/ministores.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [
        `.env.${process.env.NODE_ENV ?? 'development'}`,
        '.env',
      ],
    }),
    TypeOrmModule.forRootAsync({
      name: 'ministores',
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        url: configService.getOrThrow<string>('DATABASE_URL'),
        entities: [
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
          CoverageZoneEntity,
          MiniStoreCoverageZoneEntity,
        ],
        synchronize: false,
      }),
    }),
    TypeOrmModule.forRootAsync({
      name: 'media',
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        url: configService.getOrThrow<string>('MEDIA_DATABASE_URL'),
        entities: [MediaAssetEntity, MediaAssetVariantEntity],
        synchronize: false,
      }),
    }),
    MinistoresModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
