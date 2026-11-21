import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import * as argon2 from 'argon2';
import * as crypto from 'crypto';
import { PrismaService } from '../../core/database/prisma.service';
import {
  ADMIN_PERMISSION_CATALOG,
  ADMIN_PERMISSION_SET,
} from '../admin-auth/constants/admin-permissions.constant';
import { StaffSessionService } from '../admin-auth/services/staff-session.service';
import { CreateStaffRoleDto } from './dto/create-staff-role.dto';
import { CreateStaffUserDto } from './dto/create-staff-user.dto';
import { UpdateStaffUserDto } from './dto/update-staff-user.dto';
import {
  CloneStaffRoleDto,
  InviteStaffUserDto,
  StaffListQueryDto,
  UpdateStaffRoleDto,
} from './dto/staff-admin.dto';

const SAFE_STAFF_SELECT = {
  id: true,
  email: true,
  fullName: true,
  phone: true,
  department: true,
  jobTitle: true,
  roleId: true,
  status: true,
  isActive: true,
  mfaEnabled: true,
  lastLoginAt: true,
  expiresAt: true,
  createdAt: true,
  updatedAt: true,
  role: {
    select: {
      id: true,
      name: true,
      description: true,
      isSystem: true,
      permissions: true,
    },
  },
};

const CRITICAL_SUPER_ADMIN_PERMISSIONS = [
  'admins.read',
  'admins.create',
  'admins.update',
  'roles.read',
  'roles.create',
  'roles.update',
  'roles.delete',
  'audit_logs.read',
  'settings.read',
  'settings.update',
];

@Injectable()
export class StaffService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly staffSessionService?: StaffSessionService,
  ) {}

  getPermissionCatalog() {
    return {
      permissions: ADMIN_PERMISSION_CATALOG,
      total: ADMIN_PERMISSION_CATALOG.length,
    };
  }

  async listRoles() {
    return this.prisma.staffRole.findMany({
      orderBy: { id: 'asc' },
      include: {
        _count: {
          select: { staffUsers: true },
        },
      },
    });
  }

  async createRole(
    dto: CreateStaffRoleDto,
    actorId: string,
    actorContext?: { role?: string; permissions?: string[] },
  ) {
    const normalizedName = dto.name.trim().toLowerCase();
    const existing = await this.prisma.staffRole.findUnique({
      where: { name: normalizedName },
    });
    if (existing) {
      throw new ConflictException(
        `Staff role '${normalizedName}' already exists`,
      );
    }

    const permissions = this.validateAndCheckEscalation(
      dto.permissions ?? [],
      actorContext,
    );

    return this.prisma.$transaction(async (tx) => {
      const role = await tx.staffRole.create({
        data: {
          name: normalizedName,
          description: dto.description?.trim() || null,
          isSystem: false,
          permissions,
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'STAFF_ROLE_CREATED',
          targetEntity: 'staff_role',
          diffPayload: {
            roleId: role.id,
            name: role.name,
            permissionsCount: permissions.length,
          },
        },
      });

      return role;
    });
  }

  async updateRole(
    roleId: number,
    dto: UpdateStaffRoleDto,
    actorId: string,
    actorContext?: { role?: string; permissions?: string[] },
  ) {
    const existing = await this.prisma.staffRole.findUnique({
      where: { id: roleId },
    });
    if (!existing) {
      throw new NotFoundException('Staff role not found');
    }

    let nextPermissions: string[] | undefined;
    if (dto.permissions !== undefined) {
      nextPermissions = this.validateAndCheckEscalation(
        dto.permissions,
        actorContext,
      );

      if (existing.name === 'super_admin') {
        const missingCritical = CRITICAL_SUPER_ADMIN_PERMISSIONS.filter(
          (p) => !nextPermissions!.includes(p),
        );
        if (missingCritical.length > 0) {
          throw new ForbiddenException(
            `Cannot remove critical governance permissions from super_admin: ${missingCritical.join(', ')}`,
          );
        }
      }
    }

    if (
      dto.name !== undefined &&
      existing.isSystem &&
      dto.name.trim().toLowerCase() !== existing.name
    ) {
      throw new ForbiddenException('System role names cannot be renamed.');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const role = await tx.staffRole.update({
        where: { id: roleId },
        data: {
          ...(dto.name !== undefined
            ? { name: dto.name.trim().toLowerCase() }
            : {}),
          ...(dto.description !== undefined
            ? { description: dto.description.trim() || null }
            : {}),
          ...(nextPermissions !== undefined
            ? { permissions: nextPermissions }
            : {}),
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'STAFF_ROLE_UPDATED',
          targetEntity: 'staff_role',
          diffPayload: {
            roleId,
            name: role.name,
            previousPermissions: existing.permissions,
            newPermissions: role.permissions,
          },
        },
      });

      return role;
    });

    // Invalidate Redis auth cache for all staff assigned to this role
    const affected = await this.prisma.staffUser.findMany({
      where: { roleId },
      select: { id: true },
    });
    await Promise.all(
      affected.map((s) =>
        this.staffSessionService?.invalidateStaffAuthCache(s.id),
      ),
    );

    return updated;
  }

  async cloneRole(
    sourceRoleId: number,
    dto: CloneStaffRoleDto,
    actorId: string,
    actorContext?: { role?: string; permissions?: string[] },
  ) {
    const source = await this.prisma.staffRole.findUnique({
      where: { id: sourceRoleId },
    });
    if (!source) {
      throw new NotFoundException('Source role not found');
    }

    const perms = Array.isArray(source.permissions)
      ? (source.permissions as string[])
      : [];

    return this.createRole(
      {
        name: dto.name,
        description: dto.description ?? `Cloned from ${source.name}`,
        permissions: perms,
      },
      actorId,
      actorContext,
    );
  }

  async deleteRole(roleId: number, actorId: string) {
    const role = await this.prisma.staffRole.findUnique({
      where: { id: roleId },
      include: { _count: { select: { staffUsers: true } } },
    });
    if (!role) {
      throw new NotFoundException('Staff role not found');
    }
    if (role.isSystem) {
      throw new ForbiddenException('Built-in system roles cannot be deleted.');
    }
    if (role._count.staffUsers > 0) {
      throw new ConflictException(
        'Cannot delete a role that still has assigned staff accounts.',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.staffRole.delete({ where: { id: roleId } });
      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'STAFF_ROLE_DELETED',
          targetEntity: 'staff_role',
          diffPayload: { roleId, name: role.name },
        },
      });
    });

    return { success: true };
  }

  async listStaffUsers(query?: StaffListQueryDto) {
    const page = Math.max(Number(query?.page) || 1, 1);
    const limit = Math.min(Math.max(Number(query?.limit) || 20, 1), 100);
    const skip = (page - 1) * limit;

    const where: any = {
      deletedAt: null,
      ...(query?.roleId ? { roleId: Number(query.roleId) } : {}),
      ...(query?.status ? { status: query.status } : {}),
      ...(query?.isActive !== undefined ? { isActive: query.isActive } : {}),
      ...(query?.q
        ? {
            OR: [
              { fullName: { contains: query.q.trim(), mode: 'insensitive' } },
              { email: { contains: query.q.trim(), mode: 'insensitive' } },
              { department: { contains: query.q.trim(), mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [total, items] = await Promise.all([
      this.prisma.staffUser.count({ where }),
      this.prisma.staffUser.findMany({
        where,
        select: SAFE_STAFF_SELECT,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
    ]);

    return {
      items,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getStaffUserDetail(staffId: string) {
    const staff = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
      select: SAFE_STAFF_SELECT,
    });
    if (!staff) {
      throw new NotFoundException('Staff user not found');
    }

    const [activeSessions, recentAuditLogs, recentLoginAttempts] =
      await Promise.all([
        this.prisma.staffSession.findMany({
          where: {
            staffId,
            isRevoked: false,
            expiresAt: { gt: new Date() },
          },
          orderBy: { lastUsedAt: 'desc' },
          select: {
            id: true,
            ipAddress: true,
            userAgent: true,
            mfaVerified: true,
            createdAt: true,
            lastUsedAt: true,
            expiresAt: true,
          },
        }),
        this.prisma.auditLog.findMany({
          where: { actorType: 'staff', actorId: staffId },
          orderBy: { createdAt: 'desc' },
          take: 25,
        }),
        this.prisma.staffLoginAttempt.findMany({
          where: { staffId },
          orderBy: { createdAt: 'desc' },
          take: 15,
        }),
      ]);

    return {
      staff,
      activeSessions,
      recentAuditLogs,
      recentLoginAttempts,
    };
  }

  async createStaffUser(
    dto: CreateStaffUserDto,
    actorId: string,
    actorContext?: { role?: string; permissions?: string[] },
  ) {
    const normalizedEmail = dto.email.trim().toLowerCase();

    const [existingEmail, role] = await Promise.all([
      this.prisma.staffUser.findUnique({ where: { email: normalizedEmail } }),
      this.prisma.staffRole.findUnique({ where: { id: dto.roleId } }),
    ]);

    if (existingEmail) {
      throw new ConflictException(
        'A staff user with this email already exists',
      );
    }
    if (!role) {
      throw new NotFoundException('Staff role not found');
    }

    this.assertCanAssignRole(role, actorContext);

    const passwordHash = await argon2.hash(dto.password);

    return this.prisma.$transaction(async (tx) => {
      const staff = await tx.staffUser.create({
        data: {
          email: normalizedEmail,
          passwordHash,
          fullName: dto.fullName.trim(),
          roleId: dto.roleId,
          isActive: true,
        },
        select: SAFE_STAFF_SELECT,
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'STAFF_USER_CREATED',
          targetEntity: 'staff_user',
          targetId: staff.id,
          diffPayload: {
            email: staff.email,
            roleId: staff.roleId,
          },
        },
      });

      return staff;
    });
  }

  async inviteStaffUser(
    dto: InviteStaffUserDto,
    actorId: string,
    actorContext?: { role?: string; permissions?: string[] },
  ) {
    const normalizedEmail = dto.email.trim().toLowerCase();

    const [existingEmail, role] = await Promise.all([
      this.prisma.staffUser.findUnique({ where: { email: normalizedEmail } }),
      this.prisma.staffRole.findUnique({ where: { id: dto.roleId } }),
    ]);

    if (existingEmail) {
      throw new ConflictException(
        'A staff user with this email already exists',
      );
    }
    if (!role) {
      throw new NotFoundException('Staff role not found');
    }

    this.assertCanAssignRole(role, actorContext);

    const rawPassword =
      dto.password || `Inv!${crypto.randomBytes(12).toString('hex')}`;
    const passwordHash = await argon2.hash(rawPassword);

    const created = await this.prisma.$transaction(async (tx) => {
      const staff = await tx.staffUser.create({
        data: {
          email: normalizedEmail,
          passwordHash,
          fullName: dto.fullName.trim(),
          phone: dto.phone?.trim() || null,
          department: dto.department?.trim() || null,
          jobTitle: dto.jobTitle?.trim() || null,
          roleId: dto.roleId,
          status: dto.password ? 'active' : 'invited',
          isActive: true,
          expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null,
        },
        select: SAFE_STAFF_SELECT,
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'STAFF_USER_INVITED',
          targetEntity: 'staff_user',
          targetId: staff.id,
          diffPayload: {
            email: staff.email,
            roleId: staff.roleId,
            department: staff.department,
            status: staff.status,
          },
        },
      });

      return staff;
    });

    return {
      staff: created,
      invitationIssued: !dto.password,
    };
  }

  async updateStaffUser(
    staffId: string,
    dto: UpdateStaffUserDto,
    actorId: string,
    actorContext?: { role?: string; permissions?: string[] },
  ) {
    const existing = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
      include: { role: true },
    });

    if (!existing) {
      throw new NotFoundException('Staff user not found');
    }

    const isSelf = staffId === actorId;
    if (
      isSelf &&
      (dto.isActive === false ||
        (dto.status && dto.status !== 'active') ||
        (dto.roleId !== undefined && dto.roleId !== existing.roleId))
    ) {
      throw new ForbiddenException(
        'Administrators cannot deactivate, suspend, or change their own role.',
      );
    }

    let nextRole = existing.role;
    if (dto.roleId !== undefined && dto.roleId !== existing.roleId) {
      const role = await this.prisma.staffRole.findUnique({
        where: { id: dto.roleId },
      });
      if (!role) {
        throw new NotFoundException('Staff role not found');
      }
      this.assertCanAssignRole(role, actorContext);
      nextRole = role;
    }

    // Last Super Admin protection
    const isCurrentlySuperAdmin = existing.role?.name === 'super_admin';
    const nextIsActive =
      dto.isActive !== undefined
        ? dto.isActive
        : dto.status !== undefined
          ? dto.status === 'active'
          : existing.isActive;
    const nextStatus =
      dto.status !== undefined
        ? dto.status
        : dto.isActive !== undefined
          ? dto.isActive
            ? 'active'
            : 'disabled'
          : existing.status;

    const demotingOrDisablingSuperAdmin =
      isCurrentlySuperAdmin &&
      (!nextIsActive ||
        nextStatus !== 'active' ||
        (dto.roleId !== undefined && nextRole.name !== 'super_admin'));

    if (demotingOrDisablingSuperAdmin) {
      const otherActiveSuperAdmins = await this.prisma.staffUser.count({
        where: {
          id: { not: staffId },
          isActive: true,
          status: 'active',
          deletedAt: null,
          role: { name: 'super_admin' },
        },
      });
      if (otherActiveSuperAdmins === 0) {
        throw new ConflictException(
          'Cannot disable or demote the last active Super Admin account.',
        );
      }
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const next = await tx.staffUser.update({
        where: { id: staffId },
        data: {
          ...(dto.isActive !== undefined || dto.status !== undefined
            ? { isActive: nextIsActive, status: nextStatus }
            : {}),
          ...(dto.roleId !== undefined ? { roleId: dto.roleId } : {}),
          ...(dto.fullName !== undefined
            ? { fullName: dto.fullName.trim() }
            : {}),
          ...(dto.phone !== undefined ? { phone: dto.phone || null } : {}),
          ...(dto.department !== undefined
            ? { department: dto.department || null }
            : {}),
          ...(dto.jobTitle !== undefined
            ? { jobTitle: dto.jobTitle || null }
            : {}),
          ...(dto.expiresAt !== undefined
            ? { expiresAt: dto.expiresAt ? new Date(dto.expiresAt) : null }
            : {}),
        },
        select: SAFE_STAFF_SELECT,
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'STAFF_USER_UPDATED',
          targetEntity: 'staff_user',
          targetId: staffId,
          diffPayload: {
            previousIsActive: existing.isActive,
            newIsActive: next.isActive,
            previousStatus: existing.status,
            newStatus: next.status,
            previousRoleId: existing.roleId,
            newRoleId: next.roleId,
          },
        },
      });

      return next;
    });

    if (!updated.isActive || updated.status !== 'active') {
      await this.staffSessionService?.revokeAllStaffSessions(staffId, actorId);
    } else {
      await this.staffSessionService?.invalidateStaffAuthCache(staffId);
    }

    return updated;
  }

  async revokeStaffSessions(staffId: string, actorId: string) {
    const existing = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
      select: { id: true },
    });
    if (!existing) {
      throw new NotFoundException('Staff user not found');
    }

    const revokedCount =
      (await this.staffSessionService?.revokeAllStaffSessions(
        staffId,
        actorId,
      )) ?? 0;

    return { success: true, revokedCount };
  }

  async resetStaffMfa(staffId: string, actorId: string) {
    const existing = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
      select: { id: true, mfaEnabled: true },
    });
    if (!existing) {
      throw new NotFoundException('Staff user not found');
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.staffUser.update({
        where: { id: staffId },
        data: {
          mfaEnabled: false,
          mfaSecretEncrypted: null,
          mfaRecoveryCodesHash: [],
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'STAFF_MFA_RESET',
          targetEntity: 'staff_user',
          targetId: staffId,
          diffPayload: { previousMfaEnabled: existing.mfaEnabled },
        },
      });
    });

    await this.staffSessionService?.revokeAllStaffSessions(staffId, actorId);
    return { success: true };
  }

  private validateAndCheckEscalation(
    rawPermissions: string[],
    actorContext?: { role?: string; permissions?: string[] },
  ): string[] {
    const unique = Array.from(
      new Set(rawPermissions.map((p) => p.trim()).filter(Boolean)),
    );

    if (actorContext) {
      const invalid = unique.filter(
        (p) => !ADMIN_PERMISSION_SET.has(p) && !/^[a-z_]+:[a-z_]+$/i.test(p),
      );
      if (invalid.length > 0) {
        throw new BadRequestException(
          `Unknown permission key(s): ${invalid.join(', ')}`,
        );
      }

      if (
        actorContext.role !== 'super_admin' &&
        actorContext.role !== 'SUPER_ADMIN'
      ) {
        const held = new Set(actorContext.permissions ?? []);
        const missing = unique.filter((p) => !held.has(p));
        if (missing.length > 0) {
          throw new ForbiddenException(
            `Privilege escalation blocked. You cannot grant permissions you do not possess: ${missing.join(', ')}`,
          );
        }
      }
    }

    return unique;
  }

  private assertCanAssignRole(
    role: { name: string; permissions: unknown },
    actorContext?: { role?: string; permissions?: string[] },
  ) {
    if (!actorContext) return;
    if (
      actorContext.role === 'super_admin' ||
      actorContext.role === 'SUPER_ADMIN'
    ) {
      return;
    }

    if (role.name === 'super_admin') {
      throw new ForbiddenException(
        'Only an existing Super Admin can assign the super_admin role.',
      );
    }

    const rolePerms = Array.isArray(role.permissions)
      ? (role.permissions as string[])
      : [];
    const held = new Set(actorContext.permissions ?? []);
    const unauthorized = rolePerms.filter((p) => !held.has(p));
    if (unauthorized.length > 0) {
      throw new ForbiddenException(
        `Privilege escalation blocked. Target role contains permissions outside your scope: ${unauthorized.join(', ')}`,
      );
    }
  }
}
