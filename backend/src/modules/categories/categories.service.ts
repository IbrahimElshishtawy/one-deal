import {
  Injectable,
  NotFoundException,
  ConflictException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { CreateCategoryFieldDto } from './dto/create-category-field.dto';

const CATEGORIES_CACHE_TTL_SECONDS = 600; // 10 minutes

@Injectable()
export class CategoriesService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  /**
   * Returns root categories and their subcategories hierarchy (cached in Redis).
   */
  async getCategoryTree() {
    const cacheKey = 'categories:tree';
    const cached = await this.redis?.get<any[]>(cacheKey);
    if (cached) {
      return cached;
    }

    const tree = await this.prisma.category.findMany({
      where: { parentId: null, isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: {
        children: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });

    await this.redis?.set(cacheKey, tree, CATEGORIES_CACHE_TTL_SECONDS);
    return tree;
  }

  /**
   * Retrieves category by slug or UUID.
   */
  async getCategoryBySlug(identifier: string) {
    const cacheKey = `categories:item:${identifier}`;
    const cached = await this.redis?.get<any>(cacheKey);
    if (cached) {
      return cached;
    }

    const isUuid =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        identifier,
      );
    const category = await this.prisma.category.findUnique({
      where: isUuid ? { id: identifier } : { slug: identifier },
      include: {
        children: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });

    if (!category) {
      throw new NotFoundException(
        `Category with identifier '${identifier}' not found`,
      );
    }

    await this.redis?.set(cacheKey, category, CATEGORIES_CACHE_TTL_SECONDS);
    return category;
  }

  /**
   * Retrieves active dynamic attribute schemas for a specific subcategory by slug or UUID.
   */
  async getCategoryFields(identifier: string) {
    const cacheKey = `categories:fields:${identifier}`;
    const cached = await this.redis?.get<any[]>(cacheKey);
    if (cached) {
      return cached;
    }

    const isUuid =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        identifier,
      );
    const category = await this.prisma.category.findUnique({
      where: isUuid ? { id: identifier } : { slug: identifier },
      include: {
        fields: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });

    if (!category) {
      throw new NotFoundException(
        `Category with identifier '${identifier}' not found`,
      );
    }

    await this.redis?.set(
      cacheKey,
      category.fields,
      CATEGORIES_CACHE_TTL_SECONDS,
    );
    return category.fields;
  }

  /**
   * Admin: Creates a new category or subcategory and invalidates tree cache.
   */
  async createCategory(dto: CreateCategoryDto) {
    const existing = await this.prisma.category.findUnique({
      where: { slug: dto.slug },
    });

    if (existing) {
      throw new ConflictException(
        `Category with slug '${dto.slug}' already exists`,
      );
    }

    const created = await this.prisma.category.create({
      data: {
        slug: dto.slug,
        nameAr: dto.nameAr,
        nameEn: dto.nameEn,
        iconUrl: dto.iconUrl ?? dto.iconName,
        parentId: dto.parentId,
        sortOrder: dto.sortOrder ?? 0,
        isActive: dto.isActive ?? true,
      },
    });

    await this.redis?.del('categories:tree');
    await this.redis?.incr?.('home:feed:ver').catch(() => undefined);
    return created;
  }

  /**
   * Admin: Upserts a dynamic attribute specification for a subcategory and invalidates cache.
   */
  async upsertCategoryField(categoryId: string, dto: CreateCategoryFieldDto) {
    const upserted = await this.prisma.categoryField.upsert({
      where: {
        uq_cat_field_key: {
          categoryId,
          fieldKey: dto.fieldKey,
        },
      },
      update: {
        fieldType: dto.fieldType,
        labelAr: dto.labelAr,
        labelEn: dto.labelEn,
        isRequired: dto.isRequired ?? false,
        isFilterable: dto.isFilterable ?? true,
        validationRules: (dto.validationRules as any) ?? {},
        sortOrder: dto.sortOrder ?? 0,
        isActive: true,
      },
      create: {
        categoryId,
        fieldKey: dto.fieldKey,
        fieldType: dto.fieldType,
        labelAr: dto.labelAr,
        labelEn: dto.labelEn,
        isRequired: dto.isRequired ?? false,
        isFilterable: dto.isFilterable ?? true,
        validationRules: (dto.validationRules as any) ?? {},
        sortOrder: dto.sortOrder ?? 0,
      },
    });

    await this.redis?.del(`categories:fields:${categoryId}`);
    return upserted;
  }
}
