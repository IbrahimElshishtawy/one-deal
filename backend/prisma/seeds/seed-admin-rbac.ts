import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';
import * as crypto from 'crypto';
import { INITIAL_ADMIN_ROLES } from '../../src/modules/admin-auth/constants/admin-permissions.constant';

const prisma = new PrismaClient();

async function seedAdminRbac() {
  console.log('🔐 Seeding Deal One Enterprise Admin Roles & Baseline Data...');

  const roleMap = new Map<string, number>();

  for (const roleSpec of INITIAL_ADMIN_ROLES) {
    const role = await prisma.staffRole.upsert({
      where: { name: roleSpec.name },
      update: {
        description: roleSpec.description,
        isSystem: roleSpec.isSystem,
        permissions: roleSpec.permissions,
      },
      create: {
        name: roleSpec.name,
        description: roleSpec.description,
        isSystem: roleSpec.isSystem,
        permissions: roleSpec.permissions,
      },
    });
    roleMap.set(role.name, role.id);
    console.log(
      `  ✓ Role [${role.name}] (id=${role.id}, permissions=${roleSpec.permissions.length})`,
    );
  }

  // Bootstrap initial Super Admin account if configured or in non-production
  const isProd = process.env.NODE_ENV === 'production';
  const superAdminEmail = (
    process.env.BOOTSTRAP_SUPER_ADMIN_EMAIL ||
    (isProd ? '' : 'superadmin@dealone.eg')
  )
    .trim()
    .toLowerCase();
  const superAdminPassword =
    process.env.BOOTSTRAP_SUPER_ADMIN_PASSWORD ||
    (isProd ? '' : 'SuperAdmin!2026');

  if (superAdminEmail && superAdminPassword) {
    const superRoleId = roleMap.get('super_admin')!;
    const existing = await prisma.staffUser.findUnique({
      where: { email: superAdminEmail },
    });
    if (!existing) {
      const passwordHash = await argon2.hash(superAdminPassword);
      await prisma.staffUser.create({
        data: {
          email: superAdminEmail,
          passwordHash,
          fullName: 'Deal One Super Admin',
          department: 'Executive & Security',
          jobTitle: 'Super Administrator',
          roleId: superRoleId,
          status: 'active',
          isActive: true,
        },
      });
      console.log(`  ✓ Created Super Admin: ${superAdminEmail}`);
    } else {
      console.log(`  • Super Admin already exists: ${superAdminEmail}`);
    }
  }

  // Seed sample non-production staff personas for local RBAC verification
  if (!isProd) {
    const devPersonas = [
      {
        email: 'moderator@dealone.eg',
        fullName: 'Content Moderator',
        roleName: 'content_moderator',
        department: 'Trust & Safety',
        jobTitle: 'Senior Content Moderator',
      },
      {
        email: 'verification@dealone.eg',
        fullName: 'Verification Officer',
        roleName: 'verification_officer',
        department: 'Compliance & KYC',
        jobTitle: 'Verification Specialist',
      },
      {
        email: 'support@dealone.eg',
        fullName: 'Customer Support Agent',
        roleName: 'customer_support',
        department: 'Customer Experience',
        jobTitle: 'Support Specialist',
      },
      {
        email: 'marketing@dealone.eg',
        fullName: 'Marketing Manager',
        roleName: 'marketing_manager',
        department: 'Growth & Content',
        jobTitle: 'Marketing Lead',
      },
      {
        email: 'analyst@dealone.eg',
        fullName: 'Marketplace Analyst',
        roleName: 'analyst',
        department: 'Business Intelligence',
        jobTitle: 'Data Analyst',
      },
      {
        email: 'auditor@dealone.eg',
        fullName: 'Security Auditor',
        roleName: 'security_auditor',
        department: 'Information Security',
        jobTitle: 'Security & Compliance Auditor',
      },
    ];

    const devPasswordHash = await argon2.hash('AdminStaff!2026');
    for (const p of devPersonas) {
      const roleId = roleMap.get(p.roleName)!;
      await prisma.staffUser.upsert({
        where: { email: p.email },
        update: { roleId, status: 'active', isActive: true },
        create: {
          email: p.email,
          passwordHash: devPasswordHash,
          fullName: p.fullName,
          department: p.department,
          jobTitle: p.jobTitle,
          roleId,
          status: 'active',
          isActive: true,
        },
      });
    }
    console.log('  ✓ Seeded local verification staff personas (password: AdminStaff!2026)');
  }

  // Idempotent Feature Flags
  const defaultFlags = [
    {
      key: 'auto_approve_listings',
      name: 'Auto-Approve Listings',
      description: 'Automatically publish new listings without manual review',
      isEnabled: false,
      environment: 'all',
      rolloutPercentage: 100,
      isSystem: true,
    },
    {
      key: 'enable_video_feed',
      name: 'Short Video Feed',
      description: 'Enable vertical video feed in the mobile application',
      isEnabled: true,
      environment: 'all',
      rolloutPercentage: 100,
      isSystem: true,
    },
    {
      key: 'enable_in_app_chat',
      name: 'In-App Chat Messaging',
      description: 'Enable real-time buyer-seller messaging',
      isEnabled: true,
      environment: 'all',
      rolloutPercentage: 100,
      isSystem: true,
    },
    {
      key: 'maintenance_mode',
      name: 'Maintenance Mode',
      description: 'Display maintenance notice and restrict mutating marketplace actions',
      isEnabled: false,
      environment: 'all',
      rolloutPercentage: 100,
      isSystem: true,
    },
    {
      key: 'enable_v2_payments',
      name: 'V2 Paid Promotions (Paymob)',
      description: 'Enable V2 promotion packages checkout (disabled in V1)',
      isEnabled: false,
      environment: 'all',
      rolloutPercentage: 0,
      isSystem: true,
    },
  ];

  for (const flag of defaultFlags) {
    await prisma.featureFlag.upsert({
      where: { key: flag.key },
      update: {},
      create: {
        ...flag,
        rules: { history: [] },
      },
    });
  }
  console.log(`  ✓ Seeded ${defaultFlags.length} default feature flags`);

  // Idempotent Default Platform Settings
  const defaultSettings = [
    {
      key: 'general.platform_name',
      value: { ar: 'صفقة ون', en: 'Deal One' },
      description: 'Public marketplace name in Arabic and English',
    },
    {
      key: 'listings.max_active_per_account',
      value: { individual: 10, business: 100 },
      description: 'Maximum active published listings per account tier',
    },
    {
      key: 'listings.default_expiry_days',
      value: 30,
      description: 'Default active duration in days before listing expiry',
    },
    {
      key: 'moderation.auto_approve',
      value: false,
      description: 'Whether newly submitted listings bypass human review queue',
    },
    {
      key: 'maintenance.enabled',
      value: {
        enabled: false,
        messageAr: 'النظام في وضع الصيانة المجدولة حالياً.',
        messageEn: 'The platform is currently undergoing scheduled maintenance.',
      },
      description: 'Marketplace maintenance banner and state configuration',
    },
    {
      key: 'localization.supported_languages',
      value: { default: 'ar', supported: ['ar', 'en'] },
      description: 'Supported client application languages',
    },
    {
      key: 'support.contact',
      value: {
        email: 'support@dealone.eg',
        phone: '+201000000000',
        workingHours: '09:00-21:00 Africa/Cairo',
      },
      description: 'Customer support contact information displayed in app',
    },
  ];

  for (const s of defaultSettings) {
    await prisma.platformSetting.upsert({
      where: { key: s.key },
      update: {},
      create: s,
    });
  }
  console.log(`  ✓ Seeded ${defaultSettings.length} default platform settings`);

  // Idempotent Default CMS Items
  const defaultCms = [
    {
      type: 'banner',
      slug: 'home-hero-welcome',
      titleAr: 'مرحباً بك في صفقة ون — سوق مصر الأول للعقارات والسيارات والخدمات',
      titleEn: 'Welcome to Deal One — Egypt Marketplace for Real Estate, Cars & Services',
      bodyAr: 'تصفح آلاف الإعلانات الموثوقة أو أنشر إعلانك مجاناً خلال دقائق.',
      bodyEn: 'Browse thousands of verified listings or publish your listing for free in minutes.',
      placement: 'home_hero',
      sortOrder: 1,
      status: 'published',
      isActive: true,
    },
    {
      type: 'terms',
      slug: 'terms-and-conditions',
      titleAr: 'الشروط والأحكام',
      titleEn: 'Terms and Conditions',
      bodyAr: 'باستخدامك لمنصة صفقة ون فإنك توافق على الالتزام بسياسات النشر وعدم نشر محتوى مخالف.',
      bodyEn: 'By using Deal One, you agree to comply with marketplace publishing policies and refrain from prohibited content.',
      placement: 'legal',
      sortOrder: 1,
      status: 'published',
      isActive: true,
    },
    {
      type: 'privacy',
      slug: 'privacy-policy',
      titleAr: 'سياسة الخصوصية',
      titleEn: 'Privacy Policy',
      bodyAr: 'تحترم صفقة ون خصوصية المستخدمين وتحمي بيانات التواصل ومستندات التوثيق وفق أعلى معايير الأمان.',
      bodyEn: 'Deal One respects user privacy and protects contact data and verification documents under strict security controls.',
      placement: 'legal',
      sortOrder: 2,
      status: 'published',
      isActive: true,
    },
    {
      type: 'faq',
      slug: 'faq-how-to-post',
      titleAr: 'كيف أنشر إعلاناً على صفقة ون؟',
      titleEn: 'How do I publish a listing on Deal One?',
      bodyAr: 'اختر القسم المناسب، أضف الصور والتفاصيل والمدينة، ثم أرسل الإعلان للمراجعة.',
      bodyEn: 'Select the category, upload images, enter details and city, then submit your listing for review.',
      placement: 'help',
      sortOrder: 1,
      status: 'published',
      isActive: true,
    },
  ];

  for (const item of defaultCms) {
    await prisma.cmsItem.upsert({
      where: { slug: item.slug },
      update: {},
      create: {
        id: crypto.randomUUID(),
        ...item,
        revisions: [],
      },
    });
  }
  console.log(`  ✓ Seeded ${defaultCms.length} default CMS items`);
}

seedAdminRbac()
  .then(async () => {
    await prisma.$disconnect();
    console.log('✅ Enterprise Admin RBAC seed completed successfully.');
  })
  .catch(async (err) => {
    console.error('❌ Error seeding admin RBAC:', err);
    await prisma.$disconnect();
    process.exit(1);
  });
