import { Body, Controller, Get, Param, ParseIntPipe, Patch, Post } from '@nestjs/common';
import {
  MinistoresService,
  CreateStoreCategoryInput,
  CreateProductUnitInput,
  UpdateProductUnitInput,
  CreateProductTagInput,
  UpdateProductTagInput,
} from '../../application/ministores.service.js';

interface UpdateCategoryBody {
  name?: string;
  description?: string | null;
  imageUrl?: string | null;
  imageMediaAssetId?: number | null;
  isActive?: boolean;
}

interface CreateCategoryBody extends CreateStoreCategoryInput {}
interface CreateUnitBody extends CreateProductUnitInput {}
interface CreateTagBody extends CreateProductTagInput {}

@Controller('catalogs')
export class CatalogsController {
  constructor(private readonly ministoresService: MinistoresService) {}

  @Get('categories')
  async listCategories() {
    return this.ministoresService.listCategories();
  }

  @Get('units')
  async listUnits() {
    return this.ministoresService.listUnits();
  }

  @Get('tags')
  async listTags() {
    return this.ministoresService.listTags();
  }

  @Get('coverage-zones')
  async listCoverageZones() {
    return this.ministoresService.listCoverageZones();
  }

  @Post('categories')
  async createCategory(@Body() body: CreateCategoryBody) {
    return this.ministoresService.createCategory(body);
  }

  @Patch('categories/:id')
  async updateCategory(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: UpdateCategoryBody,
  ) {
    return this.ministoresService.updateCategory({
      categoryId: id,
      ...body,
    });
  }

  @Post('units')
  async createUnit(@Body() body: CreateUnitBody) {
    return this.ministoresService.createUnit(body);
  }

  @Patch('units/:id')
  async updateUnit(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: Omit<UpdateProductUnitInput, 'unitId'>,
  ) {
    return this.ministoresService.updateUnit({
      unitId: id,
      ...body,
    });
  }

  @Post('tags')
  async createTag(@Body() body: CreateTagBody) {
    return this.ministoresService.createTag(body);
  }

  @Patch('tags/:id')
  async updateTag(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: Omit<UpdateProductTagInput, 'tagId'>,
  ) {
    return this.ministoresService.updateTag({
      tagId: id,
      ...body,
    });
  }
}
