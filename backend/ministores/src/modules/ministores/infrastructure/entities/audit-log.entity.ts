import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { AuditAction } from '../../domain/ministores.enums.js';

@Entity({ name: 'audit_logs' })
export class AuditLogEntity {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({ name: 'entity_name', type: 'varchar', length: 80 })
  entityName!: string;

  @Column({ name: 'entity_id', type: 'bigint' })
  entityId!: string;

  @Column({ type: 'enum', enum: AuditAction })
  action!: AuditAction;

  @Column({ name: 'actor_profile_id', type: 'bigint', nullable: true })
  actorProfileId!: string | null;

  @Column({ name: 'request_id', type: 'varchar', length: 100, nullable: true })
  requestId!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  changes!: Record<string, unknown> | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;
}
