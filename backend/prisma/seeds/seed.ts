import { PrismaClient } from '@prisma/client';
import * as crypto from 'crypto';
import { EGYPT_GEOGRAPHY } from './geography-data';
import { DEAL_ONE_TAXONOMY } from './taxonomy-data';
import { DEMO_SELLERS } from './demo-sellers-data';
import { DEMO_LISTINGS_TEMPLATES } from './demo-listings-generator';
import { normalizeArabicText } from '../../src/modules/search/arabic-normalizer';

const prisma = new PrismaClient();

const SEED_SOURCE = 'deal-one-demo-seed';
const SEED_VERSION = '2.0.0';

const SECTION_GALLERY_POOL: Record<string, string[]> = {
  'real-estate': [
    'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
  ],
  'building-materials': [
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1562259949-e8e7689d7828?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=800&q=80',
  ],
  services: [
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=800&q=80',
  ],
  'home-appliances': [
    'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?auto=format&fit=crop&w=800&q=80',
  ],
  cars: [
    'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1563720223185-11003d516935?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1489824904134-891ab64532f1?auto=format&fit=crop&w=800&q=80',
  ],
  fashion: [
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=800&q=80',
  ],
};

function deterministicUuid(seedKey: string): string {
  const hash = crypto
    .createHash('sha256')
    .update(`dealone:seed:${SEED_VERSION}:${seedKey}`)
    .digest('hex');
  return [
    hash.slice(0, 8),
    hash.slice(8, 12),
    `5${hash.slice(13, 16)}`,
    `a${hash.slice(17, 20)}`,
    hash.slice(20, 32),
  ].join('-');
}

function assertSafeDatabaseTarget(isProd: boolean, allowOverride: boolean) {
  const rawUrl = process.env.DATABASE_URL || '';
  if (!rawUrl) {
    throw new Error('🚨 SAFETY BLOCK: DATABASE_URL is not defined.');
  }
  let hostname = 'unknown';
  let dbName = 'unknown';
  try {
    const parsed = new URL(rawUrl);
    hostname = parsed.hostname.toLowerCase();
    dbName = parsed.pathname.replace(/^\//, '').toLowerCase();
  } catch {
    throw new Error('🚨 SAFETY BLOCK: Invalid DATABASE_URL format.');
  }

  const forbiddenHostPatterns = [
    'railway.app',
    'rlwy.net',
    'railway.internal',
    'prod',
    'rds.amazonaws.com',
    'neon.tech',
    'supabase.co',
  ];
  const isRemoteProdHost = forbiddenHostPatterns.some((p) =>
    hostname.includes(p),
  );

  if ((isProd || isRemoteProdHost) && !allowOverride) {
    throw new Error(
      `🚨 PRODUCTION DATABASE SAFETY BLOCK: Refusing demo write/cleanup on target host="${hostname}" db="${dbName}" (NODE_ENV=${process.env.NODE_ENV || 'development'}).`,
    );
  }
  console.log(
    `   DB Target Verified: host=${hostname}, database=${dbName} (SAFE FOR DEV/TEST)`,
  );
}

const DEV_GUEST_USER = {
  phone: '+201000000001',
  email: 'dev.guest@dealone.local',
  fullName: 'مصطفى هيكل',
  accountSlug: 'dev-guest-account',
  bio: 'حساب ضيف التطوير الافتراضي لتطبيق ديل ون',
};

async function resetDemoData() {
  console.log('🧹 [DEMO ISOLATION] Cleaning existing demo data safely (isDemo = true only)...');

  // Delete only records explicitly tagged with isDemo: true
  // Respecting foreign keys and cascading order — NEVER touches real user records (isDemo = false)
  const delMedia = await prisma.listingMedia.deleteMany({
    where: { listing: { isDemo: true } },
  });
  console.log(`   - Deleted ${delMedia.count} demo listing media records`);

  const delFavs = await prisma.favorite.deleteMany({
    where: {
      OR: [{ listing: { isDemo: true } }, { user: { isDemo: true } }],
    },
  });
  console.log(`   - Deleted ${delFavs.count} demo favorite bookmarks`);

  const delListings = await prisma.listing.deleteMany({
    where: { isDemo: true },
  });
  console.log(`   - Deleted ${delListings.count} demo listings`);

  const delBranches = await prisma.branch.deleteMany({
    where: { account: { isDemo: true } },
  });
  console.log(`   - Deleted ${delBranches.count} demo seller branches`);

  const delMembers = await prisma.accountMember.deleteMany({
    where: { account: { isDemo: true } },
  });
  console.log(`   - Deleted ${delMembers.count} demo account memberships`);

  const delAccounts = await prisma.account.deleteMany({
    where: { isDemo: true },
  });
  console.log(`   - Deleted ${delAccounts.count} demo seller accounts`);

  const delSessions = await prisma.userSession.deleteMany({
    where: { user: { isDemo: true } },
  });
  console.log(`   - Deleted ${delSessions.count} demo user sessions`);

  const delUsers = await prisma.user.deleteMany({
    where: {
      isDemo: true,
      ownedAccounts: { none: {} },
    },
  });
  console.log(`   - Deleted ${delUsers.count} demo users`);

  console.log('✅ Demo data cleanup completed without affecting real user records.\n');
}

async function main() {
  const args = process.argv.slice(2);
  const isCleanOnly =
    args.includes('--reset-demo') ||
    args.includes('--clean-demo') ||
    process.env.RESET_DEMO === 'true';
  const nodeEnv = process.env.NODE_ENV || 'development';
  const isProd = nodeEnv === 'production';
  const enableDemoData = process.env.ENABLE_DEMO_DATA === 'true';
  const allowDemoCleanup = process.env.ALLOW_DEMO_CLEANUP === 'true';
  const explicitProdOverride =
    process.env.ALLOW_DEMO_SEEDING_IN_PROD === 'true';

  console.log('====================================================');
  console.log('🌱 Deal One Marketplace Database Seeder');
  console.log(`   Environment:        ${nodeEnv}`);
  console.log(`   ENABLE_DEMO_DATA:   ${enableDemoData}`);
  console.log(`   ALLOW_DEMO_CLEANUP: ${allowDemoCleanup}`);
  console.log('====================================================\n');

  // 1. Standalone Demo Cleanup Mode
  if (isCleanOnly) {
    if (!allowDemoCleanup) {
      throw new Error(
        '🚨 SAFETY BLOCK: Demo cleanup requires ALLOW_DEMO_CLEANUP=true.',
      );
    }
    assertSafeDatabaseTarget(isProd, explicitProdOverride);
    await resetDemoData();
    return;
  }

  // Production Gate Protection for Seeding
  const shouldSeedDemo = isProd
    ? enableDemoData && explicitProdOverride
    : enableDemoData;

  if (shouldSeedDemo) {
    assertSafeDatabaseTarget(isProd, explicitProdOverride);
  }

  if (isProd && !shouldSeedDemo) {
    console.warn(
      '⚠️ Production environment detected (demo seeding disabled by default). Seeding ONLY base geography and taxonomy reference data.',
    );
  } else if (!shouldSeedDemo) {
    console.warn(
      'ℹ️ ENABLE_DEMO_DATA is not true. Seeding ONLY base geography and taxonomy reference data.',
    );
  }

  // 2. Seed Geography (Governorates, Cities, Areas with PostGIS Centroids)
  console.log('📍 Seeding Egyptian Administrative Geography...');
  const cityMap = new Map<string, number>();
  const areaMap = new Map<string, string>();

  for (const gov of EGYPT_GEOGRAPHY) {
    const dbGov = await prisma.governorate.upsert({
      where: { slug: gov.slug },
      update: {
        nameAr: gov.nameAr,
        nameEn: gov.nameEn,
        sortOrder: gov.sortOrder,
      },
      create: {
        slug: gov.slug,
        nameAr: gov.nameAr,
        nameEn: gov.nameEn,
        sortOrder: gov.sortOrder,
      },
    });

    for (const city of gov.cities) {
      const dbCity = await prisma.city.upsert({
        where: {
          uq_city_gov_slug: {
            governorateId: dbGov.id,
            slug: city.slug,
          },
        },
        update: {
          nameAr: city.nameAr,
          nameEn: city.nameEn,
        },
        create: {
          governorateId: dbGov.id,
          slug: city.slug,
          nameAr: city.nameAr,
          nameEn: city.nameEn,
        },
      });

      cityMap.set(city.slug, dbCity.id);

      for (const area of city.areas) {
        // Query area by name and city
        let dbArea = await prisma.area.findFirst({
          where: { cityId: dbCity.id, nameAr: area.nameAr },
        });

        if (!dbArea) {
          // Use raw SQL to insert geometry accurately
          const areaInsert = await prisma.$queryRaw<Array<{ id: string }>>`
            INSERT INTO areas (id, city_id, name_ar, name_en, centroid, is_active)
            VALUES (
              gen_random_uuid(),
              ${dbCity.id},
              ${area.nameAr},
              ${area.nameEn},
              ST_SetSRID(ST_MakePoint(${area.longitude}, ${area.latitude}), 4326),
              true
            )
            RETURNING id;
          `;
          dbArea = areaInsert[0] as any;
        }

        if (dbArea) {
          areaMap.set(`${city.slug}:${area.nameAr}`, dbArea.id);
        }
      }
    }
  }
  console.log(`   ✔ Geography seeded: ${cityMap.size} cities and ${areaMap.size} areas registered.\n`);

  // 3. Seed Deal One 6-Section Commercial Taxonomy & Dynamic Fields
  console.log('📂 Seeding 6 Commercial Taxonomy Sections & Leaf Subcategories...');
  const categoryMap = new Map<string, string>();

  for (const rootCat of DEAL_ONE_TAXONOMY) {
    const dbRoot = await prisma.category.upsert({
      where: { slug: rootCat.slug },
      update: {
        nameAr: rootCat.nameAr,
        nameEn: rootCat.nameEn,
        iconUrl: rootCat.iconUrl,
        sortOrder: rootCat.sortOrder,
      },
      create: {
        slug: rootCat.slug,
        nameAr: rootCat.nameAr,
        nameEn: rootCat.nameEn,
        iconUrl: rootCat.iconUrl,
        sortOrder: rootCat.sortOrder,
      },
    });

    categoryMap.set(rootCat.slug, dbRoot.id);

    // Also support underscore slug alias if hyphenated
    if (rootCat.slug.includes('-')) {
      categoryMap.set(rootCat.slug.replace(/-/g, '_'), dbRoot.id);
    }

    for (const sub of rootCat.subcategories) {
      const dbSub = await prisma.category.upsert({
        where: { slug: sub.slug },
        update: {
          nameAr: sub.nameAr,
          nameEn: sub.nameEn,
          iconUrl: sub.iconUrl,
          parentId: dbRoot.id,
        },
        create: {
          slug: sub.slug,
          nameAr: sub.nameAr,
          nameEn: sub.nameEn,
          iconUrl: sub.iconUrl,
          parentId: dbRoot.id,
        },
      });

      categoryMap.set(sub.slug, dbSub.id);
      if (sub.slug.includes('-')) {
        categoryMap.set(sub.slug.replace(/-/g, '_'), dbSub.id);
      }

      // Upsert Category Dynamic Fields
      if (sub.fields && sub.fields.length > 0) {
        for (const field of sub.fields) {
          await prisma.categoryField.upsert({
            where: {
              uq_cat_field_key: {
                categoryId: dbSub.id,
                fieldKey: field.fieldKey,
              },
            },
            update: {
              labelAr: field.labelAr,
              labelEn: field.labelEn,
              fieldType: field.fieldType,
              isRequired: field.isRequired,
              isFilterable: field.isFilterable,
              validationRules: (field.validationRules as any) || {},
              sortOrder: field.sortOrder,
            },
            create: {
              categoryId: dbSub.id,
              fieldKey: field.fieldKey,
              labelAr: field.labelAr,
              labelEn: field.labelEn,
              fieldType: field.fieldType,
              isRequired: field.isRequired,
              isFilterable: field.isFilterable,
              validationRules: (field.validationRules as any) || {},
              sortOrder: field.sortOrder,
            },
          });
        }
      }
    }
  }
  // Deactivate any legacy root categories not in Deal One's 6 approved sections (only if they have 0 listings)
  const approvedRootSlugs = DEAL_ONE_TAXONOMY.map((c) => c.slug);
  await prisma.category.updateMany({
    where: {
      parentId: null,
      slug: { notIn: approvedRootSlugs },
      listings: { none: {} },
    },
    data: { isActive: false },
  });
  console.log(`   ✔ Taxonomy seeded: 6 sections and ${categoryMap.size} category identifiers.\n`);

  // Stop here if demo data seeding is disabled (e.g. Production)
  if (!shouldSeedDemo) {
    console.log('====================================================');
    console.log('✅ BASE REFERENCE DATA SEED COMPLETED (NO DEMO DATA)');
    console.log('====================================================');
    return;
  }

  // Clean existing demo data before re-seeding to guarantee strict idempotency without duplicates
  await resetDemoData();

  // 4. Seed Fixed Development Guest Account
  console.log('👤 Seeding Development Guest Account...');
  const devGuest = await prisma.user.upsert({
    where: { phone: DEV_GUEST_USER.phone },
    update: {
      fullName: DEV_GUEST_USER.fullName,
      email: DEV_GUEST_USER.email,
      isPhoneVerified: true,
      isEmailVerified: true,
      isActive: true,
      isDemo: true,
    },
    create: {
      phone: DEV_GUEST_USER.phone,
      fullName: DEV_GUEST_USER.fullName,
      email: DEV_GUEST_USER.email,
      isPhoneVerified: true,
      isEmailVerified: true,
      isActive: true,
      isDemo: true,
      preferredLanguage: 'ar',
    },
  });
  const devGuestAccount = await prisma.account.upsert({
    where: { slug: DEV_GUEST_USER.accountSlug },
    update: {
      ownerUserId: devGuest.id,
      displayName: DEV_GUEST_USER.fullName,
      isActive: true,
      isDemo: true,
    },
    create: {
      slug: DEV_GUEST_USER.accountSlug,
      ownerUserId: devGuest.id,
      accountType: 'individual',
      displayName: DEV_GUEST_USER.fullName,
      bio: DEV_GUEST_USER.bio,
      verificationStatus: 'approved',
      isActive: true,
      isDemo: true,
    },
  });
  await prisma.accountMember.upsert({
    where: {
      uq_account_user: {
        accountId: devGuestAccount.id,
        userId: devGuest.id,
      },
    },
    update: { role: 'owner' },
    create: {
      accountId: devGuestAccount.id,
      userId: devGuest.id,
      role: 'owner',
    },
  });
  console.log(`   ✔ Development Guest seeded: ${devGuest.fullName} (${devGuest.phone})\n`);

  // 5. Seed Verified Egyptian Demo Sellers & Branches
  console.log('🏢 Seeding Verified Demo Sellers & Branches...');
  const accountMap = new Map<string, string>();

  for (const seller of DEMO_SELLERS) {
    const user = await prisma.user.upsert({
      where: { phone: seller.userPhone },
      update: {
        fullName: seller.userFullName,
        email: seller.userEmail,
        isPhoneVerified: true,
        isEmailVerified: true,
        isDemo: true,
      },
      create: {
        phone: seller.userPhone,
        fullName: seller.userFullName,
        email: seller.userEmail,
        isPhoneVerified: true,
        isEmailVerified: true,
        isDemo: true,
      },
    });

    const account = await prisma.account.upsert({
      where: { slug: seller.accountSlug },
      update: {
        ownerUserId: user.id,
        displayName: seller.accountDisplayName,
        accountType: seller.accountType,
        bio: seller.bio,
        logoUrl: seller.logoUrl,
        bannerUrl: seller.bannerUrl,
        verificationStatus: seller.verificationStatus,
        isActive: true,
        isDemo: true,
      },
      create: {
        slug: seller.accountSlug,
        ownerUserId: user.id,
        displayName: seller.accountDisplayName,
        accountType: seller.accountType,
        bio: seller.bio,
        logoUrl: seller.logoUrl,
        bannerUrl: seller.bannerUrl,
        verificationStatus: seller.verificationStatus,
        isActive: true,
        isDemo: true,
      },
    });

    accountMap.set(seller.accountSlug, account.id);

    // Membership
    await prisma.accountMember.upsert({
      where: {
        uq_account_user: {
          accountId: account.id,
          userId: user.id,
        },
      },
      update: { role: 'owner' },
      create: {
        accountId: account.id,
        userId: user.id,
        role: 'owner',
      },
    });

    // Branch
    const areaId = areaMap.get(`${seller.branchCitySlug}:${seller.branchAreaName}`);
    if (areaId) {
      await prisma.branch.create({
        data: {
          accountId: account.id,
          areaId,
          name: `${seller.accountDisplayName} - الفرع الرئيسي`,
          address: seller.branchAddress,
          phone: seller.userPhone,
          isMain: true,
        },
      });
    }
  }
  console.log(`   ✔ Demo sellers seeded: ${accountMap.size} verified merchant accounts.\n`);

  // 6. Seed Comprehensive Demo Marketplace Listings (Deterministic Stable IDs + 3+ Images each)
  console.log('🛍️ Seeding Realistic Egyptian Marketplace Listings...');
  const seedStartMs = Date.now();
  let totalListingsCount = 0;
  let totalImagesCount = 0;
  let totalFeaturedCount = 0;
  const defaultAreaId = Array.from(areaMap.values())[0];
  const allAccountIds = Array.from(accountMap.values());
  const defaultAccountId = allAccountIds[0];

  // Map subcategory slug -> root section slug for gallery matching & seller rotation
  const subToRootSlug = new Map<string, string>();
  for (const root of DEAL_ONE_TAXONOMY) {
    subToRootSlug.set(root.slug, root.slug);
    for (const sub of root.subcategories) {
      subToRootSlug.set(sub.slug, root.slug);
    }
  }

  const sectionExtraSellers: Record<string, string[]> = {
    'real-estate': ['al-ahram-realestate', 'zayed-heights-realty', 'tanta-prime-estates', 'ahmed-elmasry-seller'],
    'building-materials': ['el-ezz-steel-trading', 'al-swedy-electric-trading', 'al-qadi-paints-hub', 'nile-sanitary-plumbing', 'delta-cement-corp'],
    services: ['al-handaseya-finishing', 'al-aman-moving', 'fastfix-egypt-services', 'decora-design-studio'],
    'home-appliances': ['al-alamiya-appliances', 'modern-home-furniture', 'lumina-lighting-decor'],
    cars: ['cairo-motors-hub', 'alex-auto-parts-center', 'auto-elite-motors', 'ahmed-elmasry-seller'],
    fashion: ['el-basha-fashion-stores', 'crown-watches-accessories', 'velvet-cairo-boutique'],
  };

  for (let idx = 0; idx < DEMO_LISTINGS_TEMPLATES.length; idx++) {
    const template = DEMO_LISTINGS_TEMPLATES[idx];
    const categoryId = categoryMap.get(template.subcategorySlug);
    if (!categoryId) {
      console.warn(`   ⚠️ Subcategory slug '${template.subcategorySlug}' not found in map, skipping.`);
      continue;
    }

    const rootSlug = subToRootSlug.get(template.subcategorySlug) || 'real-estate';
    const sectionPool = sectionExtraSellers[rootSlug] || [];
    const rotatedSlug =
      sectionPool.length > 0 && idx % 2 === 1
        ? sectionPool[idx % sectionPool.length]
        : template.sellerAccountSlug;
    const accountId =
      accountMap.get(rotatedSlug) ||
      accountMap.get(template.sellerAccountSlug) ||
      defaultAccountId;
    const areaId = areaMap.get(`${template.citySlug}:${template.areaName}`) || defaultAreaId;

    // Realistic deterministic timestamp: spread over the last 14 days
    const daysAgo = (totalListingsCount % 14) + 1;
    const refreshedAt = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
    const expiresAt = new Date(Date.now() + 45 * 24 * 60 * 60 * 1000);
    // Mark 20% of listings evenly across all categories as Featured (promotedUntil in future)
    const isFeatured = totalListingsCount % 5 === 0;
    const promotedUntil = isFeatured
      ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      : null;
    if (isFeatured) totalFeaturedCount++;

    const stableListingId = deterministicUuid(`${template.subcategorySlug}:${idx}`);
    const enrichedAttributes: Record<string, unknown> = {
      ...((template.attributes as Record<string, unknown>) || {}),
      condition:
        (template.attributes as any)?.condition ||
        (idx % 3 === 0 ? 'NEW' : 'USED'),
      _seedMeta: {
        seedSource: SEED_SOURCE,
        seedVersion: SEED_VERSION,
        section: rootSlug,
      },
    };

    const listing = await prisma.listing.create({
      data: {
        id: stableListingId,
        accountId,
        categoryId,
        areaId,
        title: template.title,
        description: template.description,
        searchNormalizedText: normalizeArabicText(
          `${template.title} ${template.description}`,
        ),
        price: template.price,
        currency: 'EGP',
        listingKind: template.listingKind,
        contactChannel: 'in_app',
        moderationStatus: 'approved',
        publicationStatus: 'published',
        availabilityStatus: 'available',
        isDemo: true,
        attributes: enrichedAttributes as any,
        viewsCount: 45 + (totalListingsCount * 17) % 350,
        contactRevealsCount: 3 + (totalListingsCount * 3) % 25,
        promotedUntil,
        approvedAt: refreshedAt,
        refreshedAt,
        expiresAt,
        createdAt: refreshedAt,
      },
    });

    // Seed a few sample favorites for the Development Guest account
    if (totalListingsCount < 4) {
      await prisma.favorite.upsert({
        where: {
          uq_user_favorite: {
            userId: devGuest.id,
            listingId: listing.id,
          },
        },
        update: {},
        create: {
          userId: devGuest.id,
          listingId: listing.id,
        },
      });
    }

    totalListingsCount++;

    // Ensure 3+ distinct category-matched images per listing
    const galleryPool = SECTION_GALLERY_POOL[rootSlug] || SECTION_GALLERY_POOL['real-estate'];
    const images: string[] = [...template.images];
    let poolCursor = idx;
    while (images.length < 3) {
      const candidate = galleryPool[poolCursor % galleryPool.length];
      if (!images.includes(candidate)) {
        images.push(candidate);
      }
      poolCursor++;
      if (poolCursor > idx + galleryPool.length + 3) break;
    }

    const mediaRecords = images.map((url, index) => ({
      listingId: listing.id,
      mediaType: 'image',
      storageKey: `demo/images/${template.subcategorySlug}/${listing.id.substring(0, 8)}_${index}.jpg`,
      publicUrl: url,
      thumbnailUrl: url,
      sortOrder: index,
      isPrimary: index === 0,
      processingStatus: 'ready',
    }));

    await prisma.listingMedia.createMany({
      data: mediaRecords,
    });
    totalImagesCount += mediaRecords.length;
  }

  // Synchronize spatial PostGIS geometries for listings and branches with their area centroids
  await prisma.$executeRaw`
    UPDATE listings l
    SET display_location = a.centroid,
        physical_location = a.centroid
    FROM areas a
    WHERE l.area_id = a.id;
  `;
  await prisma.$executeRaw`
    UPDATE branches b
    SET location = a.centroid
    FROM areas a
    WHERE b.area_id = a.id;
  `;
  console.log('   ✔ Synchronized PostGIS geometry centroids for listings and branches.');

  const elapsedSec = ((Date.now() - seedStartMs) / 1000).toFixed(2);
  console.log('\n==================== SEED EXECUTION REPORT ====================');
  console.log(`   Seed Source:        ${SEED_SOURCE} v${SEED_VERSION}`);
  console.log(`   Root Categories:    ${DEAL_ONE_TAXONOMY.length}`);
  console.log(`   Demo Sellers:       ${accountMap.size} (+ 1 Dev Guest)`);
  console.log(`   Demo Listings:      ${totalListingsCount} (Featured: ${totalFeaturedCount})`);
  console.log(`   Listing Images:     ${totalImagesCount} (Avg ${(totalImagesCount / Math.max(totalListingsCount, 1)).toFixed(1)}/listing)`);
  console.log(`   Duration:           ${elapsedSec}s`);
  console.log('===============================================================');
}

main()
  .catch((e) => {
    console.error('❌ Seeder execution error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
