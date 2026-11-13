import { Controller, Get, Query } from '@nestjs/common';
import { MinistoresService } from '../../application/ministores.service.js';

/**
 * Feed público del marketplace: productos publicados de tiendas activas.
 * `GET /feed?limit=&offset=`. No requiere perfil ni token (ver gateway: ruta
 * pública), igual que la lectura de imágenes en /media/files.
 */
@Controller('feed')
export class FeedController {
  constructor(private readonly ministoresService: MinistoresService) {}

  @Get()
  async getFeed(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.ministoresService.listFeed({
      limit: limit !== undefined ? Number(limit) : undefined,
      offset: offset !== undefined ? Number(offset) : undefined,
    });
  }
}
