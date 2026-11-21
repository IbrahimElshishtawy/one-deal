/**
 * Known dead or removed external image IDs mapped to verified 200 OK replacements.
 */
const BROKEN_IMAGE_REPLACEMENTS: Array<{
  pattern: string;
  replacement: string;
}> = [
  {
    pattern: 'photo-1486006920555-c77dce18193b',
    replacement: 'photo-1492144534655-ae79c964c9d7',
  },
  {
    pattern: 'photo-1502005229762-ee1b4458f4ff',
    replacement: 'photo-1512917774080-9991f1c4c750',
  },
  {
    pattern: 'photo-1504917599217-d4dc5ebe6122',
    replacement: 'photo-1504307651254-35680f356dfd',
  },
  {
    pattern: 'photo-1542272604-780c96856592',
    replacement: 'photo-1541099649105-f69ad21f3246',
  },
  {
    pattern: 'photo-1584463699028-56837e3d1b72',
    replacement: 'photo-1513506003901-1e6a229e2d15',
  },
  {
    pattern: 'photo-1586191582056-a60d66826645',
    replacement: 'photo-1503376780353-7e6692767b70',
  },
];

const CATEGORY_FALLBACK_IMAGES: Record<string, string> = {
  'real-estate':
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
  'home-appliances':
    'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80',
  services:
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=800&q=80',
  'building-materials':
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=800&q=80',
  cars: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=800&q=80',
  fashion:
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80',
  default:
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
};

const DEFAULT_AVATAR_URL =
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';

export function resolveFallbackImageForCategory(
  categorySlug?: string | null,
): string {
  if (!categorySlug) return CATEGORY_FALLBACK_IMAGES.default;
  const slug = categorySlug.toLowerCase();
  if (
    slug.includes('real-estate') ||
    slug.includes('apartment') ||
    slug.includes('villa') ||
    slug.includes('land') ||
    slug.includes('commercial')
  ) {
    return CATEGORY_FALLBACK_IMAGES['real-estate'];
  }
  if (
    slug.includes('appliance') ||
    slug.includes('furniture') ||
    slug.includes('decor') ||
    slug.includes('kitchen')
  ) {
    return CATEGORY_FALLBACK_IMAGES['home-appliances'];
  }
  if (
    slug.includes('service') ||
    slug.includes('finishing') ||
    slug.includes('maintenance') ||
    slug.includes('moving')
  ) {
    return CATEGORY_FALLBACK_IMAGES.services;
  }
  if (
    slug.includes('building') ||
    slug.includes('steel') ||
    slug.includes('cement') ||
    slug.includes('paint') ||
    slug.includes('plumbing') ||
    slug.includes('electric')
  ) {
    return CATEGORY_FALLBACK_IMAGES['building-materials'];
  }
  if (slug.includes('car') || slug.includes('auto') || slug.includes('motor')) {
    return CATEGORY_FALLBACK_IMAGES.cars;
  }
  if (
    slug.includes('fashion') ||
    slug.includes('wear') ||
    slug.includes('shoe') ||
    slug.includes('watch')
  ) {
    return CATEGORY_FALLBACK_IMAGES.fashion;
  }
  return CATEGORY_FALLBACK_IMAGES[slug] ?? CATEGORY_FALLBACK_IMAGES.default;
}

export function sanitizeImageUrl(
  rawUrl?: string | null,
  categorySlug?: string | null,
): string {
  if (!rawUrl || typeof rawUrl !== 'string' || rawUrl.trim().length === 0) {
    return resolveFallbackImageForCategory(categorySlug);
  }
  let url = rawUrl.trim();
  for (const rule of BROKEN_IMAGE_REPLACEMENTS) {
    if (url.includes(rule.pattern)) {
      url = url.replace(rule.pattern, rule.replacement);
    }
  }
  return url;
}

export function sanitizeAvatarUrl(
  rawUrl?: string | null,
  categorySlug?: string | null,
): string {
  if (!rawUrl || typeof rawUrl !== 'string' || rawUrl.trim().length === 0) {
    return categorySlug
      ? resolveFallbackImageForCategory(categorySlug)
      : DEFAULT_AVATAR_URL;
  }
  return sanitizeImageUrl(rawUrl, categorySlug);
}

export function sanitizeMediaList(
  media: any[] | null | undefined,
  categorySlug?: string | null,
): any[] {
  if (!Array.isArray(media) || media.length === 0) {
    const fallback = resolveFallbackImageForCategory(categorySlug);
    return [
      {
        id: 'fallback-media-0',
        mediaType: 'image',
        publicUrl: fallback,
        thumbnailUrl: fallback,
        sortOrder: 0,
      },
    ];
  }
  return media.map((m, idx) => {
    const publicUrl = sanitizeImageUrl(m?.publicUrl ?? m?.url, categorySlug);
    const thumbnailUrl = sanitizeImageUrl(
      m?.thumbnailUrl ?? publicUrl,
      categorySlug,
    );
    return {
      ...m,
      id: m?.id ?? `media-${idx}`,
      mediaType: m?.mediaType ?? 'image',
      publicUrl,
      thumbnailUrl,
    };
  });
}
