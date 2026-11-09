import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { createHash, randomUUID } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import sharp from 'sharp';
import { Repository } from 'typeorm';
import {
  MediaAssetStatus,
  MediaOwnerType,
  MediaQualityMode,
  MediaVariantType,
} from '../domain/media.enums.js';
import { MediaAssetEntity } from '../infrastructure/entities/media-asset.entity.js';
import { MediaAssetVariantEntity } from '../infrastructure/entities/media-asset-variant.entity.js';

export interface CreateMediaAssetInput {
  ownerType: MediaOwnerType;
  ownerId: number;
  mimeType: string;
  originalFilename?: string;
  checksumSha256?: string;
  qualityMode?: MediaQualityMode;
  status?: MediaAssetStatus;
}

export interface CreateMediaVariantInput {
  mediaAssetId: number;
  variant: MediaVariantType;
  bucket: string;
  storageKey: string;
  publicUrl: string;
  sizeBytes: number;
  widthPx: number;
  heightPx: number;
  isDefault?: boolean;
}

export interface UploadMediaInput {
  ownerType: MediaOwnerType;
  ownerId: number;
  fileBuffer: Buffer;
  originalFilename?: string;
  mimeType: string;
  qualityMode?: MediaQualityMode;
  includeHd?: boolean;
}

@Injectable()
export class MediaService {
  constructor(
    @InjectRepository(MediaAssetEntity, 'media')
    private readonly mediaAssetRepository: Repository<MediaAssetEntity>,
    @InjectRepository(MediaAssetVariantEntity, 'media')
    private readonly mediaAssetVariantRepository: Repository<MediaAssetVariantEntity>,
    private readonly configService: ConfigService,
  ) {}

  async createAsset(input: CreateMediaAssetInput) {
    const asset = this.mediaAssetRepository.create({
      ownerType: input.ownerType,
      ownerId: String(input.ownerId),
      mimeType: input.mimeType,
      originalFilename: input.originalFilename ?? null,
      checksumSha256: input.checksumSha256 ?? null,
      qualityMode: input.qualityMode ?? MediaQualityMode.OPTIMIZED_DEFAULT,
      status: input.status ?? MediaAssetStatus.PROCESSING,
    });
    return this.mediaAssetRepository.save(asset);
  }

  async createVariant(input: CreateMediaVariantInput) {
    const asset = await this.mediaAssetRepository.findOne({
      where: { id: String(input.mediaAssetId) },
    });
    if (!asset) {
      throw new NotFoundException(`Media asset ${input.mediaAssetId} not found`);
    }

    if (input.isDefault) {
      await this.mediaAssetVariantRepository.update(
        { mediaAssetId: String(input.mediaAssetId), isDefault: true },
        { isDefault: false },
      );
    }

    const variant = this.mediaAssetVariantRepository.create({
      mediaAssetId: String(input.mediaAssetId),
      variant: input.variant,
      bucket: input.bucket,
      storageKey: input.storageKey,
      publicUrl: input.publicUrl,
      sizeBytes: String(input.sizeBytes),
      widthPx: input.widthPx,
      heightPx: input.heightPx,
      isDefault: input.isDefault ?? false,
    });

    return this.mediaAssetVariantRepository.save(variant);
  }

  async getAssetById(id: number) {
    const asset = await this.mediaAssetRepository.findOne({
      where: { id: String(id) },
    });
    if (!asset) {
      throw new NotFoundException(`Media asset ${id} not found`);
    }
    const variants = await this.mediaAssetVariantRepository.find({
      where: { mediaAssetId: String(id) },
      order: { isDefault: 'DESC', id: 'ASC' },
    });
    return { ...asset, variants };
  }

  async listAssetsByOwner(ownerType: MediaOwnerType, ownerId: number) {
    return this.mediaAssetRepository.find({
      where: {
        ownerType,
        ownerId: String(ownerId),
      },
      order: { id: 'DESC' },
    });
  }

  async resolvePreferredUrl(assetId: number): Promise<string | null> {
    const variants = await this.mediaAssetVariantRepository.find({
      where: { mediaAssetId: String(assetId) },
      order: { isDefault: 'DESC', id: 'ASC' },
    });

    const byPriority = [
      variants.find((item) => item.isDefault),
      variants.find((item) => item.variant === MediaVariantType.OPTIMIZED),
      variants.find((item) => item.variant === MediaVariantType.THUMBNAIL),
      variants.find((item) => item.variant === MediaVariantType.HD),
    ].filter((item): item is MediaAssetVariantEntity => Boolean(item));

    return byPriority[0]?.publicUrl ?? null;
  }

  async uploadAndProcessImage(input: UploadMediaInput) {
    const qualityMode = input.qualityMode ?? MediaQualityMode.OPTIMIZED_DEFAULT;
    const includeHd = input.includeHd ?? qualityMode === MediaQualityMode.HD_DEFAULT;
    const checksumSha256 = createHash('sha256')
      .update(input.fileBuffer)
      .digest('hex');
    const storageRoot = this.getStorageRoot();
    const optimizedWidth = Number(
      this.configService.get<string>('MEDIA_OPTIMIZED_MAX_WIDTH') ?? '1600',
    );
    const thumbnailWidth = Number(
      this.configService.get<string>('MEDIA_THUMBNAIL_MAX_WIDTH') ?? '360',
    );

    const asset = await this.createAsset({
      ownerType: input.ownerType,
      ownerId: input.ownerId,
      mimeType: input.mimeType,
      originalFilename: input.originalFilename,
      checksumSha256,
      qualityMode,
      status: MediaAssetStatus.PROCESSING,
    });

    await mkdir(resolve(storageRoot, asset.id), { recursive: true });

    const optimizedBuffer = await sharp(input.fileBuffer)
      .rotate()
      .resize({ width: optimizedWidth, withoutEnlargement: true })
      .webp({ quality: 80 })
      .toBuffer();
    const optimizedMetadata = await sharp(optimizedBuffer).metadata();
    const optimizedVariant = await this.persistVariant({
      mediaAssetId: Number(asset.id),
      variant: MediaVariantType.OPTIMIZED,
      fileBuffer: optimizedBuffer,
      fileName: 'optimized.webp',
      widthPx: optimizedMetadata.width ?? 0,
      heightPx: optimizedMetadata.height ?? 0,
      isDefault: true,
    });

    const thumbnailBuffer = await sharp(input.fileBuffer)
      .rotate()
      .resize({ width: thumbnailWidth, withoutEnlargement: true })
      .webp({ quality: 70 })
      .toBuffer();
    const thumbnailMetadata = await sharp(thumbnailBuffer).metadata();
    const thumbnailVariant = await this.persistVariant({
      mediaAssetId: Number(asset.id),
      variant: MediaVariantType.THUMBNAIL,
      fileBuffer: thumbnailBuffer,
      fileName: 'thumbnail.webp',
      widthPx: thumbnailMetadata.width ?? 0,
      heightPx: thumbnailMetadata.height ?? 0,
      isDefault: false,
    });

    let hdVariant: MediaAssetVariantEntity | null = null;
    if (includeHd) {
      const hdBuffer = await sharp(input.fileBuffer)
        .rotate()
        .webp({ quality: 95 })
        .toBuffer();
      const hdMetadata = await sharp(hdBuffer).metadata();
      hdVariant = await this.persistVariant({
        mediaAssetId: Number(asset.id),
        variant: MediaVariantType.HD,
        fileBuffer: hdBuffer,
        fileName: 'hd.webp',
        widthPx: hdMetadata.width ?? 0,
        heightPx: hdMetadata.height ?? 0,
        isDefault: qualityMode === MediaQualityMode.HD_DEFAULT,
      });

      if (qualityMode === MediaQualityMode.HD_DEFAULT) {
        await this.mediaAssetVariantRepository.update(
          { id: optimizedVariant.id },
          { isDefault: false },
        );
      }
    }

    await this.mediaAssetRepository.update(
      { id: asset.id },
      { status: MediaAssetStatus.READY },
    );

    return this.getAssetById(Number(asset.id));
  }

  private getStorageRoot(): string {
    return resolve(
      process.cwd(),
      this.configService.get<string>('MEDIA_STORAGE_DIR') ?? './storage/media',
    );
  }

  private getPublicBaseUrl(): string {
    return (
      this.configService.get<string>('MEDIA_PUBLIC_BASE_URL') ??
      `http://localhost:${this.configService.get<string>('PORT') ?? '3002'}`
    );
  }

  private async persistVariant(input: {
    mediaAssetId: number;
    variant: MediaVariantType;
    fileBuffer: Buffer;
    fileName: string;
    widthPx: number;
    heightPx: number;
    isDefault: boolean;
  }) {
    const safeWidth = input.widthPx > 0 ? input.widthPx : 1;
    const safeHeight = input.heightPx > 0 ? input.heightPx : 1;
    const storageKey = `${input.mediaAssetId}/${randomUUID()}-${input.fileName}`;
    const storagePath = resolve(this.getStorageRoot(), storageKey);
    await mkdir(dirname(storagePath), { recursive: true });
    await writeFile(storagePath, input.fileBuffer);

    return this.createVariant({
      mediaAssetId: input.mediaAssetId,
      variant: input.variant,
      bucket: 'local',
      storageKey,
      publicUrl: `${this.getPublicBaseUrl()}/media/files/${storageKey}`,
      sizeBytes: input.fileBuffer.byteLength,
      widthPx: safeWidth,
      heightPx: safeHeight,
      isDefault: input.isDefault,
    });
  }
}
