import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { AuditAction } from '../../domain/ministores.enums.js';
import { MinistoresService } from '../../application/ministores.service.js';

interface AuditLogQuery {
  entityName?: string;
  entityId?: string;
  action?: AuditAction;
  actorProfileId?: string;
  limit?: string;
}

@Controller('audit-logs')
export class AuditLogsController {
  constructor(private readonly ministoresService: MinistoresService) {}

  @Get()
  async listAuditLogs(@Query() query: AuditLogQuery) {
    if (query.action && !Object.values(AuditAction).includes(query.action)) {
      throw new BadRequestException(
        `action must be one of: ${Object.values(AuditAction).join(', ')}`,
      );
    }
    return this.ministoresService.listAuditLogs({
      entityName: query.entityName,
      entityId: this.parseOptionalInt(query.entityId, 'entityId'),
      action: query.action,
      actorProfileId: this.parseOptionalInt(query.actorProfileId, 'actorProfileId'),
      limit: this.parseOptionalInt(query.limit, 'limit'),
    });
  }

  private parseOptionalInt(
    value: string | undefined,
    fieldName: string,
  ): number | undefined {
    if (!value) {
      return undefined;
    }
    const parsed = Number(value);
    if (!Number.isFinite(parsed) || parsed < 0 || !Number.isInteger(parsed)) {
      throw new BadRequestException(`${fieldName} must be a positive integer`);
    }
    return parsed;
  }
}
