import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';
import { UserRole } from '../../core/enums/domain.enums';
import {
  assertValidQuotationTransition,
  assertValidRfqTransition,
} from './rfq-state-machine';
import { ACTIVE_RFQ_STATUSES, QuotationStatus, RfqStatus } from './rfq.enums';
import { CreateQuotationDto } from './dto/create-quotation.dto';
import { CreateRfqDto } from './dto/create-rfq.dto';
import { UpdateRfqDto } from './dto/update-rfq.dto';
import { GetRfqsQueryDto } from './dto/get-rfqs-query.dto';
import { UpdateQuotationStatusDto } from './dto/update-quotation-status.dto';

@Injectable()
export class RfqService {
  constructor(private readonly prisma: PrismaService) {}

  private generateReference(): string {
    const datePart = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const randPart = crypto.randomBytes(3).toString('hex').toUpperCase();
    return `RFQ-${datePart}-${randPart}`;
  }

  private async resolveAuthorizedSupplierAccount(
    userId: string,
    requestedAccountId?: string,
  ) {
    if (requestedAccountId) {
      const account = await this.prisma.account.findUnique({
        where: { id: requestedAccountId },
        select: {
          id: true,
          ownerUserId: true,
          isActive: true,
          deletedAt: true,
          members: {
            where: {
              userId,
              role: { in: ['owner', 'manager', 'responder'] },
            },
            select: { id: true },
          },
        },
      });

      if (!account || !account.isActive || account.deletedAt) {
        throw new NotFoundException('Supplier account not found or inactive');
      }

      if (account.ownerUserId !== userId && account.members.length === 0) {
        throw new ForbiddenException(
          'You are not authorized to submit quotations on behalf of this supplier account',
        );
      }

      return account;
    }

    const account = await this.prisma.account.findFirst({
      where: {
        isActive: true,
        deletedAt: null,
        OR: [
          { ownerUserId: userId },
          {
            members: {
              some: {
                userId,
                role: { in: ['owner', 'manager', 'responder'] },
              },
            },
          },
        ],
      },
      orderBy: { createdAt: 'asc' },
      select: { id: true, ownerUserId: true },
    });

    if (!account) {
      throw new ForbiddenException(
        'An active seller/supplier account is required to submit a quotation',
      );
    }

    return account;
  }

  private isAdminActor(
    userRole?: string,
    actorType?: 'user' | 'staff',
  ): boolean {
    const normalized = (userRole || '').toUpperCase();
    const hasAdminRole =
      normalized === UserRole.SUPER_ADMIN ||
      normalized === UserRole.MODERATOR ||
      normalized === 'ADMIN';
    if (!hasAdminRole) return false;
    if (actorType === 'staff') return true;
    return process.env.NODE_ENV !== 'production';
  }

  private async isSupplierAccountMember(
    accountId: string,
    userId: string,
    allowedRoles?: string[],
    actorType?: 'user' | 'staff',
  ): Promise<boolean> {
    if (actorType === 'staff') return false;
    const account = await this.prisma.account.findUnique({
      where: { id: accountId },
      select: {
        ownerUserId: true,
        members: {
          where: {
            userId,
            ...(allowedRoles ? { role: { in: allowedRoles } } : {}),
          },
          select: { id: true },
        },
      },
    });
    if (!account) return false;
    return account.ownerUserId === userId || account.members.length > 0;
  }

  async createRfq(userId: string, dto: CreateRfqDto) {
    if (dto.categoryId) {
      const category = await this.prisma.category.findUnique({
        where: { id: dto.categoryId },
        select: { id: true, isActive: true },
      });
      if (!category || !category.isActive) {
        throw new BadRequestException(
          'Selected category is invalid or inactive',
        );
      }
    }

    let requiredByDateObj: Date | null = null;
    if (dto.requiredByDate) {
      requiredByDateObj = new Date(`${dto.requiredByDate}T00:00:00Z`);
      if (Number.isNaN(requiredByDateObj.getTime())) {
        throw new BadRequestException('Invalid requiredByDate');
      }
      const todayUtc = new Date();
      todayUtc.setUTCHours(0, 0, 0, 0);
      if (requiredByDateObj < todayUtc) {
        throw new BadRequestException('requiredByDate cannot be in the past');
      }
    }

    // Validate linked listing IDs if provided
    const linkedListingIds = dto.items
      .map((i) => i.listingId)
      .filter((id): id is string => Boolean(id));

    if (linkedListingIds.length > 0) {
      const foundListings = await this.prisma.listing.findMany({
        where: {
          id: { in: linkedListingIds },
          deletedAt: null,
        },
        select: { id: true },
      });
      const foundSet = new Set(foundListings.map((l) => l.id));
      const missing = linkedListingIds.find((id) => !foundSet.has(id));
      if (missing) {
        throw new BadRequestException(
          `Referenced material listing '${missing}' does not exist or was deleted`,
        );
      }
    }

    const status = dto.isDraft ? RfqStatus.DRAFT : RfqStatus.SUBMITTED;
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    return this.prisma.$transaction(async (tx) => {
      const rfq = await tx.rfqRequest.create({
        data: {
          reference: this.generateReference(),
          userId,
          categoryId: dto.categoryId ?? null,
          title: dto.title.trim(),
          description: dto.description.trim(),
          deliveryLocation: dto.deliveryLocation.trim(),
          requiredByDate: requiredByDateObj,
          supportingImages: dto.supportingImages ?? [],
          additionalNotes: dto.additionalNotes?.trim() || null,
          status,
          expiresAt,
          items: {
            create: dto.items.map((item, idx) => ({
              listingId: item.listingId ?? null,
              name: item.name.trim(),
              specification: item.specification?.trim() || null,
              quantity: item.quantity,
              unit: item.unit.trim(),
              sortOrder: idx,
            })),
          },
        },
        include: {
          category: {
            select: { id: true, slug: true, nameAr: true, nameEn: true },
          },
          items: { orderBy: { sortOrder: 'asc' } },
        },
      });

      if (status === RfqStatus.SUBMITTED) {
        await tx.outboxEvent.create({
          data: {
            aggregateType: 'RfqRequest',
            aggregateId: rfq.id,
            eventType: 'PUSH_NOTIFICATION',
            payload: {
              targetUserId: userId,
              title: 'RFQ Submitted',
              body: `Your quotation request ${rfq.reference} has been submitted.`,
              dataPayload: {
                type: 'RFQ_SUBMITTED',
                rfqId: rfq.id,
                reference: rfq.reference,
              },
            },
          },
        });
      }

      return rfq;
    });
  }

  async getRfqs(userId: string, query: GetRfqsQueryDto = {}) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;
    const scope = query.scope ?? 'mine';

    const categoryWhere: Prisma.RfqRequestWhereInput = query.categoryId
      ? {
          OR: [
            { categoryId: query.categoryId },
            { category: { parentId: query.categoryId } },
          ],
        }
      : query.categorySlug
        ? {
            OR: [
              { category: { slug: query.categorySlug } },
              { category: { parent: { slug: query.categorySlug } } },
            ],
          }
        : {};

    const openSupplierStatuses: RfqStatus[] = [
      RfqStatus.SUBMITTED,
      RfqStatus.UNDER_REVIEW,
      RfqStatus.QUOTATIONS_RECEIVED,
    ];

    if (
      scope === 'open_for_suppliers' &&
      query.status &&
      !openSupplierStatuses.includes(query.status)
    ) {
      throw new BadRequestException(
        `Status '${query.status}' is not allowed when scope is 'open_for_suppliers'`,
      );
    }

    const where: Prisma.RfqRequestWhereInput =
      scope === 'open_for_suppliers'
        ? {
            userId: { not: userId },
            status: query.status
              ? query.status
              : { in: openSupplierStatuses },
            ...categoryWhere,
          }
        : {
            userId,
            ...(query.status ? { status: query.status } : {}),
            ...categoryWhere,
          };

    const [total, items] = await Promise.all([
      this.prisma.rfqRequest.count({ where }),
      this.prisma.rfqRequest.findMany({
        where,
        include: {
          category: {
            select: { id: true, slug: true, nameAr: true, nameEn: true },
          },
          items: { orderBy: { sortOrder: 'asc' } },
          _count: { select: { quotations: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
    ]);

    return {
      data: items.map((r) => ({
        ...r,
        quotationsCount: r._count.quotations,
      })),
      meta: {
        total,
        page,
        limit,
        totalPages: total === 0 ? 0 : Math.ceil(total / limit),
      },
    };
  }

  async getActiveRfqCount(userId: string): Promise<number> {
    return this.prisma.rfqRequest.count({
      where: {
        userId,
        status: { in: ACTIVE_RFQ_STATUSES },
      },
    });
  }

  async getRfqById(
    rfqId: string,
    userId: string,
    userRole?: string,
    actorType?: 'user' | 'staff',
  ) {
    const rfq = await this.prisma.rfqRequest.findUnique({
      where: { id: rfqId },
      include: {
        category: {
          select: { id: true, slug: true, nameAr: true, nameEn: true },
        },
        items: { orderBy: { sortOrder: 'asc' } },
        _count: { select: { quotations: true } },
      },
    });

    if (!rfq) {
      throw new NotFoundException('RFQ not found');
    }

    const isOwner = actorType !== 'staff' && rfq.userId === userId;
    const isAdmin = this.isAdminActor(userRole, actorType);
    const isOpenToSuppliers = [
      RfqStatus.SUBMITTED,
      RfqStatus.UNDER_REVIEW,
      RfqStatus.QUOTATIONS_RECEIVED,
    ].includes(rfq.status as RfqStatus);

    if (!isOwner && !isAdmin && !isOpenToSuppliers) {
      throw new ForbiddenException('You do not have access to this RFQ');
    }

    return {
      ...rfq,
      quotationsCount: rfq._count.quotations,
    };
  }

  async updateDraftRfq(rfqId: string, userId: string, dto: UpdateRfqDto) {
    if (dto.categoryId) {
      const category = await this.prisma.category.findUnique({
        where: { id: dto.categoryId },
        select: { id: true, isActive: true },
      });
      if (!category || !category.isActive) {
        throw new BadRequestException(
          'Selected category is invalid or inactive',
        );
      }
    }

    let requiredByDateObj: Date | undefined;
    if (dto.requiredByDate !== undefined) {
      requiredByDateObj = new Date(`${dto.requiredByDate}T00:00:00Z`);
      if (Number.isNaN(requiredByDateObj.getTime())) {
        throw new BadRequestException('Invalid requiredByDate');
      }
      const todayUtc = new Date();
      todayUtc.setUTCHours(0, 0, 0, 0);
      if (requiredByDateObj < todayUtc) {
        throw new BadRequestException('requiredByDate cannot be in the past');
      }
    }

    if (dto.items) {
      const linkedListingIds = dto.items
        .map((i) => i.listingId)
        .filter((id): id is string => Boolean(id));
      if (linkedListingIds.length > 0) {
        const foundListings = await this.prisma.listing.findMany({
          where: { id: { in: linkedListingIds }, deletedAt: null },
          select: { id: true },
        });
        const foundSet = new Set(foundListings.map((l) => l.id));
        const missing = linkedListingIds.find((id) => !foundSet.has(id));
        if (missing) {
          throw new BadRequestException(
            `Referenced material listing '${missing}' does not exist or was deleted`,
          );
        }
      }
    }

    return this.prisma.$transaction(async (tx) => {
      const rfq = await tx.rfqRequest.findUnique({ where: { id: rfqId } });
      if (!rfq) {
        throw new NotFoundException('RFQ not found');
      }
      if (rfq.userId !== userId) {
        throw new ForbiddenException('Only the RFQ owner can edit a draft RFQ');
      }
      if (rfq.status !== RfqStatus.DRAFT) {
        throw new BadRequestException('Only DRAFT RFQs can be edited');
      }

      return tx.rfqRequest.update({
        where: { id: rfq.id },
        data: {
          ...(dto.title !== undefined ? { title: dto.title.trim() } : {}),
          ...(dto.description !== undefined
            ? { description: dto.description.trim() }
            : {}),
          ...(dto.categoryId !== undefined
            ? { categoryId: dto.categoryId }
            : {}),
          ...(dto.deliveryLocation !== undefined
            ? { deliveryLocation: dto.deliveryLocation.trim() }
            : {}),
          ...(requiredByDateObj !== undefined
            ? { requiredByDate: requiredByDateObj }
            : {}),
          ...(dto.supportingImages !== undefined
            ? { supportingImages: dto.supportingImages }
            : {}),
          ...(dto.additionalNotes !== undefined
            ? { additionalNotes: dto.additionalNotes.trim() || null }
            : {}),
          ...(dto.items
            ? {
                items: {
                  deleteMany: {},
                  create: dto.items.map((item, idx) => ({
                    listingId: item.listingId ?? null,
                    name: item.name.trim(),
                    specification: item.specification?.trim() || null,
                    quantity: item.quantity,
                    unit: item.unit.trim(),
                    sortOrder: idx,
                  })),
                },
              }
            : {}),
        },
        include: {
          category: {
            select: { id: true, slug: true, nameAr: true, nameEn: true },
          },
          items: { orderBy: { sortOrder: 'asc' } },
        },
      });
    });
  }

  async submitDraftRfq(rfqId: string, userId: string) {
    try {
      return await this.prisma.$transaction(
        async (tx) => {
          const rfq = await tx.rfqRequest.findUnique({
            where: { id: rfqId },
            include: { items: true },
          });

          if (!rfq) {
            throw new NotFoundException('RFQ not found');
          }
          if (rfq.userId !== userId) {
            throw new ForbiddenException(
              'Only the RFQ owner can submit this RFQ',
            );
          }

          assertValidRfqTransition(rfq.status, RfqStatus.SUBMITTED);

          if (!rfq.items || rfq.items.length === 0) {
            throw new BadRequestException(
              'RFQ must contain at least one item before submission',
            );
          }

          const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
          const updated = await tx.rfqRequest.update({
            where: { id: rfq.id },
            data: {
              status: RfqStatus.SUBMITTED,
              expiresAt,
            },
            include: {
              category: {
                select: { id: true, slug: true, nameAr: true, nameEn: true },
              },
              items: { orderBy: { sortOrder: 'asc' } },
            },
          });

          await tx.outboxEvent.create({
            data: {
              aggregateType: 'RfqRequest',
              aggregateId: updated.id,
              eventType: 'PUSH_NOTIFICATION',
              payload: {
                targetUserId: userId,
                title: 'RFQ Submitted',
                body: `Your quotation request ${updated.reference} has been submitted.`,
                dataPayload: {
                  type: 'RFQ_SUBMITTED',
                  rfqId: updated.id,
                  reference: updated.reference,
                },
              },
            },
          });

          return updated;
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        },
      );
    } catch (err: any) {
      if (err?.code === 'P2034') {
        throw new ConflictException(
          'Concurrent RFQ update detected. Please retry.',
        );
      }
      throw err;
    }
  }

  async cancelRfq(
    rfqId: string,
    userId: string,
    reason?: string,
    userRole?: string,
    actorType?: 'user' | 'staff',
  ) {
    try {
      return await this.prisma.$transaction(
        async (tx) => {
          const rfq = await tx.rfqRequest.findUnique({
            where: { id: rfqId },
            include: {
              quotations: {
                where: {
                  status: {
                    in: [
                      QuotationStatus.SUBMITTED,
                      QuotationStatus.SHORTLISTED,
                    ],
                  },
                },
                select: {
                  id: true,
                  supplierAccount: { select: { ownerUserId: true } },
                },
              },
            },
          });

          if (!rfq) {
            throw new NotFoundException('RFQ not found');
          }

          const isOwner = actorType !== 'staff' && rfq.userId === userId;
          const isAdmin = this.isAdminActor(userRole, actorType);

          if (!isOwner && !isAdmin) {
            throw new ForbiddenException('Only the RFQ owner can cancel it');
          }

          assertValidRfqTransition(rfq.status, RfqStatus.CANCELLED);

          const updated = await tx.rfqRequest.update({
            where: { id: rfq.id },
            data: {
              status: RfqStatus.CANCELLED,
              cancellationReason: reason?.trim() || null,
            },
            include: {
              items: { orderBy: { sortOrder: 'asc' } },
            },
          });

          const supplierOwnerIds = Array.from(
            new Set(
              (rfq.quotations ?? [])
                .map((q) => q.supplierAccount?.ownerUserId)
                .filter((id): id is string => Boolean(id)),
            ),
          );

          for (const supplierOwnerId of supplierOwnerIds) {
            await tx.outboxEvent.create({
              data: {
                aggregateType: 'RfqRequest',
                aggregateId: rfq.id,
                eventType: 'PUSH_NOTIFICATION',
                payload: {
                  targetUserId: supplierOwnerId,
                  title: 'RFQ Cancelled',
                  body: `RFQ ${rfq.reference} has been cancelled by the requester.`,
                  dataPayload: {
                    type: 'RFQ_CANCELLED',
                    rfqId: rfq.id,
                    reference: rfq.reference,
                  },
                },
              },
            });
          }

          return updated;
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        },
      );
    } catch (err: any) {
      if (err?.code === 'P2034') {
        throw new ConflictException(
          'Concurrent RFQ update detected. Please retry.',
        );
      }
      throw err;
    }
  }

  async submitQuotation(
    rfqId: string,
    userId: string,
    dto: CreateQuotationDto,
  ) {
    const rfq = await this.prisma.rfqRequest.findUnique({
      where: { id: rfqId },
      include: { items: true },
    });

    if (!rfq) {
      throw new NotFoundException('RFQ not found');
    }

    if (rfq.userId === userId) {
      throw new BadRequestException(
        'You cannot submit a quotation for your own RFQ',
      );
    }

    if (
      ![
        RfqStatus.SUBMITTED,
        RfqStatus.UNDER_REVIEW,
        RfqStatus.QUOTATIONS_RECEIVED,
      ].includes(rfq.status as RfqStatus)
    ) {
      throw new BadRequestException(
        `RFQ is in status '${rfq.status}' and is not accepting quotations`,
      );
    }

    if (rfq.expiresAt && new Date(rfq.expiresAt).getTime() <= Date.now()) {
      throw new BadRequestException(
        'RFQ has expired and is no longer accepting quotations',
      );
    }

    const supplierAccount = await this.resolveAuthorizedSupplierAccount(
      userId,
      dto.supplierAccountId,
    );

    const rfqItemIds = new Set(rfq.items.map((i) => i.id));
    for (const item of dto.items) {
      if (item.rfqItemId && !rfqItemIds.has(item.rfqItemId)) {
        throw new BadRequestException(
          `rfqItemId '${item.rfqItemId}' does not belong to this RFQ`,
        );
      }
    }

    // Authoritative server-side pricing calculation with DECIMAL(14,2) overflow guard
    const MAX_DECIMAL_14_2 = 999999999999.99;
    const computedItems = dto.items.map((item) => {
      const lineTotal = Number((item.quantity * item.unitPrice).toFixed(2));
      if (!Number.isFinite(lineTotal) || lineTotal > MAX_DECIMAL_14_2) {
        throw new BadRequestException(
          `Line total for item '${item.name}' exceeds maximum supported amount`,
        );
      }
      return {
        rfqItemId: item.rfqItemId ?? null,
        name: item.name.trim(),
        quantity: item.quantity,
        unit: item.unit.trim(),
        unitPrice: item.unitPrice,
        lineTotal,
        notes: item.notes?.trim() || null,
      };
    });

    const subtotalAmount = Number(
      computedItems.reduce((sum, i) => sum + i.lineTotal, 0).toFixed(2),
    );
    const deliveryFee = Number((dto.deliveryFee ?? 0).toFixed(2));
    const totalAmount = Number((subtotalAmount + deliveryFee).toFixed(2));
    if (
      !Number.isFinite(subtotalAmount) ||
      !Number.isFinite(totalAmount) ||
      subtotalAmount > MAX_DECIMAL_14_2 ||
      totalAmount > MAX_DECIMAL_14_2
    ) {
      throw new BadRequestException(
        'Quotation total exceeds maximum supported amount',
      );
    }
    const validUntil = new Date(
      Date.now() + (dto.validityDays ?? 14) * 24 * 60 * 60 * 1000,
    );

    try {
      return await this.prisma.$transaction(async (tx) => {
        const existing = await tx.quotation.findUnique({
          where: {
            uq_rfq_supplier_quotation: {
              rfqId: rfq.id,
              supplierAccountId: supplierAccount.id,
            },
          },
          select: { id: true },
        });

        if (existing) {
          throw new ConflictException(
            'Your supplier account has already submitted a quotation for this RFQ',
          );
        }

        const quotation = await tx.quotation.create({
          data: {
            rfqId: rfq.id,
            supplierAccountId: supplierAccount.id,
            submittedByUserId: userId,
            subtotalAmount,
            deliveryFee,
            totalAmount,
            currency: 'EGP',
            estimatedDeliveryDays: dto.estimatedDeliveryDays,
            validUntil,
            notes: dto.notes?.trim() || null,
            status: QuotationStatus.SUBMITTED,
            items: {
              create: computedItems,
            },
          },
          include: {
            supplierAccount: {
              select: {
                id: true,
                displayName: true,
                accountType: true,
                verificationStatus: true,
                logoUrl: true,
              },
            },
            items: true,
          },
        });

        if (
          rfq.status === RfqStatus.SUBMITTED ||
          rfq.status === RfqStatus.UNDER_REVIEW
        ) {
          await tx.rfqRequest.update({
            where: { id: rfq.id },
            data: { status: RfqStatus.QUOTATIONS_RECEIVED },
          });
        }

        await tx.outboxEvent.create({
          data: {
            aggregateType: 'Quotation',
            aggregateId: quotation.id,
            eventType: 'PUSH_NOTIFICATION',
            payload: {
              targetUserId: rfq.userId,
              title: 'New Quotation Received',
              body: `You received a quotation of ${totalAmount} EGP for ${rfq.reference}.`,
              dataPayload: {
                type: 'QUOTATION_RECEIVED',
                rfqId: rfq.id,
                quotationId: quotation.id,
              },
            },
          },
        });

        return quotation;
      });
    } catch (err: any) {
      if (err?.code === 'P2002') {
        throw new ConflictException(
          'Your supplier account has already submitted a quotation for this RFQ',
        );
      }
      throw err;
    }
  }

  async getQuotationsForRfq(
    rfqId: string,
    userId: string,
    sortBy:
      'totalAmount' | 'estimatedDeliveryDays' | 'createdAt' = 'totalAmount',
    userRole?: string,
    actorType?: 'user' | 'staff',
  ) {
    const rfq = await this.prisma.rfqRequest.findUnique({
      where: { id: rfqId },
      select: { id: true, userId: true },
    });

    if (!rfq) {
      throw new NotFoundException('RFQ not found');
    }

    const isOwner = actorType !== 'staff' && rfq.userId === userId;
    const isAdmin = this.isAdminActor(userRole, actorType);

    if (!isOwner && !isAdmin) {
      throw new ForbiddenException(
        'Only the RFQ owner can view and compare all quotations',
      );
    }

    const orderBy: Prisma.QuotationOrderByWithRelationInput =
      sortBy === 'estimatedDeliveryDays'
        ? { estimatedDeliveryDays: 'asc' }
        : sortBy === 'createdAt'
          ? { createdAt: 'desc' }
          : { totalAmount: 'asc' };

    return this.prisma.quotation.findMany({
      where: { rfqId },
      include: {
        supplierAccount: {
          select: {
            id: true,
            displayName: true,
            accountType: true,
            verificationStatus: true,
            logoUrl: true,
          },
        },
        items: true,
      },
      orderBy,
    });
  }

  async getQuotationById(
    quotationId: string,
    userId: string,
    userRole?: string,
    actorType?: 'user' | 'staff',
  ) {
    const quotation = await this.prisma.quotation.findUnique({
      where: { id: quotationId },
      include: {
        rfq: {
          select: { id: true, reference: true, title: true, userId: true },
        },
        supplierAccount: {
          select: {
            id: true,
            displayName: true,
            accountType: true,
            verificationStatus: true,
            logoUrl: true,
          },
        },
        items: true,
      },
    });

    if (!quotation) {
      throw new NotFoundException('Quotation not found');
    }

    const isRfqOwner =
      actorType !== 'staff' && quotation.rfq.userId === userId;
    const isAdmin = this.isAdminActor(userRole, actorType);
    const isSupplier = await this.isSupplierAccountMember(
      quotation.supplierAccountId,
      userId,
      undefined,
      actorType,
    );

    if (!isRfqOwner && !isSupplier && !isAdmin) {
      throw new ForbiddenException(
        'You do not have permission to access this quotation',
      );
    }

    return quotation;
  }

  async updateQuotationStatus(
    quotationId: string,
    userId: string,
    dto: UpdateQuotationStatusDto,
    userRole?: string,
    actorType?: 'user' | 'staff',
  ) {
    try {
      return await this.prisma.$transaction(
        async (tx) => {
          const quotation = await tx.quotation.findUnique({
            where: { id: quotationId },
            include: {
              rfq: true,
              supplierAccount: { select: { ownerUserId: true } },
            },
          });

          if (!quotation) {
            throw new NotFoundException('Quotation not found');
          }

          const isRfqOwner =
            actorType !== 'staff' && quotation.rfq.userId === userId;
          const isAdmin = this.isAdminActor(userRole, actorType);
          const isSupplierAuthorized = await this.isSupplierAccountMember(
            quotation.supplierAccountId,
            userId,
            ['owner', 'manager', 'responder'],
            actorType,
          );

          if (dto.status === QuotationStatus.WITHDRAWN) {
            if (!isSupplierAuthorized) {
              throw new ForbiddenException(
                'Only an authorized submitting supplier member can withdraw a quotation',
              );
            }
          } else {
            if (!isRfqOwner && !isAdmin) {
              throw new ForbiddenException(
                'Only the RFQ owner or an administrator can shortlist, accept, or reject a quotation',
              );
            }
          }

          assertValidQuotationTransition(quotation.status, dto.status);

          if (
            dto.status === QuotationStatus.ACCEPTED ||
            dto.status === QuotationStatus.SHORTLISTED
          ) {
            if (
              quotation.validUntil &&
              new Date(quotation.validUntil).getTime() <= Date.now()
            ) {
              throw new BadRequestException(
                'Quotation has expired and can no longer be shortlisted or accepted',
              );
            }
            if (
              quotation.rfq.expiresAt &&
              new Date(quotation.rfq.expiresAt).getTime() <= Date.now()
            ) {
              throw new BadRequestException(
                'RFQ has expired and can no longer accept quotations',
              );
            }
          }

          if (dto.status === QuotationStatus.ACCEPTED) {
            assertValidRfqTransition(quotation.rfq.status, RfqStatus.ACCEPTED);

            const alreadyAccepted = await tx.quotation.findFirst({
              where: {
                rfqId: quotation.rfqId,
                status: QuotationStatus.ACCEPTED,
              },
              select: { id: true },
            });
            if (alreadyAccepted) {
              throw new ConflictException(
                'Another quotation has already been accepted for this RFQ',
              );
            }
          }

          const notifyTargetUserId =
            dto.status === QuotationStatus.WITHDRAWN
              ? quotation.rfq.userId
              : quotation.supplierAccount.ownerUserId;

          const updated = await tx.quotation.update({
            where: { id: quotation.id },
            data: {
              status: dto.status,
              ...(dto.reason !== undefined
                ? { statusReason: dto.reason.trim() || null }
                : {}),
            },
            include: { items: true },
          });

          if (dto.status === QuotationStatus.ACCEPTED) {
            await tx.rfqRequest.update({
              where: { id: quotation.rfqId },
              data: {
                status: RfqStatus.ACCEPTED,
                acceptedQuotationId: quotation.id,
              },
            });
          }

          await tx.outboxEvent.create({
            data: {
              aggregateType: 'Quotation',
              aggregateId: quotation.id,
              eventType: 'PUSH_NOTIFICATION',
              payload: {
                targetUserId: notifyTargetUserId,
                title: `Quotation ${dto.status}`,
                body: `Quotation for ${quotation.rfq.reference} is now ${dto.status.toLowerCase()}.`,
                dataPayload: {
                  type: 'QUOTATION_STATUS_CHANGED',
                  rfqId: quotation.rfqId,
                  quotationId: quotation.id,
                  status: dto.status,
                },
              },
            },
          });

          return updated;
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        },
      );
    } catch (err: any) {
      if (err?.code === 'P2034' || err?.code === 'P2002') {
        throw new ConflictException(
          'Concurrent quotation update detected. Please retry.',
        );
      }
      throw err;
    }
  }
}
