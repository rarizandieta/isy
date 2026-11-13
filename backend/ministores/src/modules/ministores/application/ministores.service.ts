import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import { MediaService, UploadMediaInput } from '../../media/application/media.service.js';
import { MediaOwnerType, MediaQualityMode } from '../../media/domain/media.enums.js';
import {
  AuditAction,
  DeliveryOption,
  PaymentMethod,
  ProductStatus,
  StockStatus,
  StoreStatus,
} from '../domain/ministores.enums.js';
import { AuditLogEntity } from '../infrastructure/entities/audit-log.entity.js';
import { CoverageZoneEntity } from '../infrastructure/entities/coverage-zone.entity.js';
import { MiniStoreCoverageZoneEntity } from '../infrastructure/entities/mini-store-coverage-zone.entity.js';
import { MiniStoreDeliveryOptionEntity } from '../infrastructure/entities/mini-store-delivery-option.entity.js';
import { MiniStorePaymentMethodEntity } from '../infrastructure/entities/mini-store-payment-method.entity.js';
import { MiniStoreEntity } from '../infrastructure/entities/mini-store.entity.js';
import { ProductTagEntity } from '../infrastructure/entities/product-tag.entity.js';
import { ProductUnitEntity } from '../infrastructure/entities/product-unit.entity.js';
import { StoreCategoryEntity } from '../infrastructure/entities/store-category.entity.js';
import { StoreProductEntity } from '../infrastructure/entities/store-product.entity.js';
import { StoreProductTagEntity } from '../infrastructure/entities/store-product-tag.entity.js';
import { StoreSectionEntity } from '../infrastructure/entities/store-section.entity.js';

interface ActorContext {
  actorProfileId: number | null;
  actorUserId: number | null;
  requestId: string | null;
}

export interface CreateStoreInput extends ActorContext {
  sellerProfileId: number;
  name: string;
  slug: string;
  categoryId: number;
  accentColor: string;
  tagline?: string | null;
  description?: string | null;
  logoUrl?: string | null;
  coverUrl?: string | null;
  logoMediaAssetId?: number | null;
  coverMediaAssetId?: number | null;
  /** Imagen de logo/perfil en base64 (data URI o base64 puro). */
  logoImageBase64?: string | null;
  /** Imagen de portada en base64 (data URI o base64 puro). */
  coverImageBase64?: string | null;
  scheduleText?: string | null;
  zoneText?: string | null;
  isOpen?: boolean;
  status?: StoreStatus;
  deliveryOptions?: DeliveryOption[];
  paymentMethods?: PaymentMethod[];
  /** Ids de zonas de cobertura (catálogo coverage_zones). */
  coverageZoneIds?: number[];
}

export interface UpdateStoreInput extends ActorContext {
  storeId: number;
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
  /** base64 (data URI o puro). null/'' limpia la imagen; undefined la deja igual. */
  logoImageBase64?: string | null;
  coverImageBase64?: string | null;
  scheduleText?: string | null;
  zoneText?: string | null;
  isOpen?: boolean;
  status?: StoreStatus;
  deliveryOptions?: DeliveryOption[];
  paymentMethods?: PaymentMethod[];
  /** undefined = no cambia; [] limpia; lista = reemplaza las zonas de cobertura. */
  coverageZoneIds?: number[];
}

export interface CreateStoreProductInput extends ActorContext {
  storeId: number;
  sectionId?: number | null;
  name: string;
  description?: string | null;
  price: number;
  offerPrice?: number | null;
  unitId: number;
  tagIds?: number[];
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  /** Imagen del producto en base64 (data URI o base64 puro). */
  imageBase64?: string | null;
  stock?: StockStatus;
  status?: ProductStatus;
  isFeatured?: boolean;
}

export interface UpdateStoreProductInput extends ActorContext {
  storeId: number;
  productId: number;
  sectionId?: number | null;
  name?: string;
  description?: string | null;
  price?: number;
  offerPrice?: number | null;
  unitId?: number;
  tagIds?: number[];
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  /** base64 (data URI o puro). null/'' limpia la imagen; undefined la deja igual. */
  imageBase64?: string | null;
  stock?: StockStatus;
  status?: ProductStatus;
  isFeatured?: boolean;
}

export interface CreateStoreSectionInput extends ActorContext {
  storeId: number;
  name: string;
  position: number;
  description?: string | null;
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
}

export interface UpdateStoreSectionInput extends ActorContext {
  storeId: number;
  sectionId: number;
  name?: string;
  position?: number;
  description?: string | null;
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  isActive?: boolean;
}

export interface ReorderStoreSectionsInput extends ActorContext {
  storeId: number;
  /** Ids de TODAS las secciones vivas de la tienda, en el orden deseado. */
  sectionIds: number[];
}

export interface UpdateStoreCategoryInput {
  categoryId: number;
  name?: string;
  description?: string | null;
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  isActive?: boolean;
}

export interface CreateStoreCategoryInput {
  code: string;
  name: string;
  description?: string | null;
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  isActive?: boolean;
}

export interface CreateProductUnitInput {
  code: string;
  name: string;
  description?: string | null;
  isActive?: boolean;
}

export interface UpdateProductUnitInput {
  unitId: number;
  code?: string;
  name?: string;
  description?: string | null;
  isActive?: boolean;
}

export interface CreateProductTagInput {
  code: string;
  name: string;
  description?: string | null;
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  isActive?: boolean;
}

export interface UpdateProductTagInput {
  tagId: number;
  code?: string;
  name?: string;
  description?: string | null;
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  isActive?: boolean;
}

export interface ListAuditLogsInput {
  entityName?: string;
  entityId?: number;
  action?: AuditAction;
  actorProfileId?: number;
  limit?: number;
}

@Injectable()
export class MinistoresService {
  constructor(
    @InjectRepository(MiniStoreEntity, 'ministores')
    private readonly miniStoreRepository: Repository<MiniStoreEntity>,
    @InjectRepository(StoreCategoryEntity, 'ministores')
    private readonly storeCategoryRepository: Repository<StoreCategoryEntity>,
    @InjectRepository(ProductUnitEntity, 'ministores')
    private readonly productUnitRepository: Repository<ProductUnitEntity>,
    @InjectRepository(ProductTagEntity, 'ministores')
    private readonly productTagRepository: Repository<ProductTagEntity>,
    @InjectRepository(StoreSectionEntity, 'ministores')
    private readonly storeSectionRepository: Repository<StoreSectionEntity>,
    @InjectRepository(MiniStoreDeliveryOptionEntity, 'ministores')
    private readonly storeDeliveryOptionRepository: Repository<MiniStoreDeliveryOptionEntity>,
    @InjectRepository(MiniStorePaymentMethodEntity, 'ministores')
    private readonly storePaymentMethodRepository: Repository<MiniStorePaymentMethodEntity>,
    @InjectRepository(StoreProductEntity, 'ministores')
    private readonly storeProductRepository: Repository<StoreProductEntity>,
    @InjectRepository(StoreProductTagEntity, 'ministores')
    private readonly storeProductTagRepository: Repository<StoreProductTagEntity>,
    @InjectRepository(AuditLogEntity, 'ministores')
    private readonly auditLogRepository: Repository<AuditLogEntity>,
    @InjectRepository(CoverageZoneEntity, 'ministores')
    private readonly coverageZoneRepository: Repository<CoverageZoneEntity>,
    @InjectRepository(MiniStoreCoverageZoneEntity, 'ministores')
    private readonly storeCoverageZoneRepository: Repository<MiniStoreCoverageZoneEntity>,
    private readonly mediaService: MediaService,
  ) {}

  async listCategories() {
    return this.storeCategoryRepository.find({
      where: { isActive: true },
      order: { name: 'ASC' },
    });
  }

  /** Catálogo de zonas de cobertura (ubicaciones fijas con coordenadas). */
  async listCoverageZones() {
    return this.coverageZoneRepository.find({
      where: { isActive: true },
      order: { name: 'ASC' },
    });
  }

  async createCategory(input: CreateStoreCategoryInput) {
    if (!input.code.trim()) {
      throw new BadRequestException('code is required');
    }
    if (!input.name.trim()) {
      throw new BadRequestException('name is required');
    }
    const imageUrl = await this.resolveImageUrl({
      directUrl: input.imageUrl,
      mediaAssetId: input.imageMediaAssetId,
    });
    return this.storeCategoryRepository.save({
      code: input.code.trim(),
      name: input.name.trim(),
      description: input.description ?? null,
      imageUrl,
      isActive: input.isActive ?? true,
    });
  }

  async updateCategory(input: UpdateStoreCategoryInput) {
    const category = await this.storeCategoryRepository.findOne({
      where: { id: String(input.categoryId) },
    });
    if (!category) {
      throw new NotFoundException(`Category ${input.categoryId} not found`);
    }

    const patch: Partial<StoreCategoryEntity> = {};
    if (input.name !== undefined) patch.name = input.name;
    if (input.description !== undefined) patch.description = input.description;
    if (input.isActive !== undefined) patch.isActive = input.isActive;
    if (input.imageUrl !== undefined || input.imageMediaAssetId !== undefined) {
      patch.imageUrl = await this.resolveImageUrl({
        directUrl: input.imageUrl,
        mediaAssetId: input.imageMediaAssetId,
      });
    }

    await this.storeCategoryRepository.update({ id: category.id }, patch);
    return this.storeCategoryRepository.findOneByOrFail({ id: category.id });
  }

  async listUnits() {
    return this.productUnitRepository.find({
      where: { isActive: true },
      order: { name: 'ASC' },
    });
  }

  async createUnit(input: CreateProductUnitInput) {
    if (!input.code.trim()) {
      throw new BadRequestException('code is required');
    }
    if (!input.name.trim()) {
      throw new BadRequestException('name is required');
    }
    return this.productUnitRepository.save({
      code: input.code.trim(),
      name: input.name.trim(),
      description: input.description ?? null,
      isActive: input.isActive ?? true,
    });
  }

  async updateUnit(input: UpdateProductUnitInput) {
    const unit = await this.productUnitRepository.findOne({
      where: { id: String(input.unitId) },
    });
    if (!unit) {
      throw new NotFoundException(`Unit ${input.unitId} not found`);
    }

    const patch: Partial<ProductUnitEntity> = {};
    if (input.code !== undefined) patch.code = input.code.trim();
    if (input.name !== undefined) patch.name = input.name.trim();
    if (input.description !== undefined) patch.description = input.description;
    if (input.isActive !== undefined) patch.isActive = input.isActive;
    await this.productUnitRepository.update({ id: unit.id }, patch);
    return this.productUnitRepository.findOneByOrFail({ id: unit.id });
  }

  async listTags() {
    return this.productTagRepository.find({
      where: { isActive: true },
      order: { name: 'ASC' },
    });
  }

  async createTag(input: CreateProductTagInput) {
    if (!input.code.trim()) {
      throw new BadRequestException('code is required');
    }
    if (!input.name.trim()) {
      throw new BadRequestException('name is required');
    }
    const imageUrl = await this.resolveImageUrl({
      directUrl: input.imageUrl,
      mediaAssetId: input.imageMediaAssetId,
    });
    return this.productTagRepository.save({
      code: input.code.trim(),
      name: input.name.trim(),
      description: input.description ?? null,
      imageUrl,
      isActive: input.isActive ?? true,
    });
  }

  async updateTag(input: UpdateProductTagInput) {
    const tag = await this.productTagRepository.findOne({
      where: { id: String(input.tagId) },
    });
    if (!tag) {
      throw new NotFoundException(`Tag ${input.tagId} not found`);
    }

    const patch: Partial<ProductTagEntity> = {};
    if (input.code !== undefined) patch.code = input.code.trim();
    if (input.name !== undefined) patch.name = input.name.trim();
    if (input.description !== undefined) patch.description = input.description;
    if (input.isActive !== undefined) patch.isActive = input.isActive;
    if (input.imageUrl !== undefined || input.imageMediaAssetId !== undefined) {
      patch.imageUrl = await this.resolveImageUrl({
        directUrl: input.imageUrl,
        mediaAssetId: input.imageMediaAssetId,
      });
    }
    await this.productTagRepository.update({ id: tag.id }, patch);
    return this.productTagRepository.findOneByOrFail({ id: tag.id });
  }

  async listAuditLogs(input: ListAuditLogsInput) {
    const where: Record<string, unknown> = {};
    if (input.entityName) where.entityName = input.entityName;
    if (input.entityId !== undefined) where.entityId = String(input.entityId);
    if (input.action) where.action = input.action;
    if (input.actorProfileId !== undefined) {
      where.actorProfileId = String(input.actorProfileId);
    }

    const take = Math.max(1, Math.min(input.limit ?? 50, 200));
    return this.auditLogRepository.find({
      where,
      order: { id: 'DESC' },
      take,
    });
  }

  async createStore(input: CreateStoreInput) {
    this.validateCreateStoreInput(input);
    await this.ensureCategoryExists(input.categoryId);

    const resolvedLogoUrl = await this.resolveImageUrl({
      directUrl: input.logoUrl,
      mediaAssetId: input.logoMediaAssetId,
    });
    const resolvedCoverUrl = await this.resolveImageUrl({
      directUrl: input.coverUrl,
      mediaAssetId: input.coverMediaAssetId,
    });

    let logoUrl = resolvedLogoUrl;
    if (input.logoImageBase64) {
      logoUrl = await this.uploadImageFromBase64(
        input.logoImageBase64,
        MediaOwnerType.MINI_STORE,
        input.sellerProfileId,
      );
    }
    let coverUrl = resolvedCoverUrl;
    if (input.coverImageBase64) {
      coverUrl = await this.uploadImageFromBase64(
        input.coverImageBase64,
        MediaOwnerType.MINI_STORE,
        input.sellerProfileId,
      );
    }

    const store = await this.miniStoreRepository.save({
      sellerProfileId: String(input.sellerProfileId),
      slug: input.slug,
      name: input.name,
      tagline: input.tagline ?? null,
      description: input.description ?? null,
      categoryId: String(input.categoryId),
      logoUrl,
      coverUrl,
      accentColor: input.accentColor,
      status: input.status ?? StoreStatus.DRAFT,
      isOpen: input.isOpen ?? false,
      scheduleText: input.scheduleText ?? null,
      zoneText: input.zoneText ?? null,
    });

    await this.replaceStoreOptions(store.id, {
      deliveryOptions: input.deliveryOptions,
      paymentMethods: input.paymentMethods,
    });
    await this.replaceCoverageZones(store.id, input.coverageZoneIds);

    await this.insertAuditLog({
      entityName: 'mini_stores',
      entityId: Number(store.id),
      action: AuditAction.INSERT,
      actorProfileId: input.actorProfileId,
      requestId: input.requestId,
      changes: { after: this.redactStoreImages(store) },
    });

    return this.getStoreById(Number(store.id));
  }

  async createStoreWithLogoUpload(
    input: CreateStoreInput,
    files: { logo?: Express.Multer.File; cover?: Express.Multer.File },
    options?: { qualityMode?: MediaQualityMode; includeHd?: boolean },
  ) {
    const logoAssetId = files.logo
      ? await this.uploadOwnedMedia({
          ownerType: MediaOwnerType.MINI_STORE,
          ownerId: input.sellerProfileId,
          qualityMode: options?.qualityMode ?? MediaQualityMode.OPTIMIZED_DEFAULT,
          includeHd: options?.includeHd,
          file: files.logo,
        })
      : null;

    const coverAssetId = files.cover
      ? await this.uploadOwnedMedia({
          ownerType: MediaOwnerType.MINI_STORE,
          ownerId: input.sellerProfileId,
          qualityMode: options?.qualityMode ?? MediaQualityMode.OPTIMIZED_DEFAULT,
          includeHd: options?.includeHd,
          file: files.cover,
        })
      : null;

    return this.createStore({
      ...input,
      logoMediaAssetId: logoAssetId ?? input.logoMediaAssetId,
      coverMediaAssetId: coverAssetId ?? input.coverMediaAssetId,
    });
  }

  async updateStoreWithImageUpload(
    input: UpdateStoreInput,
    files: { logo?: Express.Multer.File; cover?: Express.Multer.File },
    options?: { qualityMode?: MediaQualityMode; includeHd?: boolean },
  ) {
    const store = await this.getStoreEntityOrFail(input.storeId);

    const logoAssetId = files.logo
      ? await this.uploadOwnedMedia({
          ownerType: MediaOwnerType.MINI_STORE,
          ownerId: Number(store.sellerProfileId),
          qualityMode: options?.qualityMode ?? MediaQualityMode.OPTIMIZED_DEFAULT,
          includeHd: options?.includeHd,
          file: files.logo,
        })
      : undefined;

    const coverAssetId = files.cover
      ? await this.uploadOwnedMedia({
          ownerType: MediaOwnerType.MINI_STORE,
          ownerId: Number(store.sellerProfileId),
          qualityMode: options?.qualityMode ?? MediaQualityMode.OPTIMIZED_DEFAULT,
          includeHd: options?.includeHd,
          file: files.cover,
        })
      : undefined;

    return this.updateStore({
      ...input,
      logoMediaAssetId:
        logoAssetId !== undefined ? logoAssetId : input.logoMediaAssetId,
      coverMediaAssetId:
        coverAssetId !== undefined ? coverAssetId : input.coverMediaAssetId,
    });
  }

  async updateStore(input: UpdateStoreInput) {
    if (input.name !== undefined && !input.name.trim()) {
      throw new BadRequestException('name cannot be empty');
    }
    if (input.slug !== undefined && !input.slug.trim()) {
      throw new BadRequestException('slug cannot be empty');
    }
    if (input.accentColor !== undefined && !/^#[0-9A-Fa-f]{6}$/.test(input.accentColor)) {
      throw new BadRequestException('accentColor must be a hex color (#RRGGBB)');
    }

    const store = await this.getStoreEntityOrFail(input.storeId);
    this.ensureStoreOwnership(store, input.actorProfileId);

    if (input.categoryId !== undefined) {
      await this.ensureCategoryExists(input.categoryId);
    }

    const patch: Partial<MiniStoreEntity> = { updatedAt: new Date() };
    if (input.name !== undefined) patch.name = input.name;
    if (input.slug !== undefined) patch.slug = input.slug;
    if (input.tagline !== undefined) patch.tagline = input.tagline;
    if (input.description !== undefined) patch.description = input.description;
    if (input.categoryId !== undefined) patch.categoryId = String(input.categoryId);
    if (input.accentColor !== undefined) patch.accentColor = input.accentColor;
    if (input.scheduleText !== undefined) patch.scheduleText = input.scheduleText;
    if (input.zoneText !== undefined) patch.zoneText = input.zoneText;
    if (input.isOpen !== undefined) patch.isOpen = input.isOpen;
    if (input.status !== undefined) patch.status = input.status;

    if (input.logoUrl !== undefined || input.logoMediaAssetId !== undefined) {
      patch.logoUrl = await this.resolveImageUrl({
        directUrl: input.logoUrl,
        mediaAssetId: input.logoMediaAssetId,
      });
    }
    if (input.coverUrl !== undefined || input.coverMediaAssetId !== undefined) {
      patch.coverUrl = await this.resolveImageUrl({
        directUrl: input.coverUrl,
        mediaAssetId: input.coverMediaAssetId,
      });
    }

    // Imágenes base64 -> archivo (media). undefined = sin cambios; null/'' = limpiar.
    if (input.logoImageBase64 !== undefined) {
      patch.logoUrl = input.logoImageBase64
        ? await this.uploadImageFromBase64(
            input.logoImageBase64,
            MediaOwnerType.MINI_STORE,
            Number(store.sellerProfileId),
          )
        : null;
    }
    if (input.coverImageBase64 !== undefined) {
      patch.coverUrl = input.coverImageBase64
        ? await this.uploadImageFromBase64(
            input.coverImageBase64,
            MediaOwnerType.MINI_STORE,
            Number(store.sellerProfileId),
          )
        : null;
    }

    await this.miniStoreRepository.update({ id: store.id }, patch);

    await this.replaceStoreOptions(store.id, {
      deliveryOptions: input.deliveryOptions,
      paymentMethods: input.paymentMethods,
    });
    await this.replaceCoverageZones(store.id, input.coverageZoneIds);

    await this.insertAuditLog({
      entityName: 'mini_stores',
      entityId: Number(store.id),
      action: AuditAction.UPDATE,
      actorProfileId: input.actorProfileId,
      requestId: input.requestId,
      changes: { before: store, after: this.redactStoreImages(patch) },
    });

    return this.getStoreById(Number(store.id));
  }

  async softDeleteStore(
    storeId: number,
    actor: ActorContext,
  ) {
    const store = await this.getStoreEntityOrFail(storeId);
    this.ensureStoreOwnership(store, actor.actorProfileId);

    const now = new Date();
    await this.miniStoreRepository.update(
      { id: store.id },
      {
        deletedAt: now,
        status: StoreStatus.INACTIVE,
        updatedAt: now,
      },
    );

    await this.insertAuditLog({
      entityName: 'mini_stores',
      entityId: storeId,
      action: AuditAction.DELETE,
      actorProfileId: actor.actorProfileId,
      requestId: actor.requestId,
      changes: { before: store, after: { deletedAt: now.toISOString() } },
    });

    return { id: storeId, deleted: true };
  }

  async getStoreById(storeId: number) {
    const store = await this.getStoreEntityOrFail(storeId);
    const category = await this.storeCategoryRepository.findOne({
      where: { id: store.categoryId },
    });
    const deliveryOptions = await this.storeDeliveryOptionRepository.find({
      where: { storeId: store.id },
    });
    const paymentMethods = await this.storePaymentMethodRepository.find({
      where: { storeId: store.id },
    });
    const coverageLinks = await this.storeCoverageZoneRepository.find({
      where: { storeId: store.id },
    });
    const coverageZones = coverageLinks.length
      ? await this.coverageZoneRepository.find({
          where: { id: In(coverageLinks.map((link) => link.zoneId)) },
          order: { name: 'ASC' },
        })
      : [];

    return {
      ...store,
      category,
      delivery_options: deliveryOptions.map((item) => item.option),
      payment_methods: paymentMethods.map((item) => item.method),
      coverageZones,
    };
  }

  async listStoresBySellerProfileId(sellerProfileId: number) {
    const stores = await this.miniStoreRepository.find({
      where: { sellerProfileId: String(sellerProfileId), deletedAt: IsNull() },
      order: { id: 'DESC' },
    });
    if (stores.length === 0) {
      throw new NotFoundException(
        `No stores found for seller profile ${sellerProfileId}`,
      );
    }
    return Promise.all(stores.map((store) => this.getStoreById(Number(store.id))));
  }

  async createStoreProduct(input: CreateStoreProductInput) {
    this.validateCreateProductInput(input);
    const store = await this.getStoreEntityOrFail(input.storeId);
    this.ensureStoreOwnership(store, input.actorProfileId);

    await this.ensureUnitExists(input.unitId);
    if (input.sectionId !== undefined && input.sectionId !== null) {
      await this.ensureSectionExists(input.storeId, input.sectionId);
    }

    const resolvedImageUrl = await this.resolveImageUrl({
      directUrl: input.imageUrl,
      mediaAssetId: input.imageMediaAssetId,
    });
    let imageUrl = resolvedImageUrl;
    if (input.imageBase64) {
      imageUrl = await this.uploadImageFromBase64(
        input.imageBase64,
        MediaOwnerType.STORE_PRODUCT,
        input.storeId,
      );
    }

    const product = await this.storeProductRepository.save({
      storeId: String(input.storeId),
      sectionId:
        input.sectionId !== undefined && input.sectionId !== null
          ? String(input.sectionId)
          : null,
      name: input.name,
      description: input.description ?? null,
      price: input.price.toFixed(2),
      offerPrice:
        input.offerPrice !== undefined && input.offerPrice !== null
          ? input.offerPrice.toFixed(2)
          : null,
      unitId: String(input.unitId),
      imageUrl,
      stock: input.stock ?? StockStatus.AVAILABLE,
      status: input.status ?? ProductStatus.DRAFT,
      isFeatured: input.isFeatured ?? false,
    });

    if (input.tagIds !== undefined) {
      await this.ensureTagsExist(input.tagIds);
      await this.syncProductTags(
        Number(product.id),
        input.tagIds,
        input.actorUserId,
      );
    }

    await this.insertAuditLog({
      entityName: 'store_products',
      entityId: Number(product.id),
      action: AuditAction.INSERT,
      actorProfileId: input.actorProfileId,
      requestId: input.requestId,
      changes: { after: this.redactStoreImages(product) },
    });

    return this.getStoreProductById(input.storeId, Number(product.id));
  }

  async createStoreProductWithImageUpload(
    input: CreateStoreProductInput,
    image: Express.Multer.File,
    options?: { qualityMode?: MediaQualityMode; includeHd?: boolean },
  ) {
    const mediaAssetId = await this.uploadOwnedMedia({
      ownerType: MediaOwnerType.STORE_PRODUCT,
      ownerId: input.storeId,
      qualityMode: options?.qualityMode ?? MediaQualityMode.OPTIMIZED_DEFAULT,
      includeHd: options?.includeHd,
      file: image,
    });

    return this.createStoreProduct({
      ...input,
      imageMediaAssetId: mediaAssetId,
    });
  }

  async updateStoreProductWithImageUpload(
    input: UpdateStoreProductInput,
    image: Express.Multer.File,
    options?: { qualityMode?: MediaQualityMode; includeHd?: boolean },
  ) {
    const mediaAssetId = await this.uploadOwnedMedia({
      ownerType: MediaOwnerType.STORE_PRODUCT,
      ownerId: input.storeId,
      qualityMode: options?.qualityMode ?? MediaQualityMode.OPTIMIZED_DEFAULT,
      includeHd: options?.includeHd,
      file: image,
    });

    return this.updateStoreProduct({
      ...input,
      imageMediaAssetId: mediaAssetId,
    });
  }

  async updateStoreProduct(input: UpdateStoreProductInput) {
    const store = await this.getStoreEntityOrFail(input.storeId);
    this.ensureStoreOwnership(store, input.actorProfileId);

    const product = await this.storeProductRepository.findOne({
      where: {
        id: String(input.productId),
        storeId: String(input.storeId),
        deletedAt: IsNull(),
      },
    });
    if (!product) {
      throw new NotFoundException(
        `Product ${input.productId} not found for store ${input.storeId}`,
      );
    }

    const nextPrice =
      input.price !== undefined ? input.price : Number(product.price);
    const nextOfferPrice =
      input.offerPrice !== undefined
        ? input.offerPrice
        : product.offerPrice !== null
          ? Number(product.offerPrice)
          : null;
    this.validatePricing(nextPrice, nextOfferPrice);

    if (input.unitId !== undefined) {
      await this.ensureUnitExists(input.unitId);
    }
    if (input.tagIds !== undefined) {
      await this.ensureTagsExist(input.tagIds);
    }
    if (input.sectionId !== undefined && input.sectionId !== null) {
      await this.ensureSectionExists(input.storeId, input.sectionId);
    }

    const patch: Partial<StoreProductEntity> = { updatedAt: new Date() };
    if (input.name !== undefined) patch.name = input.name;
    if (input.description !== undefined) patch.description = input.description;
    if (input.price !== undefined) patch.price = input.price.toFixed(2);
    if (input.offerPrice !== undefined) {
      patch.offerPrice =
        input.offerPrice !== null ? input.offerPrice.toFixed(2) : null;
    }
    if (input.unitId !== undefined) patch.unitId = String(input.unitId);
    if (input.sectionId !== undefined) {
      patch.sectionId =
        input.sectionId !== null ? String(input.sectionId) : null;
    }
    if (input.stock !== undefined) patch.stock = input.stock;
    if (input.status !== undefined) patch.status = input.status;
    if (input.isFeatured !== undefined) patch.isFeatured = input.isFeatured;
    if (input.imageUrl !== undefined || input.imageMediaAssetId !== undefined) {
      patch.imageUrl = await this.resolveImageUrl({
        directUrl: input.imageUrl,
        mediaAssetId: input.imageMediaAssetId,
      });
    }
    if (input.imageBase64 !== undefined) {
      patch.imageUrl = input.imageBase64
        ? await this.uploadImageFromBase64(
            input.imageBase64,
            MediaOwnerType.STORE_PRODUCT,
            input.storeId,
          )
        : null;
    }

    await this.storeProductRepository.update({ id: product.id }, patch);

    if (input.tagIds !== undefined) {
      await this.syncProductTags(
        input.productId,
        input.tagIds,
        input.actorUserId,
      );
    }

    await this.insertAuditLog({
      entityName: 'store_products',
      entityId: input.productId,
      action: AuditAction.UPDATE,
      actorProfileId: input.actorProfileId,
      requestId: input.requestId,
      changes: { before: product, after: this.redactStoreImages(patch) },
    });

    return this.getStoreProductById(input.storeId, input.productId);
  }

  async softDeleteStoreProduct(
    storeId: number,
    productId: number,
    actor: ActorContext,
  ) {
    const store = await this.getStoreEntityOrFail(storeId);
    this.ensureStoreOwnership(store, actor.actorProfileId);

    const product = await this.storeProductRepository.findOne({
      where: {
        id: String(productId),
        storeId: String(storeId),
        deletedAt: IsNull(),
      },
    });
    if (!product) {
      throw new NotFoundException(
        `Product ${productId} not found for store ${storeId}`,
      );
    }

    const now = new Date();
    await this.storeProductRepository.update(
      { id: product.id },
      { deletedAt: now, status: ProductStatus.ARCHIVED, updatedAt: now },
    );

    await this.insertAuditLog({
      entityName: 'store_products',
      entityId: productId,
      action: AuditAction.DELETE,
      actorProfileId: actor.actorProfileId,
      requestId: actor.requestId,
      changes: { before: product, after: { deletedAt: now.toISOString() } },
    });

    return { id: productId, deleted: true };
  }

  async getStoreProductById(storeId: number, productId: number) {
    const product = await this.storeProductRepository.findOne({
      where: {
        id: String(productId),
        storeId: String(storeId),
        deletedAt: IsNull(),
      },
    });
    if (!product) {
      throw new NotFoundException(
        `Product ${productId} not found for store ${storeId}`,
      );
    }

    const unit = await this.productUnitRepository.findOne({
      where: { id: product.unitId },
    });
    const tags = await this.getProductTags(product.id);
    return { ...product, unit, tags };
  }

  async listStoreProducts(storeId: number) {
    const products = await this.storeProductRepository.find({
      where: { storeId: String(storeId), deletedAt: IsNull() },
      order: { id: 'DESC' },
    });

    const unitIds = [...new Set(products.map((item) => item.unitId))];
    const units = unitIds.length
      ? await this.productUnitRepository.find({ where: { id: In(unitIds) } })
      : [];
    const unitById = new Map(units.map((unit) => [unit.id, unit]));

    return products.map((product) => ({
      ...product,
      unit: unitById.get(product.unitId) ?? null,
      // imageUrl viene en el spread del entity. Tags omitidos (ligero).
    }));
  }

  /**
   * Feed del marketplace: productos PUBLICADOS de tiendas ACTIVAS, más nuevos
   * primero, paginado (limit/offset). Cada ítem incluye su unidad y una
   * referencia ligera de la tienda (id, nombre, slug, logoUrl, accentColor)
   * para pintar el encabezado de la tarjeta. Es agnóstico del perfil: no filtra
   * por vendedor ni requiere identidad.
   */
  async listFeed(params: { limit?: number; offset?: number } = {}) {
    const rawLimit = Number(params.limit);
    const limit = Number.isFinite(rawLimit)
      ? Math.min(Math.max(Math.trunc(rawLimit), 1), 50)
      : 20;
    const rawOffset = Number(params.offset);
    const offset = Number.isFinite(rawOffset) ? Math.max(Math.trunc(rawOffset), 0) : 0;

    // Tiendas activas (no borradas): referencia ligera para el encabezado.
    const stores = await this.miniStoreRepository.find({
      where: { status: StoreStatus.ACTIVE, deletedAt: IsNull() },
    });
    if (stores.length === 0) {
      return { items: [], total: 0, limit, offset };
    }
    const storeById = new Map(
      stores.map((store) => [
        store.id,
        {
          id: store.id,
          name: store.name,
          slug: store.slug,
          logoUrl: store.logoUrl,
          accentColor: store.accentColor,
        },
      ]),
    );

    // Productos publicados de esas tiendas, paginados, más nuevos primero.
    const [products, total] = await this.storeProductRepository.findAndCount({
      where: {
        storeId: In(stores.map((store) => store.id)),
        status: ProductStatus.PUBLISHED,
        deletedAt: IsNull(),
      },
      order: { id: 'DESC' },
      skip: offset,
      take: limit,
    });

    const unitIds = [...new Set(products.map((product) => product.unitId))];
    const units = unitIds.length
      ? await this.productUnitRepository.find({ where: { id: In(unitIds) } })
      : [];
    const unitById = new Map(units.map((unit) => [unit.id, unit]));

    const items = products.map((product) => ({
      ...product,
      unit: unitById.get(product.unitId) ?? null,
      store: storeById.get(product.storeId) ?? null,
    }));

    return { items, total, limit, offset };
  }

  async createStoreSection(input: CreateStoreSectionInput) {
    if (!input.name.trim()) {
      throw new BadRequestException('name is required');
    }
    if (input.position <= 0) {
      throw new BadRequestException('position must be greater than 0');
    }

    const store = await this.getStoreEntityOrFail(input.storeId);
    this.ensureStoreOwnership(store, input.actorProfileId);
    const resolvedImageUrl = await this.resolveImageUrl({
      directUrl: input.imageUrl,
      mediaAssetId: input.imageMediaAssetId,
    });

    const section = await this.storeSectionRepository.save({
      storeId: String(input.storeId),
      name: input.name,
      description: input.description ?? null,
      imageUrl: resolvedImageUrl,
      position: input.position,
      isActive: true,
    });

    await this.insertAuditLog({
      entityName: 'store_sections',
      entityId: Number(section.id),
      action: AuditAction.INSERT,
      actorProfileId: input.actorProfileId,
      requestId: input.requestId,
      changes: { after: section },
    });

    return section;
  }

  async listStoreSections(storeId: number) {
    return this.storeSectionRepository.find({
      where: { storeId: String(storeId), deletedAt: IsNull() },
      order: { position: 'ASC', id: 'ASC' },
    });
  }

  async updateStoreSection(input: UpdateStoreSectionInput) {
    const store = await this.getStoreEntityOrFail(input.storeId);
    this.ensureStoreOwnership(store, input.actorProfileId);
    const section = await this.storeSectionRepository.findOne({
      where: {
        id: String(input.sectionId),
        storeId: String(input.storeId),
        deletedAt: IsNull(),
      },
    });
    if (!section) {
      throw new NotFoundException(
        `Section ${input.sectionId} not found for store ${input.storeId}`,
      );
    }

    const patch: Partial<StoreSectionEntity> = {};
    if (input.name !== undefined) patch.name = input.name;
    if (input.description !== undefined) patch.description = input.description;
    if (input.position !== undefined) {
      if (input.position <= 0) {
        throw new BadRequestException('position must be greater than 0');
      }
      patch.position = input.position;
    }
    if (input.isActive !== undefined) patch.isActive = input.isActive;
    if (input.imageUrl !== undefined || input.imageMediaAssetId !== undefined) {
      patch.imageUrl = await this.resolveImageUrl({
        directUrl: input.imageUrl,
        mediaAssetId: input.imageMediaAssetId,
      });
    }

    await this.storeSectionRepository.update({ id: section.id }, patch);
    await this.insertAuditLog({
      entityName: 'store_sections',
      entityId: input.sectionId,
      action: AuditAction.UPDATE,
      actorProfileId: input.actorProfileId,
      requestId: input.requestId,
      changes: { before: section, after: patch },
    });

    return this.storeSectionRepository.findOneByOrFail({ id: section.id });
  }

  async softDeleteStoreSection(
    storeId: number,
    sectionId: number,
    actor: ActorContext,
  ) {
    const store = await this.getStoreEntityOrFail(storeId);
    this.ensureStoreOwnership(store, actor.actorProfileId);
    const section = await this.storeSectionRepository.findOne({
      where: {
        id: String(sectionId),
        storeId: String(storeId),
        deletedAt: IsNull(),
      },
    });
    if (!section) {
      throw new NotFoundException(
        `Section ${sectionId} not found for store ${storeId}`,
      );
    }

    await this.storeSectionRepository.update(
      { id: section.id },
      { deletedAt: new Date(), isActive: false },
    );
    await this.insertAuditLog({
      entityName: 'store_sections',
      entityId: sectionId,
      action: AuditAction.DELETE,
      actorProfileId: actor.actorProfileId,
      requestId: actor.requestId,
      changes: { before: section, after: { deletedAt: new Date().toISOString() } },
    });

    return { id: sectionId, deleted: true };
  }

  /**
   * Reordena TODAS las secciones de la tienda según `sectionIds` (quedan con
   * posiciones 1..N en ese orden). Atómico: por el UNIQUE (store_id, position)
   * primero se desplazan a un rango temporal alto y luego se asignan las
   * posiciones finales, todo dentro de una transacción. `sectionIds` debe ser
   * exactamente el conjunto de secciones vivas de la tienda.
   */
  async reorderStoreSections(input: ReorderStoreSectionsInput) {
    const store = await this.getStoreEntityOrFail(input.storeId);
    this.ensureStoreOwnership(store, input.actorProfileId);

    const current = await this.storeSectionRepository.find({
      where: { storeId: String(input.storeId), deletedAt: IsNull() },
    });

    const currentIds = current.map((s) => Number(s.id)).sort((a, b) => a - b);
    const givenIds = [...input.sectionIds].sort((a, b) => a - b);
    const sameSet =
      currentIds.length === givenIds.length &&
      currentIds.every((value, index) => value === givenIds[index]);
    if (!sameSet) {
      throw new BadRequestException(
        "sectionIds must be exactly the set of this store's sections",
      );
    }

    await this.storeSectionRepository.manager.transaction(async (manager) => {
      // Fase 1: desplazar a un rango temporal alto para no chocar con el UNIQUE.
      await manager
        .createQueryBuilder()
        .update(StoreSectionEntity)
        .set({ position: () => '"position" + 100000' })
        .where('store_id = :storeId AND deleted_at IS NULL', {
          storeId: String(input.storeId),
        })
        .execute();
      // Fase 2: posiciones finales 1..N en el orden recibido.
      let position = 1;
      for (const sectionId of input.sectionIds) {
        await manager.update(
          StoreSectionEntity,
          { id: String(sectionId) },
          { position },
        );
        position += 1;
      }
    });

    await this.insertAuditLog({
      entityName: 'store_sections',
      entityId: input.storeId,
      action: AuditAction.UPDATE,
      actorProfileId: input.actorProfileId,
      requestId: input.requestId,
      changes: { after: { order: input.sectionIds } },
    });

    return this.listStoreSections(input.storeId);
  }

  private async getStoreEntityOrFail(storeId: number) {
    const store = await this.miniStoreRepository.findOne({
      where: { id: String(storeId), deletedAt: IsNull() },
    });
    if (!store) {
      throw new NotFoundException(`Store ${storeId} not found`);
    }
    return store;
  }

  private ensureStoreOwnership(store: MiniStoreEntity, actorProfileId: number | null) {
    if (
      actorProfileId !== null &&
      Number(store.sellerProfileId) !== actorProfileId
    ) {
      throw new BadRequestException(
        'Authenticated profile does not own this store',
      );
    }
  }

  private async replaceStoreOptions(
    storeId: string,
    input: { deliveryOptions?: DeliveryOption[]; paymentMethods?: PaymentMethod[] },
  ) {
    if (input.deliveryOptions !== undefined) {
      await this.storeDeliveryOptionRepository.delete({ storeId });
      if (input.deliveryOptions.length > 0) {
        await this.storeDeliveryOptionRepository.save(
          input.deliveryOptions.map((option) => ({ storeId, option })),
        );
      }
    }

    if (input.paymentMethods !== undefined) {
      await this.storePaymentMethodRepository.delete({ storeId });
      if (input.paymentMethods.length > 0) {
        await this.storePaymentMethodRepository.save(
          input.paymentMethods.map((method) => ({ storeId, method })),
        );
      }
    }
  }

  /**
   * Reemplaza las zonas de cobertura de la tienda. `undefined` no toca nada;
   * cualquier lista (incluida []) reemplaza el conjunto. Valida que los ids
   * existan en el catálogo (impide marcar zonas fuera de las definidas).
   */
  private async replaceCoverageZones(storeId: string, zoneIds?: number[]) {
    if (zoneIds === undefined) return;
    const unique = [...new Set(zoneIds)];
    await this.ensureCoverageZonesExist(unique);
    await this.storeCoverageZoneRepository.delete({ storeId });
    if (unique.length > 0) {
      await this.storeCoverageZoneRepository.save(
        unique.map((zoneId) => ({ storeId, zoneId: String(zoneId) })),
      );
    }
  }

  private async ensureCoverageZonesExist(zoneIds: number[]) {
    if (zoneIds.length === 0) return;
    const found = await this.coverageZoneRepository.find({
      where: { id: In(zoneIds.map((id) => String(id))), isActive: true },
    });
    if (found.length !== zoneIds.length) {
      throw new BadRequestException('One or more coverageZoneIds are invalid');
    }
  }

  /** Tamaño máximo (bytes) de una imagen de identidad decodificada. */
  private static readonly MAX_IMAGE_BYTES = 3 * 1024 * 1024; // 3 MB

  /**
   * Decodifica una imagen base64 (data URI `data:image/...;base64,xxx` o base64
   * puro) a bytes + mime. Devuelve null si la entrada es null/''. Lanza
   * BadRequest si no es imagen o excede el tamaño máximo.
   */
  private decodeImageInput(
    input: string | null | undefined,
  ): { data: Buffer; mime: string } | null {
    if (input === undefined || input === null) return null;
    const trimmed = input.trim();
    if (trimmed.length === 0) return null;

    let mime: string | null = null;
    let base64 = trimmed;
    const match = /^data:([^;,]+);base64,(.*)$/s.exec(trimmed);
    if (match) {
      mime = match[1];
      base64 = match[2];
    }

    if (mime && !mime.toLowerCase().startsWith('image/')) {
      throw new BadRequestException('Solo se permiten imágenes (image/*)');
    }

    const data = Buffer.from(base64, 'base64');
    if (data.length === 0) {
      throw new BadRequestException('Imagen base64 inválida o vacía');
    }
    if (data.length > MinistoresService.MAX_IMAGE_BYTES) {
      throw new BadRequestException('La imagen supera el máximo permitido (3 MB)');
    }
    return { data, mime: mime ?? 'image/jpeg' };
  }

  /** Reemplaza los bytes de imagen por un marcador para no inflar los audit logs. */
  private redactStoreImages(obj: object): Record<string, unknown> {
    const copy: Record<string, unknown> = { ...obj };
    if ('logoImage' in copy) copy.logoImage = copy.logoImage ? '[blob]' : null;
    if ('coverImage' in copy) copy.coverImage = copy.coverImage ? '[blob]' : null;
    if ('imageBlob' in copy) copy.imageBlob = copy.imageBlob ? '[blob]' : null;
    return copy;
  }

  /**
   * Decodifica una imagen base64 y la PERSISTE como ARCHIVO vía el módulo media
   * (disco + variantes optimized/thumbnail). Devuelve la URL preferida (relativa
   * si MEDIA_PUBLIC_BASE_URL está vacío). Reemplaza el guardado como blob en BD.
   */
  private async uploadImageFromBase64(
    base64: string,
    ownerType: MediaOwnerType,
    ownerId: number,
  ): Promise<string | null> {
    const decoded = this.decodeImageInput(base64);
    if (!decoded) return null;
    const asset = await this.mediaService.uploadAndProcessImage({
      ownerType,
      ownerId,
      fileBuffer: decoded.data,
      mimeType: decoded.mime,
    });
    return this.mediaService.resolvePreferredUrl(Number(asset.id));
  }

  private async resolveImageUrl(input: {
    directUrl?: string | null;
    mediaAssetId?: number | null;
  }) {
    if (input.mediaAssetId !== undefined && input.mediaAssetId !== null) {
      return this.mediaService.resolvePreferredUrl(input.mediaAssetId);
    }
    return input.directUrl ?? null;
  }

  private async ensureCategoryExists(categoryId: number) {
    const category = await this.storeCategoryRepository.findOne({
      where: { id: String(categoryId), isActive: true },
    });
    if (!category) {
      throw new BadRequestException(`categoryId ${categoryId} does not exist`);
    }
  }

  private async ensureUnitExists(unitId: number) {
    const unit = await this.productUnitRepository.findOne({
      where: { id: String(unitId), isActive: true },
    });
    if (!unit) {
      throw new BadRequestException(`unitId ${unitId} does not exist`);
    }
  }

  private async ensureSectionExists(storeId: number, sectionId: number) {
    const section = await this.storeSectionRepository.findOne({
      where: {
        id: String(sectionId),
        storeId: String(storeId),
        deletedAt: IsNull(),
      },
    });
    if (!section) {
      throw new BadRequestException(
        `sectionId ${sectionId} does not exist for store ${storeId}`,
      );
    }
  }

  private async ensureTagsExist(tagIds: number[]) {
    if (tagIds.length === 0) {
      return;
    }
    const uniqueTagIds = [...new Set(tagIds)];
    const tags = await this.productTagRepository.find({
      where: {
        id: In(uniqueTagIds.map((id) => String(id))),
        isActive: true,
      },
    });
    if (tags.length !== uniqueTagIds.length) {
      throw new BadRequestException(
        'One or more tagIds are invalid or inactive',
      );
    }
  }

  private async syncProductTags(
    productId: number,
    tagIds: number[],
    actorUserId: number | null,
  ) {
    await this.storeProductTagRepository.delete({ productId: String(productId) });
    const uniqueTagIds = [...new Set(tagIds)];
    if (uniqueTagIds.length === 0) {
      return;
    }
    await this.storeProductTagRepository.save(
      uniqueTagIds.map((tagId) => ({
        productId: String(productId),
        tagId: String(tagId),
        createdBy: actorUserId !== null ? String(actorUserId) : null,
        updatedBy: actorUserId !== null ? String(actorUserId) : null,
      })),
    );
  }

  private async getProductTags(productId: string) {
    const mappings = await this.storeProductTagRepository.find({
      where: { productId },
      order: { tagId: 'ASC' },
    });
    if (mappings.length === 0) {
      return [];
    }
    const tags = await this.productTagRepository.find({
      where: { id: In(mappings.map((item) => item.tagId)) },
      order: { name: 'ASC' },
    });
    return tags;
  }

  private validateCreateStoreInput(input: CreateStoreInput) {
    if (!input.name.trim()) {
      throw new BadRequestException('name is required');
    }
    if (!input.slug.trim()) {
      throw new BadRequestException('slug is required');
    }
    if (!/^#[0-9A-Fa-f]{6}$/.test(input.accentColor)) {
      throw new BadRequestException('accentColor must be a hex color (#RRGGBB)');
    }
    if (input.sellerProfileId <= 0) {
      throw new BadRequestException('sellerProfileId must be positive');
    }
  }

  private validateCreateProductInput(input: CreateStoreProductInput) {
    if (!input.name.trim()) {
      throw new BadRequestException('name is required');
    }
    this.validatePricing(input.price, input.offerPrice ?? null);
  }

  private validatePricing(price: number, offerPrice: number | null) {
    if (price < 0) {
      throw new BadRequestException('price cannot be negative');
    }
    if (offerPrice !== null) {
      if (offerPrice < 0) {
        throw new BadRequestException('offerPrice cannot be negative');
      }
      if (offerPrice > price) {
        throw new BadRequestException(
          'offerPrice cannot be greater than price',
        );
      }
    }
  }

  private async uploadOwnedMedia(input: {
    ownerType: MediaOwnerType;
    ownerId: number;
    qualityMode: MediaQualityMode;
    includeHd?: boolean;
    file: Express.Multer.File;
  }) {
    const uploadInput: UploadMediaInput = {
      ownerType: input.ownerType,
      ownerId: input.ownerId,
      qualityMode: input.qualityMode,
      includeHd: input.includeHd,
      fileBuffer: input.file.buffer,
      mimeType: input.file.mimetype,
      originalFilename: input.file.originalname,
    };
    const asset = await this.mediaService.uploadAndProcessImage(uploadInput);
    return Number(asset.id);
  }

  private async insertAuditLog(input: {
    entityName: string;
    entityId: number;
    action: AuditAction;
    actorProfileId: number | null;
    requestId: string | null;
    changes: Record<string, unknown>;
  }) {
    await this.auditLogRepository.save(
      this.auditLogRepository.create({
        entityName: input.entityName,
        entityId: String(input.entityId),
        action: input.action,
        actorProfileId:
          input.actorProfileId !== null ? String(input.actorProfileId) : null,
        requestId: input.requestId,
        changes: input.changes,
      }),
    );
  }
}
