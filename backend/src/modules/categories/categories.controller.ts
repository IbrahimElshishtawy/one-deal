import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { CreateCategoryFieldDto } from './dto/create-category-field.dto';
import {
  ReorderCategoriesDto,
  UpdateCategoryDto,
  UpdateCategoryFieldDto,
} from './dto/update-category.dto';
import { AdminJwtAuthGuard } from '../admin-auth/guards/admin-jwt-auth.guard';
import { PermissionsGuard } from '../admin-auth/guards/permissions.guard';
import {
  CurrentStaff,
  Permissions,
} from '../admin-auth/decorators/permissions.decorator';
import { AuthenticatedStaff } from '../admin-auth/types/authenticated-staff.type';

@ApiTags('Categories')
@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Get()
  @ApiOperation({ summary: 'Get category tree (Root & Subcategories)' })
  @ApiResponse({ status: 200, description: 'Categories taxonomy returned' })
  async getCategoryTree() {
    return this.categoriesService.getCategoryTree();
  }

  @Get(':slug')
  @ApiOperation({ summary: 'Get category by slug' })
  @ApiResponse({ status: 200, description: 'Category details returned' })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async getCategoryBySlug(@Param('slug') slug: string) {
    return this.categoriesService.getCategoryBySlug(slug);
  }

  @Get(':slug/fields')
  @ApiOperation({ summary: 'Get dynamic attribute fields for a subcategory' })
  @ApiResponse({ status: 200, description: 'Dynamic field schema returned' })
  @ApiResponse({ status: 404, description: 'Category not found' })
  async getCategoryFields(@Param('slug') slug: string) {
    return this.categoriesService.getCategoryFields(slug);
  }
}

@ApiTags('Admin / Categories')
@ApiBearerAuth('BearerAuth')
@UseGuards(AdminJwtAuthGuard, PermissionsGuard)
@Controller('admin/categories')
export class AdminCategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Get()
  @Permissions('categories.read')
  @ApiOperation({
    summary: 'List full category tree including inactive categories and stats',
  })
  async listAllAdminCategories() {
    return this.categoriesService.listAdminCategories();
  }

  @Post()
  @Permissions('categories.create')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create new root category or subcategory' })
  @ApiResponse({ status: 201, description: 'Category created' })
  @ApiResponse({ status: 409, description: 'Category slug already exists' })
  async createCategory(
    @Body() dto: CreateCategoryDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.categoriesService.createCategory(dto, staff.id);
  }

  @Patch('reorder')
  @Permissions('categories.update')
  @ApiOperation({ summary: 'Batch update display ordering of categories' })
  async reorderCategories(
    @Body() dto: ReorderCategoriesDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.categoriesService.reorderCategories(dto.items, staff.id);
  }

  @Patch(':id')
  @Permissions('categories.update')
  @ApiOperation({ summary: 'Update category metadata, parent, or active status' })
  async updateCategory(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCategoryDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.categoriesService.updateCategory(id, dto, staff.id);
  }

  @Delete(':id')
  @Permissions('categories.delete')
  @ApiOperation({
    summary: 'Delete unused category or safely deactivate if listings/children exist',
  })
  async deleteOrDeactivateCategory(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.categoriesService.deleteOrDeactivateCategory(id, staff.id);
  }

  @Get(':id/fields')
  @Permissions('categories.read')
  @ApiOperation({ summary: 'List all dynamic fields (active and inactive) for a category' })
  async listCategoryFields(@Param('id', ParseUUIDPipe) categoryId: string) {
    return this.categoriesService.listAdminCategoryFields(categoryId);
  }

  @Post(':id/fields')
  @Permissions('categories.update')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Define or update a dynamic attribute field for a subcategory',
  })
  @ApiResponse({ status: 200, description: 'Field schema saved' })
  async upsertField(
    @Param('id', ParseUUIDPipe) categoryId: string,
    @Body() dto: CreateCategoryFieldDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.categoriesService.upsertCategoryField(
      categoryId,
      dto,
      staff.id,
    );
  }

  @Patch(':id/fields/:fieldId')
  @Permissions('categories.update')
  @ApiOperation({ summary: 'Update dynamic attribute field configuration' })
  async updateField(
    @Param('id', ParseUUIDPipe) categoryId: string,
    @Param('fieldId', ParseUUIDPipe) fieldId: string,
    @Body() dto: UpdateCategoryFieldDto,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.categoriesService.updateCategoryField(
      categoryId,
      fieldId,
      dto,
      staff.id,
    );
  }

  @Delete(':id/fields/:fieldId')
  @Permissions('categories.delete')
  @ApiOperation({ summary: 'Deactivate a dynamic attribute field' })
  async deactivateField(
    @Param('id', ParseUUIDPipe) categoryId: string,
    @Param('fieldId', ParseUUIDPipe) fieldId: string,
    @CurrentStaff() staff: AuthenticatedStaff,
  ) {
    return this.categoriesService.deactivateCategoryField(
      categoryId,
      fieldId,
      staff.id,
    );
  }
}
