import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { ProfileList, ProfileMutationResult } from '../application/dto/auth.dto.js';
import { AuthService } from '../application/services/auth.service.js';
import { CreateProfileDto } from './dto/create-profile.dto.js';
import { type AuthenticatedRequest, JwtAuthGuard } from './guards/jwt-auth.guard.js';

/**
 * Gestión de perfiles del usuario (requiere access token válido).
 *
 * Un usuario nace con un perfil `buyer`. Aquí puede crear un perfil `seller`
 * (o `service_provider`) y cambiar cuál es el perfil ACTIVO. Como el perfil
 * activo viaja dentro del access token (y el gateway lo propaga a los
 * microservicios), crear o cambiar de perfil re-emite el access token: la
 * respuesta incluye el nuevo token, que el cliente debe empezar a usar.
 */
@UseGuards(JwtAuthGuard)
@Controller('auth/profiles')
export class ProfilesController {
  constructor(private readonly auth: AuthService) {}

  /** Lista los perfiles del usuario e indica cuál está activo. */
  @Get()
  list(@Req() req: AuthenticatedRequest): Promise<ProfileList> {
    return this.auth.listProfiles(req.user.sub);
  }

  /** Crea un perfil (vendedor/servicios), lo activa y re-emite el access token. */
  @Post()
  @HttpCode(201)
  create(
    @Req() req: AuthenticatedRequest,
    @Body() dto: CreateProfileDto,
  ): Promise<ProfileMutationResult> {
    return this.auth.createProfile(req.user.sub, dto);
  }

  /** Cambia el perfil activo y re-emite el access token. */
  @Post(':id/activate')
  @HttpCode(200)
  activate(
    @Req() req: AuthenticatedRequest,
    @Param('id', ParseIntPipe) id: number,
  ): Promise<ProfileMutationResult> {
    return this.auth.switchProfile(req.user.sub, id);
  }
}
