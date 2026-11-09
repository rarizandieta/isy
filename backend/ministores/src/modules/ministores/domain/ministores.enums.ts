export enum StoreStatus {
  DRAFT = 'draft',
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  SUSPENDED = 'suspended',
}

export enum ProductStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  ARCHIVED = 'archived',
}

export enum StockStatus {
  AVAILABLE = 'available',
  SOLD_OUT = 'sold_out',
  MADE_TO_ORDER = 'made_to_order',
}

export enum DeliveryOption {
  PICKUP = 'pickup',
  DELIVERY = 'delivery',
  SHIPPING = 'shipping',
}

export enum PaymentMethod {
  CASH = 'cash',
  TRANSFER = 'transfer',
  CARD = 'card',
}

export enum AuditAction {
  INSERT = 'insert',
  UPDATE = 'update',
  DELETE = 'delete',
  STATUS_CHANGE = 'status_change',
}
