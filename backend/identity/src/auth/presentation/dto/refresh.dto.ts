import { IsNotEmpty, IsString } from 'class-validator';

/** Cuerpo compartido por POST /auth/refresh y POST /auth/logout. */
export class RefreshTokenDto {
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}
