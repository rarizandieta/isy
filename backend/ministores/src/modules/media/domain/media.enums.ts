export enum MediaAssetStatus {
  PROCESSING = 'processing',
  READY = 'ready',
  FAILED = 'failed',
  DELETED = 'deleted',
}

export enum MediaVariantType {
  OPTIMIZED = 'optimized',
  THUMBNAIL = 'thumbnail',
  HD = 'hd',
}

export enum MediaQualityMode {
  OPTIMIZED_DEFAULT = 'optimized_default',
  HD_DEFAULT = 'hd_default',
}

export enum MediaOwnerType {
  MINI_STORE = 'mini_store',
  STORE_PRODUCT = 'store_product',
  STORE_CATEGORY = 'store_category',
  STORE_SECTION = 'store_section',
}
