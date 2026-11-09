import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MediaService } from './application/media.service.js';
import { MediaAssetEntity } from './infrastructure/entities/media-asset.entity.js';
import { MediaAssetVariantEntity } from './infrastructure/entities/media-asset-variant.entity.js';
import { MediaController } from './interfaces/http/media.controller.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([MediaAssetEntity, MediaAssetVariantEntity], 'media'),
  ],
  controllers: [MediaController],
  providers: [MediaService],
  exports: [MediaService],
})
export class MediaModule {}
