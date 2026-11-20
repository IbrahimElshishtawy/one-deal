const BASE_URL = process.env.E2E_BASE_URL || 'http://localhost:3000/api/v1';
const ROOT_URL = BASE_URL.replace('/api/v1', '');

async function req(
  method: string,
  url: string,
  opts: { token?: string; body?: unknown } = {},
) {
  const headers: Record<string, string> = {};
  if (opts.body !== undefined) headers['Content-Type'] = 'application/json';
  if (opts.token) headers['Authorization'] = `Bearer ${opts.token}`;
  const res = await fetch(url, {
    method,
    headers,
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
  });
  const text = await res.text();
  let json: any = null;
  try {
    json = JSON.parse(text);
  } catch {
    json = text;
  }
  return { status: res.status, json, headers: res.headers };
}

describe('Deal One Complete Backend Modules, RBAC & Error-Handling Audit (Live E2E)', () => {
  let token = '';
  let refreshToken = '';
  let accountId = '';
  let sampleListingId = '';

  beforeAll(async () => {
    const auth = await req('POST', `${BASE_URL}/auth/dev-guest`, { body: {} });
    expect(auth.status).toBe(200);
    token = auth.json.data.tokens.accessToken;
    refreshToken = auth.json.data.tokens.refreshToken;
    accountId = auth.json.data.activeAccount.id;
  });

  it('1. Health & OpenAPI Swagger probes work cleanly', async () => {
    const live = await req('GET', `${ROOT_URL}/health/live`);
    expect(live.status).toBe(200);
    expect(live.json.data.status).toBe('ok');

    const ready = await req('GET', `${ROOT_URL}/health/ready`);
    expect(ready.status).toBe(200);
    expect(ready.json.data.status).toBe('healthy');
    expect(ready.json.data.checks.database).toBe('up');
    expect(ready.json.data.checks.redis_cache).toBe('up');
    expect(ready.json.data.checks.redis_queue).toBe('up');

    const docs = await req('GET', `${ROOT_URL}/api/docs-json`);
    expect(docs.status).toBe(200);
    expect(Object.keys(docs.json.paths || {}).length).toBeGreaterThan(50);
  });

  it('2. Auth, Sessions & Token Rotation work securely', async () => {
    const me = await req('GET', `${BASE_URL}/auth/me`, { token });
    expect(me.status).toBe(200);
    expect(me.json.data.role).toBe('USER');

    const sessions = await req('GET', `${BASE_URL}/auth/sessions`, { token });
    expect(sessions.status).toBe(200);
    expect(Array.isArray(sessions.json.data)).toBe(true);

    // Token rotation
    const rotated = await req('POST', `${BASE_URL}/auth/refresh`, {
      body: { refreshToken },
    });
    expect(rotated.status).toBe(200);
    expect(rotated.json.data.accessToken).toBeTruthy();
    token = rotated.json.data.accessToken;

    // Invalid refresh token rejected
    const badRefresh = await req('POST', `${BASE_URL}/auth/refresh`, {
      body: { refreshToken: 'invalid_token_xyz_123' },
    });
    expect(badRefresh.status).toBe(401);
  });

  it('3. Users & Accounts & Locations modules return valid contracts', async () => {
    const profile = await req('GET', `${BASE_URL}/users/me`, { token });
    expect(profile.status).toBe(200);
    expect(profile.json.data.fullName).toBeTruthy();

    const accounts = await req('GET', `${BASE_URL}/accounts/my-accounts`, { token });
    expect(accounts.status).toBe(200);
    expect(accounts.json.data.length).toBeGreaterThan(0);

    const accDetail = await req('GET', `${BASE_URL}/accounts/${accountId}`, { token });
    expect(accDetail.status).toBe(200);

    const govs = await req('GET', `${BASE_URL}/locations/governorates`);
    expect(govs.status).toBe(200);
    expect(govs.json.data.length).toBeGreaterThanOrEqual(10);
    const firstCityId = govs.json.data[0]?.cities?.[0]?.id;
    if (firstCityId) {
      const areas = await req('GET', `${BASE_URL}/locations/cities/${firstCityId}/areas`);
      expect(areas.status).toBe(200);
    }
  });

  it('4. Categories, Dynamic Fields, Home Hub, Section Home, Listings & Batch Prices', async () => {
    const cats = await req('GET', `${BASE_URL}/categories`);
    expect(cats.status).toBe(200);
    expect(cats.json.data.length).toBeGreaterThanOrEqual(6);

    const fields = await req('GET', `${BASE_URL}/categories/apartments-for-sale/fields`);
    expect(fields.status).toBe(200);
    expect(fields.json.data.length).toBeGreaterThan(0);

    const sectionHome = await req('GET', `${BASE_URL}/home/sections/real-estate`);
    expect(sectionHome.status).toBe(200);

    const listings = await req('GET', `${BASE_URL}/listings?limit=5`);
    expect(listings.status).toBe(200);
    expect(listings.json.data.length).toBe(5);
    sampleListingId = listings.json.data[0].id;

    const batchPrices = await req('POST', `${BASE_URL}/listings/prices/batch`, {
      body: { ids: [sampleListingId] },
    });
    expect(batchPrices.status).toBe(200);
    expect(batchPrices.json.data.items).toHaveLength(1);

    const suggestions = await req(
      'GET',
      `${BASE_URL}/search/suggestions?q=${encodeURIComponent('شقة')}`,
    );
    expect(suggestions.status).toBe(200);
  });

  it('5. Favorites, Chat, Notifications, Quotas & Video Feed modules work', async () => {
    const favs = await req('GET', `${BASE_URL}/favorites`, { token });
    expect(favs.status).toBe(200);

    const addFav = await req('POST', `${BASE_URL}/favorites/${sampleListingId}`, { token });
    expect([200, 201]).toContain(addFav.status);

    const delFav = await req('DELETE', `${BASE_URL}/favorites/${sampleListingId}`, { token });
    expect(delFav.status).toBe(200);

    const convs = await req('GET', `${BASE_URL}/conversations`, { token });
    expect(convs.status).toBe(200);

    const notifs = await req('GET', `${BASE_URL}/notifications`, { token });
    expect(notifs.status).toBe(200);

    const quotas = await req('GET', `${BASE_URL}/quotas/my-usage`, { token });
    expect(quotas.status).toBe(200);

    const videos = await req('GET', `${BASE_URL}/video-feed`);
    expect(videos.status).toBe(200);
  });

  it('6. RBAC Admin Protection blocks standard USER token (403 Forbidden)', async () => {
    const modListings = await req('GET', `${BASE_URL}/admin/moderation/listings`, { token });
    expect(modListings.status).toBe(403);

    const settings = await req('GET', `${BASE_URL}/admin/settings`, { token });
    expect(settings.status).toBe(403);

    const staff = await req('GET', `${BASE_URL}/admin/staff`, { token });
    expect(staff.status).toBe(403);
  });

  it('7. Centralized Error Handling (400 Invalid UUID, 400 Malformed JSON filter, 404, Trace ID)', async () => {
    const badUuid = await req('GET', `${BASE_URL}/listings/not-a-valid-uuid`);
    expect(badUuid.status).toBe(400);
    expect(badUuid.json.success).toBe(false);
    expect(badUuid.json.error.code).toBe('INVALID_IDENTIFIER');
    expect(badUuid.json.error.trace_id).toBeTruthy();

    const badAttrs = await req('GET', `${BASE_URL}/search?attributes={malformed_json`);
    expect(badAttrs.status).toBe(400);
    expect(badAttrs.json.success).toBe(false);

    const notFound = await req('GET', `${BASE_URL}/route-does-not-exist-xyz`);
    expect(notFound.status).toBe(404);
    expect(notFound.json.error.trace_id).toBeTruthy();
  });
});
