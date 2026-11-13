import { IsIn, IsString, MaxLength, MinLength } from 'class-validator';

/**
 * Cuerpo de POST /auth/profiles. Solo se pueden crear perfiles 'seller' o
 * 'service_provider' (el 'buyer' se crea automáticamente al registrarse).
 */
export class CreateProfileDto {
  @IsIn(['seller', 'service_provider'])
  type!: 'seller' | 'service_provider';

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  displayName!: string;
}
