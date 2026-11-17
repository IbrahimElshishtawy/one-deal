-- Enable pg_trgm for fast Arabic & partial text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Enable pg_stat_statements if permitted by Postgres superuser / shared_preload_libraries
-- (Safe to run only if installed on host; wrapped in DO block so managed DBs without preload don't fail)
DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_stat_statements extension skipped: %', SQLERRM;
END $$;

-- Trigram GIN indexes for Arabic normalized text and listing title/description
CREATE INDEX IF NOT EXISTS "idx_listings_search_norm_trgm"
  ON "listings" USING GIN ("search_normalized_text" gin_trgm_ops);

CREATE INDEX IF NOT EXISTS "idx_listings_title_trgm"
  ON "listings" USING GIN ("title" gin_trgm_ops);

-- Targeted B-tree expression indexes for high-frequency JSONB attribute filters
CREATE INDEX IF NOT EXISTS "idx_listings_attr_rooms"
  ON "listings" (((attributes->>'rooms')::int))
  WHERE (attributes ? 'rooms');

CREATE INDEX IF NOT EXISTS "idx_listings_attr_baths"
  ON "listings" (((attributes->>'baths')::int))
  WHERE (attributes ? 'baths');

CREATE INDEX IF NOT EXISTS "idx_listings_attr_year"
  ON "listings" (((attributes->>'year')::int))
  WHERE (attributes ? 'year');

CREATE INDEX IF NOT EXISTS "idx_listings_attr_brand"
  ON "listings" ((attributes->>'brand'))
  WHERE (attributes ? 'brand');

CREATE INDEX IF NOT EXISTS "idx_listings_attr_make"
  ON "listings" ((attributes->>'make'))
  WHERE (attributes ? 'make');

CREATE INDEX IF NOT EXISTS "idx_listings_attr_model"
  ON "listings" ((attributes->>'model'))
  WHERE (attributes ? 'model');

CREATE INDEX IF NOT EXISTS "idx_listings_attr_transmission"
  ON "listings" ((attributes->>'transmission'))
  WHERE (attributes ? 'transmission');

CREATE INDEX IF NOT EXISTS "idx_listings_attr_fuel_type"
  ON "listings" ((attributes->>'fuel_type'))
  WHERE (attributes ? 'fuel_type');

CREATE INDEX IF NOT EXISTS "idx_listings_attr_finishing"
  ON "listings" ((attributes->>'finishing'))
  WHERE (attributes ? 'finishing');

CREATE INDEX IF NOT EXISTS "idx_listings_attr_unit_type"
  ON "listings" ((attributes->>'unit_type'))
  WHERE (attributes ? 'unit_type');

-- Partial index for active public feed & promotion sorting
CREATE INDEX IF NOT EXISTS "idx_listings_public_feed_active"
  ON "listings" ("promoted_until" DESC NULLS LAST, "refreshed_at" DESC)
  WHERE "publication_status" = 'published' AND "deleted_at" IS NULL;
