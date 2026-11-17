import { Injectable, NotFoundException, Optional } from '@nestjs/common';
import { PrismaService } from '../../core/database/prisma.service';
import { RedisService } from '../../core/redis/redis.service';

const LOCATIONS_CACHE_TTL_SECONDS = 1800; // 30 minutes

@Injectable()
export class LocationsService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  /**
   * Returns all active governorates in Egypt with their primary cities (cached in Redis).
   */
  async getGovernorates() {
    const cacheKey = 'locations:governorates';
    const cached = await this.redis?.get<any[]>(cacheKey);
    if (cached) {
      return cached;
    }

    const governorates = await this.prisma.governorate.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: {
        cities: {
          where: { isActive: true },
          orderBy: { nameAr: 'asc' },
        },
      },
    });

    await this.redis?.set(cacheKey, governorates, LOCATIONS_CACHE_TTL_SECONDS);
    return governorates;
  }

  /**
   * Returns all active areas/neighborhoods for a given city ID (cached in Redis).
   */
  async getAreasByCity(cityId: number) {
    const cacheKey = `locations:areas:city:${cityId}`;
    const cached = await this.redis?.get<any[]>(cacheKey);
    if (cached) {
      return cached;
    }

    const city = await this.prisma.city.findUnique({
      where: { id: cityId },
    });

    if (!city) {
      throw new NotFoundException(`City with ID ${cityId} not found`);
    }

    const areas = await this.prisma.area.findMany({
      where: { cityId, isActive: true },
      orderBy: { nameAr: 'asc' },
    });

    await this.redis?.set(cacheKey, areas, LOCATIONS_CACHE_TTL_SECONDS);
    return areas;
  }
}
