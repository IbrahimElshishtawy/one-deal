import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as argon2 from 'argon2';
import { PrismaService } from '../../core/database/prisma.service';
import { CreateStaffRoleDto } from './dto/create-staff-role.dto';
import { CreateStaffUserDto } from './dto/create-staff-user.dto';
import { UpdateStaffUserDto } from './dto/update-staff-user.dto';

const SAFE_STAFF_SELECT = {
  id: true,
  email: true,
  fullName: true,
  roleId: true,
  isActive: true,
  createdAt: true,
  role: true,
};

@Injectable()
export class StaffService {
  constructor(private readonly prisma: PrismaService) {}

  async listRoles() {
    return this.prisma.staffRole.findMany({
      orderBy: { id: 'asc' },
    });
  }

  async createRole(dto: CreateStaffRoleDto, actorId: string) {
    const existing = await this.prisma.staffRole.findUnique({
      where: { name: dto.name },
    });
    if (existing) {
      throw new ConflictException(`Staff role '${dto.name}' already exists`);
    }

    return this.prisma.$transaction(async (tx) => {
      const role = await tx.staffRole.create({
        data: {
          name: dto.name,
          permissions: dto.permissions ?? [],
        },
      });

      await tx.auditLog.create({
        data: {
          actorType: 'staff',
          actorId,
          action: 'STAFF_ROLE_CREATED',
          targetEntity: 'staff_role',
          diffPayload: { roleId: role.id, name: role.name },
        },
      });

      return role;
    });
  }

  async listStaffUsers() {
    return this.prisma.staffUser.findMany({
      select: SAFE_STAFF_SELECT,
      orderBy: { createdAt: 'desc' },
    });
  }

  async createStaffUser(dto: CreateStaffUserDto, actorId: string) {
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

  async updateStaffUser(
    staffId: string,
    dto: UpdateStaffUserDto,
    actorId: string,
  ) {
    const existing = await this.prisma.staffUser.findUnique({
      where: { id: staffId },
      select: { id: true, isActive: true, roleId: true },
    });

    if (!existing) {
      throw new NotFoundException('Staff user not found');
    }

    if (dto.roleId !== undefined) {
      const role = await this.prisma.staffRole.findUnique({
        where: { id: dto.roleId },
      });
      if (!role) {
        throw new NotFoundException('Staff role not found');
      }
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.staffUser.update({
        where: { id: staffId },
        data: {
          ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
          ...(dto.roleId !== undefined ? { roleId: dto.roleId } : {}),
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
            newIsActive: updated.isActive,
            previousRoleId: existing.roleId,
            newRoleId: updated.roleId,
          },
        },
      });

      return updated;
    });
  }
}
