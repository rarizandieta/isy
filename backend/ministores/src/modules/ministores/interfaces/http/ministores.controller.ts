import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UploadedFile,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import { FileFieldsInterceptor, FileInterceptor } from '@nestjs/platform-express';
import { MediaQualityMode } from '../../../media/domain/media.enums.js';
import {
  CreateStoreInput,
  CreateStoreProductInput,
  CreateStoreSectionInput,
  MinistoresService,
  ReorderStoreSectionsInput,
  UpdateStoreInput,
  UpdateStoreProductInput,
  UpdateStoreSectionInput,
} from '../../application/ministores.service.js';
import {
  DeliveryOption,
  PaymentMethod,
  ProductStatus,
  StockStatus,
  StoreStatus,
} from '../../domain/ministores.enums.js';

interface CreateStoreRequestBody {
  sellerProfileId?: number;
  name: string;
  slug: string;
  categoryId: number;
  accentColor: string;
  tagline?: string;
  description?: string;
  logoUrl?: string;
  coverUrl?: string;
  logoMediaAssetId?: number;
  coverMediaAssetId?: number;
  logoImageBase64?: string | null;
  coverImageBase64?: string | null;
  scheduleText?: string;
  zoneText?: string;
  isOpen?: boolean;
  status?: StoreStatus;
  deliveryOptions?: DeliveryOption[];
  paymentMethods?: PaymentMethod[];
  coverageZoneIds?: number[];
}

interface UpdateStoreRequestBody {
  name?: string;
  slug?: string;
  categoryId?: number;
  accentColor?: string;
  tagline?: string | null;
  description?: string | null;
  logoUrl?: string | null;
  coverUrl?: string | null;
  logoMediaAssetId?: number | null;
  coverMediaAssetId?: number | null;
  logoImageBase64?: string | null;
  coverImageBase64?: string | null;
  scheduleText?: string | null;
  zoneText?: string | null;
  isOpen?: boolean;
  status?: StoreStatus;
  deliveryOptions?: DeliveryOption[];
  paymentMethods?: PaymentMethod[];
  coverageZoneIds?: number[];
}

interface CreateStoreProductRequestBody {
  sectionId?: number;
  name: string;
  description?: string;
  price: number;
  offerPrice?: number;
  unitId: number;
  tagIds?: number[];
  imageUrl?: string;
  imageMediaAssetId?: number;
  imageBase64?: string | null;
  stock?: StockStatus;
  status?: ProductStatus;
  isFeatured?: boolean;
}

interface UpdateStoreProductRequestBody {
  sectionId?: number | null;
  name?: string;
  description?: string | null;
  price?: number;
  offerPrice?: number | null;
  unitId?: number;
  tagIds?: number[];
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  imageBase64?: string | null;
  stock?: StockStatus;
  status?: ProductStatus;
  isFeatured?: boolean;
}

interface CreateSectionRequestBody {
  name: string;
  position: number;
  description?: string;
  imageUrl?: string;
  imageMediaAssetId?: number;
}

interface UpdateSectionRequestBody {
  name?: string;
  position?: number;
  description?: string | null;
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  isActive?: boolean;
}

interface ReorderSectionsRequestBody {
  sectionIds: number[];
}

@Controller('stores')
export class MinistoresController {
  constructor(private readonly ministoresService: MinistoresService) {}

  @Get('mine')
  async getMyStore(@Headers('x-profile-id') profileIdHeader: string) {
    const sellerProfileId = Number(profileIdHeader);
    if (!Number.isFinite(sellerProfileId) || sellerProfileId <= 0) {
      throw new BadRequestException(
        'Missing or invalid x-profile-id header. Provide seller profile ID from identity context.',
      );
    }
    return this.ministoresService.listStoresBySellerProfileId(sellerProfileId);
  }

  @Get(':id')
  async getStoreById(@Param('id', ParseIntPipe) id: number) {
    return this.ministoresService.getStoreById(id);
  }

  @Post()
  async createStore(
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @Body() body: CreateStoreRequestBody,
  ) {
    const actorProfileId = this.parseOptionalPositiveInt(profileIdHeader);
    const actorUserId = this.parseOptionalPositiveInt(userIdHeader);
    const input: CreateStoreInput = {
      sellerProfileId: body.sellerProfileId ?? actorProfileId ?? 0,
      actorProfileId,
      actorUserId,
      requestId: correlationIdHeader ?? null,
      name: body.name,
      slug: body.slug,
      categoryId: body.categoryId,
      accentColor: body.accentColor,
      tagline: body.tagline,
      description: body.description,
      logoUrl: body.logoUrl,
      coverUrl: body.coverUrl,
      logoMediaAssetId: body.logoMediaAssetId,
      coverMediaAssetId: body.coverMediaAssetId,
      logoImageBase64: body.logoImageBase64,
      coverImageBase64: body.coverImageBase64,
      scheduleText: body.scheduleText,
      zoneText: body.zoneText,
      isOpen: body.isOpen,
      status: body.status,
      deliveryOptions: body.deliveryOptions,
      paymentMethods: body.paymentMethods,
      coverageZoneIds: body.coverageZoneIds,
    };
    return this.ministoresService.createStore(input);
  }

  @Post('with-image')
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'logo', maxCount: 1 },
        { name: 'cover', maxCount: 1 },
      ],
      { limits: { fileSize: 20 * 1024 * 1024 } },
    ),
  )
  async createStoreWithImage(
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @UploadedFiles()
    files: { logo?: Express.Multer.File[]; cover?: Express.Multer.File[] },
    @Body() body: Record<string, string>,
  ) {
    const actorProfileId = this.parseOptionalPositiveInt(profileIdHeader);
    const actorUserId = this.parseOptionalPositiveInt(userIdHeader);

    const parsedBody: CreateStoreInput = {
      sellerProfileId:
        this.parseOptionalPositiveInt(body.sellerProfileId) ??
        actorProfileId ??
        0,
      actorProfileId,
      actorUserId,
      requestId: correlationIdHeader ?? null,
      name: body.name ?? '',
      slug: body.slug ?? '',
      categoryId: this.parseRequiredPositiveInt(body.categoryId, 'categoryId'),
      accentColor: body.accentColor ?? '',
      tagline: body.tagline ?? undefined,
      description: body.description ?? undefined,
      scheduleText: body.scheduleText ?? undefined,
      zoneText: body.zoneText ?? undefined,
      isOpen: this.parseOptionalBoolean(body.isOpen),
      status: this.parseOptionalStoreStatus(body.status),
      deliveryOptions: this.parseOptionalDeliveryOptions(body.deliveryOptions),
      paymentMethods: this.parseOptionalPaymentMethods(body.paymentMethods),
    };

    return this.ministoresService.createStoreWithLogoUpload(parsedBody, {
      logo: files.logo?.[0],
      cover: files.cover?.[0],
    }, {
      qualityMode: this.parseOptionalMediaQualityMode(body.qualityMode),
      includeHd: this.parseOptionalBoolean(body.includeHd),
    });
  }

  @Patch(':id')
  async updateStore(
    @Param('id', ParseIntPipe) id: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @Body() body: UpdateStoreRequestBody,
  ) {
    const input: UpdateStoreInput = {
      storeId: id,
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
      ...body,
    };
    return this.ministoresService.updateStore(input);
  }

  @Patch(':id/with-image')
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'logo', maxCount: 1 },
        { name: 'cover', maxCount: 1 },
      ],
      { limits: { fileSize: 20 * 1024 * 1024 } },
    ),
  )
  async updateStoreWithImage(
    @Param('id', ParseIntPipe) id: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @UploadedFiles()
    files: { logo?: Express.Multer.File[]; cover?: Express.Multer.File[] },
    @Body() body: Record<string, string>,
  ) {
    const input: UpdateStoreInput = {
      storeId: id,
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
      name: body.name,
      slug: body.slug,
      categoryId: this.parseOptionalPositiveInt(body.categoryId) ?? undefined,
      accentColor: body.accentColor,
      tagline: body.tagline,
      description: body.description,
      scheduleText: body.scheduleText,
      zoneText: body.zoneText,
      isOpen: this.parseOptionalBoolean(body.isOpen),
      status: this.parseOptionalStoreStatus(body.status),
      deliveryOptions: this.parseOptionalDeliveryOptions(body.deliveryOptions),
      paymentMethods: this.parseOptionalPaymentMethods(body.paymentMethods),
    };

    return this.ministoresService.updateStoreWithImageUpload(
      input,
      { logo: files.logo?.[0], cover: files.cover?.[0] },
      {
        qualityMode: this.parseOptionalMediaQualityMode(body.qualityMode),
        includeHd: this.parseOptionalBoolean(body.includeHd),
      },
    );
  }

  @Delete(':id')
  async deleteStore(
    @Param('id', ParseIntPipe) id: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
  ) {
    return this.ministoresService.softDeleteStore(id, {
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
    });
  }

  @Get(':id/sections')
  async listStoreSections(@Param('id', ParseIntPipe) id: number) {
    return this.ministoresService.listStoreSections(id);
  }

  @Post(':id/sections')
  async createStoreSection(
    @Param('id', ParseIntPipe) id: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @Body() body: CreateSectionRequestBody,
  ) {
    const input: CreateStoreSectionInput = {
      storeId: id,
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
      name: body.name,
      position: body.position,
      description: body.description,
      imageUrl: body.imageUrl,
      imageMediaAssetId: body.imageMediaAssetId,
    };
    return this.ministoresService.createStoreSection(input);
  }

  // IMPORTANTE: declarar ANTES de ':id/sections/:sectionId' para que el
  // segmento estático 'reorder' no sea capturado por el :sectionId (ParseIntPipe).
  @Patch(':id/sections/reorder')
  async reorderStoreSections(
    @Param('id', ParseIntPipe) id: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @Body() body: ReorderSectionsRequestBody,
  ) {
    const input: ReorderStoreSectionsInput = {
      storeId: id,
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
      sectionIds: Array.isArray(body.sectionIds)
        ? body.sectionIds.map((value) => Number(value)).filter((value) => Number.isFinite(value))
        : [],
    };
    return this.ministoresService.reorderStoreSections(input);
  }

  @Patch(':id/sections/:sectionId')
  async updateStoreSection(
    @Param('id', ParseIntPipe) id: number,
    @Param('sectionId', ParseIntPipe) sectionId: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @Body() body: UpdateSectionRequestBody,
  ) {
    const input: UpdateStoreSectionInput = {
      storeId: id,
      sectionId,
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
      ...body,
    };
    return this.ministoresService.updateStoreSection(input);
  }

  @Delete(':id/sections/:sectionId')
  async deleteStoreSection(
    @Param('id', ParseIntPipe) id: number,
    @Param('sectionId', ParseIntPipe) sectionId: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
  ) {
    return this.ministoresService.softDeleteStoreSection(id, sectionId, {
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
    });
  }

  @Get(':id/products')
  async listStoreProducts(@Param('id', ParseIntPipe) id: number) {
    return this.ministoresService.listStoreProducts(id);
  }

  @Get(':id/products/:productId')
  async getStoreProductById(
    @Param('id', ParseIntPipe) id: number,
    @Param('productId', ParseIntPipe) productId: number,
  ) {
    return this.ministoresService.getStoreProductById(id, productId);
  }

  @Post(':id/products')
  async createStoreProduct(
    @Param('id', ParseIntPipe) id: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @Body() body: CreateStoreProductRequestBody,
  ) {
    const input: CreateStoreProductInput = {
      storeId: id,
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
      sectionId: body.sectionId,
      name: body.name,
      description: body.description,
      price: body.price,
      offerPrice: body.offerPrice,
      unitId: body.unitId,
      tagIds: body.tagIds,
      imageUrl: body.imageUrl,
      imageMediaAssetId: body.imageMediaAssetId,
      imageBase64: body.imageBase64,
      stock: body.stock,
      status: body.status,
      isFeatured: body.isFeatured,
    };
    return this.ministoresService.createStoreProduct(input);
  }

  @Post(':id/products/with-image')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: 20 * 1024 * 1024,
      },
    }),
  )
  async createStoreProductWithImage(
    @Param('id', ParseIntPipe) id: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: Record<string, string>,
  ) {
    if (!file) {
      throw new BadRequestException('file is required');
    }

    const input: CreateStoreProductInput = {
      storeId: id,
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
      sectionId: this.parseOptionalPositiveInt(body.sectionId),
      name: body.name ?? '',
      description: body.description ?? undefined,
      price: this.parseRequiredNumber(body.price, 'price'),
      offerPrice: this.parseOptionalNumber(body.offerPrice),
      unitId: this.parseRequiredPositiveInt(body.unitId, 'unitId'),
      tagIds: this.parseOptionalNumberArray(body.tagIds),
      stock: this.parseOptionalStockStatus(body.stock),
      status: this.parseOptionalProductStatus(body.status),
      isFeatured: this.parseOptionalBoolean(body.isFeatured),
    };
    return this.ministoresService.createStoreProductWithImageUpload(
      input,
      file,
      {
        qualityMode: this.parseOptionalMediaQualityMode(body.qualityMode),
        includeHd: this.parseOptionalBoolean(body.includeHd),
      },
    );
  }

  @Patch(':id/products/:productId')
  async updateStoreProduct(
    @Param('id', ParseIntPipe) id: number,
    @Param('productId', ParseIntPipe) productId: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @Body() body: UpdateStoreProductRequestBody,
  ) {
    const input: UpdateStoreProductInput = {
      storeId: id,
      productId,
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
      ...body,
    };
    return this.ministoresService.updateStoreProduct(input);
  }

  @Patch(':id/products/:productId/with-image')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: 20 * 1024 * 1024,
      },
    }),
  )
  async updateStoreProductWithImage(
    @Param('id', ParseIntPipe) id: number,
    @Param('productId', ParseIntPipe) productId: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: Record<string, string>,
  ) {
    if (!file) {
      throw new BadRequestException('file is required');
    }

    const input: UpdateStoreProductInput = {
      storeId: id,
      productId,
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
      sectionId: this.parseOptionalPositiveInt(body.sectionId),
      name: body.name,
      description: body.description,
      price: this.parseOptionalNumber(body.price) ?? undefined,
      offerPrice: this.parseOptionalNumber(body.offerPrice),
      unitId: this.parseOptionalPositiveInt(body.unitId) ?? undefined,
      tagIds: this.parseOptionalNumberArray(body.tagIds),
      stock: this.parseOptionalStockStatus(body.stock),
      status: this.parseOptionalProductStatus(body.status),
      isFeatured: this.parseOptionalBoolean(body.isFeatured),
    };

    return this.ministoresService.updateStoreProductWithImageUpload(
      input,
      file,
      {
        qualityMode: this.parseOptionalMediaQualityMode(body.qualityMode),
        includeHd: this.parseOptionalBoolean(body.includeHd),
      },
    );
  }

  @Delete(':id/products/:productId')
  async deleteStoreProduct(
    @Param('id', ParseIntPipe) id: number,
    @Param('productId', ParseIntPipe) productId: number,
    @Headers('x-profile-id') profileIdHeader: string,
    @Headers('x-user-id') userIdHeader: string,
    @Headers('x-correlation-id') correlationIdHeader: string,
  ) {
    return this.ministoresService.softDeleteStoreProduct(id, productId, {
      actorProfileId: this.parseOptionalPositiveInt(profileIdHeader),
      actorUserId: this.parseOptionalPositiveInt(userIdHeader),
      requestId: correlationIdHeader ?? null,
    });
  }

  private parseOptionalPositiveInt(value: string | undefined): number | null {
    if (!value) {
      return null;
    }
    const parsed = Number(value);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  private parseRequiredPositiveInt(value: string | undefined, field: string): number {
    const parsed = Number(value);
    if (!Number.isFinite(parsed) || parsed <= 0) {
      throw new BadRequestException(`${field} must be a positive number`);
    }
    return parsed;
  }

  private parseRequiredNumber(value: string | undefined, field: string): number {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) {
      throw new BadRequestException(`${field} must be a valid number`);
    }
    return parsed;
  }

  private parseOptionalNumber(value: string | undefined): number | null | undefined {
    if (value === undefined || value === '') {
      return undefined;
    }
    if (value === 'null') {
      return null;
    }
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) {
      throw new BadRequestException('Numeric value is invalid');
    }
    return parsed;
  }

  private parseOptionalBoolean(value: string | undefined): boolean | undefined {
    if (value === undefined) {
      return undefined;
    }
    return value === 'true';
  }

  private parseOptionalStoreStatus(value: string | undefined): StoreStatus | undefined {
    if (!value) {
      return undefined;
    }
    if (Object.values(StoreStatus).includes(value as StoreStatus)) {
      return value as StoreStatus;
    }
    throw new BadRequestException('Invalid store status');
  }

  private parseOptionalProductStatus(value: string | undefined): ProductStatus | undefined {
    if (!value) {
      return undefined;
    }
    if (Object.values(ProductStatus).includes(value as ProductStatus)) {
      return value as ProductStatus;
    }
    throw new BadRequestException('Invalid product status');
  }

  private parseOptionalStockStatus(value: string | undefined): StockStatus | undefined {
    if (!value) {
      return undefined;
    }
    if (Object.values(StockStatus).includes(value as StockStatus)) {
      return value as StockStatus;
    }
    throw new BadRequestException('Invalid stock status');
  }

  private parseOptionalDeliveryOptions(
    value: string | undefined,
  ): DeliveryOption[] | undefined {
    if (!value) {
      return undefined;
    }
    return value
      .split(',')
      .map((item) => item.trim())
      .filter((item): item is DeliveryOption =>
        Object.values(DeliveryOption).includes(item as DeliveryOption),
      );
  }

  private parseOptionalPaymentMethods(
    value: string | undefined,
  ): PaymentMethod[] | undefined {
    if (!value) {
      return undefined;
    }
    return value
      .split(',')
      .map((item) => item.trim())
      .filter((item): item is PaymentMethod =>
        Object.values(PaymentMethod).includes(item as PaymentMethod),
      );
  }

  private parseOptionalMediaQualityMode(
    value: string | undefined,
  ): MediaQualityMode | undefined {
    if (!value) {
      return undefined;
    }
    if (Object.values(MediaQualityMode).includes(value as MediaQualityMode)) {
      return value as MediaQualityMode;
    }
    throw new BadRequestException('Invalid media quality mode');
  }

  private parseOptionalNumberArray(
    value: string | undefined,
  ): number[] | undefined {
    if (!value) {
      return undefined;
    }
    return value
      .split(',')
      .map((item) => item.trim())
      .filter((item) => item.length > 0)
      .map((item) => {
        const parsed = Number(item);
        if (!Number.isFinite(parsed) || parsed <= 0) {
          throw new BadRequestException('Invalid numeric list value');
        }
        return parsed;
      });
  }
}
