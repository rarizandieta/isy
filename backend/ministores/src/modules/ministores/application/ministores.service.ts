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
  scheduleText?: string | null;
  zoneText?: string | null;
  isOpen?: boolean;
  status?: StoreStatus;
  deliveryOptions?: DeliveryOption[];
  paymentMethods?: PaymentMethod[];
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
  scheduleText?: string | null;
  zoneText?: string | null;
  isOpen?: boolean;
  status?: StoreStatus;
  deliveryOptions?: DeliveryOption[];
  paymentMethods?: PaymentMethod[];
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
    private readonly mediaService: MediaService,
  ) {}

  async listCategories() {
    return this.storeCategoryRepository.find({
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

    const store = await this.miniStoreRepository.save({
      sellerProfileId: String(input.sellerProfileId),
      slug: input.slug,
      name: input.name,
      tagline: input.tagline ?? null,
      description: input.description ?? null,
      categoryId: String(input.categoryId),
      logoUrl: resolvedLogoUrl,
      coverUrl: resolvedCoverUrl,
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

    await this.insertAuditLog({
      entityName: 'mini_stores',
      entityId: Number(store.id),
      action: AuditAction.INSERT,
      actorProfileId: input.actorProfileId,
      requestId: input.requestId,
      changes: { after: store },
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

    await this.miniStoreRepository.update({ id: store.id }, patch);

    await this.replaceStoreOptions(store.id, {
      deliveryOptions: input.deliveryOptions,
      paymentMethods: input.paymentMethods,
    });

    await this.insertAuditLog({
      entityName: 'mini_stores',
      entityId: Number(store.id),
      action: AuditAction.UPDATE,
      actorProfileId: input.actorProfileId,
      requestId: input.requestId,
      changes: { before: store, after: patch },
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

    return {
      ...store,
      category,
      delivery_options: deliveryOptions.map((item) => item.option),
      payment_methods: paymentMethods.map((item) => item.method),
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
      imageUrl: resolvedImageUrl,
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
      changes: { after: product },
    });

    return product;
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
      changes: { before: product, after: patch },
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
      // Kept lightweight for list calls; use get by id for full tags payload if needed.
    }));
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
