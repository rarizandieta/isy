import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { MediaService } from '../../application/media.service.js';
import {
  MediaAssetStatus,
  MediaOwnerType,
  MediaQualityMode,
  MediaVariantType,
} from '../../domain/media.enums.js';

interface CreateMediaAssetBody {
  ownerType: MediaOwnerType;
  ownerId: number;
  mimeType: string;
  originalFilename?: string;
  checksumSha256?: string;
  qualityMode?: MediaQualityMode;
  status?: MediaAssetStatus;
}

interface CreateMediaVariantBody {
  variant: MediaVariantType;
  bucket: string;
  storageKey: string;
  publicUrl: string;
  sizeBytes: number;
  widthPx: number;
  heightPx: number;
  isDefault?: boolean;
}

interface UploadMediaBody {
  ownerType: MediaOwnerType;
  ownerId: string;
  qualityMode?: MediaQualityMode;
  includeHd?: string;
}

@Controller('media/assets')
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post()
  async createAsset(@Body() body: CreateMediaAssetBody) {
    return this.mediaService.createAsset(body);
  }

  @Get(':id')
  async getAsset(@Param('id', ParseIntPipe) id: number) {
    return this.mediaService.getAssetById(id);
  }

  @Get('owner/:ownerType/:ownerId')
  async listByOwner(
    @Param('ownerType') ownerType: MediaOwnerType,
    @Param('ownerId', ParseIntPipe) ownerId: number,
  ) {
    return this.mediaService.listAssetsByOwner(ownerType, ownerId);
  }

  @Post(':id/variants')
  async createVariant(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: CreateMediaVariantBody,
  ) {
    return this.mediaService.createVariant({
      mediaAssetId: id,
      ...body,
    });
  }

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: 20 * 1024 * 1024,
      },
    }),
  )
  async uploadAsset(
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: UploadMediaBody,
  ) {
    if (!file) {
      throw new BadRequestException('file is required');
    }

    const ownerId = Number(body.ownerId);
    if (!Number.isFinite(ownerId) || ownerId <= 0) {
      throw new BadRequestException('ownerId must be a positive number');
    }

    return this.mediaService.uploadAndProcessImage({
      ownerType: body.ownerType,
      ownerId,
      fileBuffer: file.buffer,
      mimeType: file.mimetype,
      originalFilename: file.originalname,
      qualityMode: body.qualityMode,
      includeHd: body.includeHd === 'true',
    });
  }
}
