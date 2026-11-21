import type { SeedListingTemplate } from './demo-listings-generator';
import { EGYPT_GEOGRAPHY } from './geography-data';
import { DEAL_ONE_TAXONOMY } from './taxonomy-data';

interface AreaEntry {
  citySlug: string;
  cityAr: string;
  areaName: string;
}

const ALL_AREAS: AreaEntry[] = [];
for (const gov of EGYPT_GEOGRAPHY) {
  for (const city of gov.cities) {
    for (const area of city.areas) {
      ALL_AREAS.push({
        citySlug: city.slug,
        cityAr: city.nameAr,
        areaName: area.nameAr,
      });
    }
  }
}

const SECTION_SELLERS: Record<string, string[]> = {
  'real-estate': [
    'al-ahram-realestate',
    'zayed-heights-realty',
    'tanta-prime-estates',
    'ahmed-elmasry-seller',
  ],
  'building-materials': [
    'el-ezz-steel-trading',
    'al-swedy-electric-trading',
    'al-qadi-paints-hub',
    'nile-sanitary-plumbing',
    'delta-cement-corp',
  ],
  services: [
    'al-handaseya-finishing',
    'al-aman-moving',
    'fastfix-egypt-services',
    'decora-design-studio',
  ],
  'home-appliances': [
    'al-alamiya-appliances',
    'modern-home-furniture',
    'lumina-lighting-decor',
    'ahmed-elmasry-seller',
  ],
  cars: [
    'cairo-motors-hub',
    'alex-auto-parts-center',
    'auto-elite-motors',
    'ahmed-elmasry-seller',
  ],
  fashion: [
    'el-basha-fashion-stores',
    'crown-watches-accessories',
    'velvet-cairo-boutique',
  ],
};

const SUB_TO_SECTION: Record<string, string> = {};
const ORDERED_SUBCATEGORIES: string[] = [];
for (const section of DEAL_ONE_TAXONOMY) {
  for (const sub of section.subcategories) {
    SUB_TO_SECTION[sub.slug] = section.slug;
    ORDERED_SUBCATEGORIES.push(sub.slug);
  }
}

const TITLE_PREFIXES_BY_KIND: Record<string, string[]> = {
  sale: [
    'فرصة مميزة',
    'عرض حصري',
    'بسعر لقطة',
    'استلام فوري',
    'مباشر بدون وسيط',
    'موقع متميز',
    'حالة ممتازة',
    'أفضل سعر',
  ],
  rent: [
    'متاح فوراً',
    'عرض مميز للإيجار',
    'موقع حيوي',
    'تشطيب حديث',
    'إيجار ميسر',
    'جاهز للسكن',
    'للعائلات والشركات',
    'فرصة إيجار',
  ],
  service: [
    'خدمة سريعة',
    'فنيون معتمدون',
    'ضمان شامل',
    'أفضل جودة',
    'تنفيذ فوري',
    'أسعار تنافسية',
    'خبرة طويلة',
    'معاينة مجانية',
  ],
  product: [
    'أصلي بالضمان',
    'الأكثر مبيعاً',
    'عرض خاص',
    'توصيل سريع',
    'خصم لفترة محدودة',
    'إصدار حديث',
    'جودة عالية',
    'متوفر الآن',
  ],
};

const DESCRIPTION_ADDONS_BY_SECTION: Record<string, string[]> = {
  'real-estate': [
    'معاينة يومية متاحة بموعد مسبق، والأوراق القانونية جاهزة للفحص.',
    'إمكانية التفاوض الجاد عند المعاينة مع مرونة في طرق السداد.',
    'قريب من المحاور الرئيسية والخدمات التعليمية والتجارية والطبية.',
    'تشطيب متقن ومرافق مكتملة وجاهزية كاملة للاستلام.',
  ],
  'building-materials': [
    'توريد فوري للمواقع والمشروعات مع فواتير ضريبية وشهادات جودة.',
    'أسعار خاصة للكميات الكبيرة والمقاولين وشركات التطوير.',
    'تغليف وتخزين مطابق للمواصفات القياسية المصرية.',
    'متوفر التسليم من المخزن مباشرة أو النقل حتى باب الموقع.',
  ],
  services: [
    'التزام تام بالمواعيد المحددة مع إشراف هندسي وفني متخصص.',
    'ضمان حقيقي على كافة الأعمال المنفذة وخدمة ما بعد التنفيذ.',
    'تغطية شاملة لجميع الأحياء المجاورة بأسعار واضحة ومناسبة.',
    'إمكانية تنفيذ التعاقدات الفردية والمؤسسية بأعلى دقة.',
  ],
  'home-appliances': [
    'ضمان الوكيل المعتمد مع إمكانية التركيب والتشغيل التجريبي.',
    'متوفر الدفع عند الاستلام أو التقسيط البنكي الميسر.',
    'فحص شامل قبل الشحن وتغليف آمن يحافظ على المنتج.',
    'خدمة عملاء متابعة بعد البيع وتوافر قطع الغيار الأصلية.',
  ],
  cars: [
    'إمكانية الكشف الفني في أي مركز معتمد قبل إتمام التعاقد.',
    'متاح أنظمة تقسيط مرنة بمقدم يبدأ من 25% وبأقل فائدة.',
    'فحص شامل للمحرك والفتيس والعفشة والشاسيه.',
    'تخليص فوري لإجراءات المرور ونقل الملكية.',
  ],
  fashion: [
    'متاح الشحن السريع مع إمكانية الاستبدال والاسترجاع خلال 14 يوماً.',
    'خامات مختارة بعناية وتقفيل عالي الجودة يناسب الذوق الراقي.',
    'تشكيلة مقاسات وألوان متنوعة متوفرة في المخزون حالياً.',
    'تغليف أنيق ومناسب للإهداء مع خصومات للطلبات المتعددة.',
  ],
};

function roundNaturalPrice(price: number): number {
  if (price >= 1_000_000) return Math.round(price / 50_000) * 50_000;
  if (price >= 100_000) return Math.round(price / 5_000) * 5_000;
  if (price >= 10_000) return Math.round(price / 500) * 500;
  if (price >= 1_000) return Math.round(price / 50) * 50;
  if (price >= 100) return Math.round(price / 10) * 10;
  return Math.max(10, Math.round(price));
}

function varyAttributes(
  attrs: Record<string, unknown>,
  variantIdx: number,
): Record<string, unknown> {
  const next: Record<string, unknown> = { ...attrs };

  if (typeof next.area_sqm === 'number') {
    const deltas = [-15, -5, 10, 20, 30, -10];
    next.area_sqm = Math.max(40, next.area_sqm + deltas[variantIdx % deltas.length]);
  }
  if (typeof next.floor === 'number') {
    next.floor = (next.floor + variantIdx) % 8;
  }
  if (typeof next.rooms === 'number') {
    next.rooms = Math.max(1, Math.min(6, next.rooms + ((variantIdx % 3) - 1)));
  }
  if (typeof next.shoe_size === 'number') {
    next.shoe_size = 38 + ((next.shoe_size + variantIdx) % 7);
  }
  if (typeof next.year === 'number') {
    next.year = Math.min(2026, Math.max(2016, next.year + ((variantIdx % 3) - 1)));
  }
  if (typeof next.mileage === 'number') {
    next.mileage = Math.max(0, next.mileage + ((variantIdx % 5) - 2) * 8000);
  }

  return next;
}

/**
 * Expands the curated base templates to exactly `targetTotal` listings
 * distributed evenly across all 34 subcategories and all 6 sections.
 */
export function expandDemoListingsToTarget(
  baseTemplates: SeedListingTemplate[],
  targetTotal = 1000,
): SeedListingTemplate[] {
  if (baseTemplates.length >= targetTotal) {
    return baseTemplates.slice(0, targetTotal);
  }

  // Group base templates by subcategory
  const bySub = new Map<string, SeedListingTemplate[]>();
  for (const t of baseTemplates) {
    const list = bySub.get(t.subcategorySlug) || [];
    list.push(t);
    bySub.set(t.subcategorySlug, list);
  }

  const subCount = ORDERED_SUBCATEGORIES.length; // 34
  const basePerSub = Math.floor(targetTotal / subCount); // 29
  const remainder = targetTotal % subCount; // 14

  const result: SeedListingTemplate[] = [...baseTemplates];
  const priceMultipliers = [0.88, 0.94, 1.04, 1.09, 1.15, 0.91, 1.07, 1.18, 0.96, 1.12];

  ORDERED_SUBCATEGORIES.forEach((subSlug, subOrderIdx) => {
    const pool = bySub.get(subSlug) || [];
    if (pool.length === 0) return;

    const targetForSub = basePerSub + (subOrderIdx < remainder ? 1 : 0);
    const needed = Math.max(0, targetForSub - pool.length);
    const sectionSlug = SUB_TO_SECTION[subSlug] || 'real-estate';
    const sellers = SECTION_SELLERS[sectionSlug] || [pool[0].sellerAccountSlug];
    const addons =
      DESCRIPTION_ADDONS_BY_SECTION[sectionSlug] ||
      DESCRIPTION_ADDONS_BY_SECTION['real-estate'];

    for (let i = 0; i < needed; i++) {
      const source = pool[i % pool.length];
      const globalSeedIdx = subOrderIdx * 31 + i;
      const area = ALL_AREAS[(globalSeedIdx * 7 + i * 3) % ALL_AREAS.length];
      const sellerSlug = sellers[(i + subOrderIdx) % sellers.length];

      const prefixes =
        TITLE_PREFIXES_BY_KIND[source.listingKind] || TITLE_PREFIXES_BY_KIND.product;
      const prefix = prefixes[(i + subOrderIdx) % prefixes.length];

      const multiplier = priceMultipliers[(i + subOrderIdx) % priceMultipliers.length];
      const newPrice = roundNaturalPrice(source.price * multiplier);
      const addon = addons[(i + subOrderIdx) % addons.length];

      const newTitle = `${prefix}: ${source.title} - ${area.areaName} (${area.cityAr})`;
      const newDescription = `${source.description} ${addon} متاح في ${area.areaName}، ${area.cityAr}.`;

      result.push({
        subcategorySlug: subSlug,
        sellerAccountSlug: sellerSlug,
        citySlug: area.citySlug,
        areaName: area.areaName,
        title: newTitle,
        description: newDescription,
        price: newPrice,
        listingKind: source.listingKind,
        attributes: varyAttributes(source.attributes, i + 1),
        images: [...source.images],
      });
    }
  });

  return result;
}
