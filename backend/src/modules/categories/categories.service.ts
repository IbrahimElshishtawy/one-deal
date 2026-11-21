import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { CreateCategoryFieldDto } from './dto/create-category-field.dto';
import {
  ReorderCategoryItemDto,
  UpdateCategoryDto,
  UpdateCategoryFieldDto,
} from './dto/update-category.dto';

const CATEGORIES_CACHE_TTL_SECONDS = 600; // 10 minutes

@Injectable()
export class CategoriesService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly redis?: RedisService,
  ) {}

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

  async listAdminCategories() {
    return this.prisma.category.findMany({
      where: { parentId: null },
      orderBy: { sortOrder: 'asc' },
      include: {
        _count: { select: { listings: true, fields: true } },
        children: {
          orderBy: { sortOrder: 'asc' },
          include: {
            _count: { select: { listings: true, fields: true } },
            fields: { orderBy: { sortOrder: 'asc' } },
          },
        },
        fields: { orderBy: { sortOrder: 'asc' } },
      },
    });
  }

  async createCategory(dto: CreateCategoryDto, actorId?: string) {
    const existing = await this.prisma.category.findUnique({
      where: { slug: dto.slug },
    });

    if (existing) {
      throw new ConflictException(
        `Category with slug '${dto.slug}' already exists`,
      );
    }

    if (!actorId || typeof this.prisma.$transaction !== 'function') {
      const created = await this.prisma.category.create({
        data: {
          slug: dto.slug.trim(),
          nameAr: dto.nameAr.trim(),
          nameEn: dto.nameEn.trim(),
          iconUrl: dto.iconUrl ?? dto.iconName,
          parentId: dto.parentId,
          sortOrder: dto.sortOrder ?? 0,
          isActive: dto.isActive ?? true,
        },
      });
      await this.invalidateCategoryCaches(created.id, created.slug);
      return created;
    }

    const created = await this.prisma.$transaction(async (tx) => {
      const cat = await tx.category.create({
        data: {
          slug: dto.slug.trim(),
          nameAr: dto.nameAr.trim(),
          nameEn: dto.nameEn.trim(),
          iconUrl: dto.iconUrl ?? dto.iconName,
          parentId: dto.parentId,
          sortOrder: dto.sortOrder ?? 0,
          isActive: dto.isActive ?? true,
        },
      });

      if (actorId) {
        await tx.auditLog.create({
          data: {
            actorType: 'staff',
            actorId,
            action: 'CATEGORY_CREATED',
            targetEntity: 'category',
            targetId: cat.id,
            diffPayload: {
              slug: cat.slug,
              nameAr: cat.nameAr,
              nameEn: cat.nameEn,
              parentId: cat.parentId,
            },
          },
        });
      }
      return cat;
    });

    await this.invalidateCategoryCaches(created.id, created.slug);
    return created;
  }

  async updateCategory(id: string, dto: UpdateCategoryDto, actorId: string) {
    const existing = await this.prisma.category.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException('Category not found');
    }

    if (dto.parentId === id) {
      throw new BadRequestException('Category cannot be its own parent.');
    }

    if (dto.slug && dto.slug !== existing.slug) {
      const slugTaken = await this.prisma.category.findUnique({
        where: { slug: dto.slug },
      });
      if (slugTaken) {
        throw new ConflictException(
          `Category slug '${dto.slug}' already exists`,
        );
      }
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const cat = await tx.category.update({
        where: { id },
        data: {
          ...(dto.slug !== undefined ? { slug: dto.slug.trim() } : {}),
          ...(dto.nameAr !== undefined ? { nameAr: dto.nameAr.trim() } : {}),
          ...(dto.nameEn !== undefined ? { nameEn: dto.nameEn.trim() } : {}),
          ...(dto.iconUrl !== undefined ? { iconUrl: dto.iconUrl } : {}),
          ...(dto.parentId !== undefined ? { parentId: dto.parentId } : {}),
          ...(dto.sortOrder !== undefined ? { sortOrder: dto.sortOrder } : {}),
          ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'CATEGORY_UPDATED',
          targetEntity: 'category',
          targetId: id,
          diffPayload: {
            previous: {
              nameAr: existing.nameAr,
              nameEn: existing.nameEn,
              isActive: existing.isActive,
              sortOrder: existing.sortOrder,
            },
            next: {
              nameAr: cat.nameAr,
              nameEn: cat.nameEn,
              isActive: cat.isActive,
              sortOrder: cat.sortOrder,
            },
          },
        },
      });
      return cat;
    });

    await this.invalidateCategoryCaches(id, existing.slug, updated.slug);
    return updated;
  }

  async reorderCategories(items: ReorderCategoryItemDto[], actorId: string) {
    await this.prisma.$transaction(async (tx) => {
      for (const item of items) {
        await tx.category.update({
          where: { id: item.id },
          data: { sortOrder: item.sortOrder },
        });
      }
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'CATEGORIES_REORDERED',
          targetEntity: 'category',
          diffPayload: { count: items.length },
        },
      });
    });

    await this.invalidateCategoryCaches();
    return { success: true, updatedCount: items.length };
  }

  async deleteOrDeactivateCategory(id: string, actorId: string) {
    const existing = await this.prisma.category.findUnique({
      where: { id },
      include: { _count: { select: { listings: true, children: true } } },
    });
    if (!existing) {
      throw new NotFoundException('Category not found');
    }

    const hasDependencies =
      existing._count.listings > 0 || existing._count.children > 0;

    if (hasDependencies) {
      const updated = await this.prisma.$transaction(async (tx) => {
        const cat = await tx.category.update({
          where: { id },
          data: { isActive: false },
        });
        await tx.auditLog.create({
          data: {
            actorType: 'staff',
            actorId,
            action: 'CATEGORY_DEACTIVATED',
            targetEntity: 'category',
            targetId: id,
            diffPayload: {
              reason: 'HAS_LISTINGS_OR_CHILDREN',
              listingsCount: existing._count.listings,
              childrenCount: existing._count.children,
            },
          },
        });
        return cat;
      });
      await this.invalidateCategoryCaches(id, existing.slug);
      return { action: 'deactivated', category: updated };
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.category.delete({ where: { id } });
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'CATEGORY_DELETED',
          targetEntity: 'category',
          targetId: id,
          diffPayload: { slug: existing.slug },
        },
      });
    });
    await this.invalidateCategoryCaches(id, existing.slug);
    return { action: 'deleted', id };
  }

  async listAdminCategoryFields(categoryId: string) {
    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
      include: { fields: { orderBy: { sortOrder: 'asc' } } },
    });
    if (!category) {
      throw new NotFoundException('Category not found');
    }
    return category.fields;
  }

  async upsertCategoryField(
    categoryId: string,
    dto: CreateCategoryFieldDto,
    actorId?: string,
  ) {
    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
      select: { id: true, slug: true },
    });
    if (!category) {
      throw new NotFoundException('Category not found');
    }

    const runUpsert = async (client: any) => {
      const field = await client.categoryField.upsert({
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

      if (actorId && client.auditLog?.create) {
        await client.auditLog.create({
          data: {
            actorType: 'staff',
            actorId,
            action: 'CATEGORY_FIELD_UPSERTED',
            targetEntity: 'category_field',
            targetId: field.id,
            diffPayload: {
              categoryId,
              fieldKey: field.fieldKey,
              isRequired: field.isRequired,
              isFilterable: field.isFilterable,
            },
          },
        });
      }
      return field;
    };

    const upserted =
      !actorId || typeof this.prisma.$transaction !== 'function'
        ? await runUpsert(this.prisma)
        : await this.prisma.$transaction((tx) => runUpsert(tx));

    await this.invalidateCategoryCaches(categoryId, category.slug);
    return upserted;
  }

  async updateCategoryField(
    categoryId: string,
    fieldId: string,
    dto: UpdateCategoryFieldDto,
    actorId: string,
  ) {
    const field = await this.prisma.categoryField.findFirst({
      where: { id: fieldId, categoryId },
      include: { category: { select: { slug: true } } },
    });
    if (!field) {
      throw new NotFoundException('Category field not found');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.categoryField.update({
        where: { id: fieldId },
        data: {
          ...(dto.fieldType !== undefined ? { fieldType: dto.fieldType } : {}),
          ...(dto.labelAr !== undefined ? { labelAr: dto.labelAr } : {}),
          ...(dto.labelEn !== undefined ? { labelEn: dto.labelEn } : {}),
          ...(dto.isRequired !== undefined
            ? { isRequired: dto.isRequired }
            : {}),
          ...(dto.isFilterable !== undefined
            ? { isFilterable: dto.isFilterable }
            : {}),
          ...(dto.validationRules !== undefined
            ? { validationRules: dto.validationRules as any }
            : {}),
          ...(dto.sortOrder !== undefined ? { sortOrder: dto.sortOrder } : {}),
          ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
        },
      });
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'CATEGORY_FIELD_UPDATED',
          targetEntity: 'category_field',
          targetId: fieldId,
          diffPayload: { categoryId, fieldKey: next.fieldKey, ...dto } as any,
        },
      });
      return next;
    });

    await this.invalidateCategoryCaches(categoryId, field.category.slug);
    return updated;
  }

  async deactivateCategoryField(
    categoryId: string,
    fieldId: string,
    actorId: string,
  ) {
    const field = await this.prisma.categoryField.findFirst({
      where: { id: fieldId, categoryId },
      include: { category: { select: { slug: true } } },
    });
    if (!field) {
      throw new NotFoundException('Category field not found');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.categoryField.update({
        where: { id: fieldId },
        data: { isActive: false },
      });
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'CATEGORY_FIELD_DEACTIVATED',
          targetEntity: 'category_field',
          targetId: fieldId,
          diffPayload: { categoryId, fieldKey: field.fieldKey },
        },
      });
      return next;
    });

    await this.invalidateCategoryCaches(categoryId, field.category.slug);
    return updated;
  }

  private async invalidateCategoryCaches(
    id?: string,
    ...slugs: Array<string | undefined>
  ) {
    const keys = ['categories:tree'];
    if (id) {
      keys.push(`categories:item:${id}`, `categories:fields:${id}`);
    }
    for (const s of slugs) {
      if (s) {
        keys.push(`categories:item:${s}`, `categories:fields:${s}`);
      }
    }
    await Promise.all([
      ...keys.map((k) => this.redis?.del(k).catch(() => undefined)),
      this.redis?.incr?.('home:feed:ver').catch(() => undefined),
    ]);
  }
}
