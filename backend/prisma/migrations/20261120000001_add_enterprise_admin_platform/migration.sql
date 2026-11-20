-- Additive non-destructive Enterprise Admin Platform migration
-- Preserves all existing marketplace tables, columns, foreign keys, and user data.

-- 1. Extend staff_roles
ALTER TABLE "staff_roles"
  ADD COLUMN IF NOT EXISTS "description" VARCHAR(255),
  ADD COLUMN IF NOT EXISTS "is_system" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- 2. Extend staff_users
ALTER TABLE "staff_users"
  ADD COLUMN IF NOT EXISTS "phone" VARCHAR(20),
  ADD COLUMN IF NOT EXISTS "department" VARCHAR(100),
  ADD COLUMN IF NOT EXISTS "job_title" VARCHAR(100),
  ADD COLUMN IF NOT EXISTS "status" VARCHAR(20) NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS "mfa_enabled" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "mfa_secret_encrypted" TEXT,
  ADD COLUMN IF NOT EXISTS "mfa_recovery_codes_hash" JSONB,
  ADD COLUMN IF NOT EXISTS "last_login_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "password_changed_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "expires_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS "staff_users_role_id_is_active_idx"
  ON "staff_users"("role_id", "is_active");

-- 3. Extend users (non-breaking moderation metadata; is_active stays synchronized)
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "moderation_status" VARCHAR(20) NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS "suspended_until" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "suspension_reason" TEXT,
  ADD COLUMN IF NOT EXISTS "banned_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "ban_reason" TEXT,
  ADD COLUMN IF NOT EXISTS "internal_notes" JSONB DEFAULT '[]'::jsonb;

-- 4. Extend reports
ALTER TABLE "reports"
  ADD COLUMN IF NOT EXISTS "priority" VARCHAR(20) NOT NULL DEFAULT 'medium',
  ADD COLUMN IF NOT EXISTS "assigned_to_staff_id" UUID,
  ADD COLUMN IF NOT EXISTS "assigned_at" TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS "internal_notes" JSONB DEFAULT '[]'::jsonb;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'reports_assigned_to_staff_id_fkey'
  ) THEN
    ALTER TABLE "reports"
      ADD CONSTRAINT "reports_assigned_to_staff_id_fkey"
      FOREIGN KEY ("assigned_to_staff_id") REFERENCES "staff_users"("id")
      ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS "reports_assigned_to_staff_id_status_idx"
  ON "reports"("assigned_to_staff_id", "status");

-- 5. Extend account_verifications
ALTER TABLE "account_verifications"
  ADD COLUMN IF NOT EXISTS "assigned_to_staff_id" UUID,
  ADD COLUMN IF NOT EXISTS "notes" TEXT;

-- 6. Extend audit_log indexes
CREATE INDEX IF NOT EXISTS "audit_log_actor_type_actor_id_created_at_idx"
  ON "audit_log"("actor_type", "actor_id", "created_at" DESC);

CREATE INDEX IF NOT EXISTS "audit_log_action_created_at_idx"
  ON "audit_log"("action", "created_at" DESC);

CREATE INDEX IF NOT EXISTS "audit_log_created_at_idx"
  ON "audit_log"("created_at" DESC);

-- 7. Create staff_sessions
CREATE TABLE IF NOT EXISTS "staff_sessions" (
  "id" UUID NOT NULL,
  "staff_id" UUID NOT NULL,
  "family_id" UUID NOT NULL,
  "refresh_token_hash" VARCHAR(255) NOT NULL,
  "ip_address" VARCHAR(50) NOT NULL,
  "user_agent" VARCHAR(500),
  "mfa_verified" BOOLEAN NOT NULL DEFAULT false,
  "is_revoked" BOOLEAN NOT NULL DEFAULT false,
  "expires_at" TIMESTAMPTZ NOT NULL,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "last_used_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "staff_sessions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "staff_sessions_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "staff_users"("id")
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "staff_sessions_staff_id_is_revoked_idx"
  ON "staff_sessions"("staff_id", "is_revoked");
CREATE INDEX IF NOT EXISTS "staff_sessions_family_id_idx"
  ON "staff_sessions"("family_id");
CREATE INDEX IF NOT EXISTS "staff_sessions_refresh_token_hash_idx"
  ON "staff_sessions"("refresh_token_hash");

-- 8. Create staff_login_attempts
CREATE TABLE IF NOT EXISTS "staff_login_attempts" (
  "id" UUID NOT NULL,
  "email" VARCHAR(255) NOT NULL,
  "staff_id" UUID,
  "ip_address" VARCHAR(50) NOT NULL,
  "user_agent" VARCHAR(500),
  "is_success" BOOLEAN NOT NULL,
  "failure_reason" VARCHAR(100),
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "staff_login_attempts_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "staff_login_attempts_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "staff_users"("id")
    ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "staff_login_attempts_email_created_at_idx"
  ON "staff_login_attempts"("email", "created_at" DESC);
CREATE INDEX IF NOT EXISTS "staff_login_attempts_staff_id_created_at_idx"
  ON "staff_login_attempts"("staff_id", "created_at" DESC);
CREATE INDEX IF NOT EXISTS "staff_login_attempts_ip_address_created_at_idx"
  ON "staff_login_attempts"("ip_address", "created_at" DESC);

-- 9. Create staff_password_resets
CREATE TABLE IF NOT EXISTS "staff_password_resets" (
  "id" UUID NOT NULL,
  "staff_id" UUID NOT NULL,
  "token_hash" VARCHAR(255) NOT NULL,
  "expires_at" TIMESTAMPTZ NOT NULL,
  "used_at" TIMESTAMPTZ,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "staff_password_resets_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "staff_password_resets_staff_id_fkey"
    FOREIGN KEY ("staff_id") REFERENCES "staff_users"("id")
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "staff_password_resets_token_hash_key"
  ON "staff_password_resets"("token_hash");
CREATE INDEX IF NOT EXISTS "staff_password_resets_staff_id_expires_at_idx"
  ON "staff_password_resets"("staff_id", "expires_at");

-- 10. Create feature_flags
CREATE TABLE IF NOT EXISTS "feature_flags" (
  "key" VARCHAR(100) NOT NULL,
  "name" VARCHAR(150) NOT NULL,
  "description" TEXT,
  "is_enabled" BOOLEAN NOT NULL DEFAULT false,
  "environment" VARCHAR(30) NOT NULL DEFAULT 'all',
  "rollout_percentage" INTEGER NOT NULL DEFAULT 100,
  "rules" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "is_system" BOOLEAN NOT NULL DEFAULT false,
  "updated_by_staff_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "feature_flags_pkey" PRIMARY KEY ("key")
);

-- 11. Create cms_items
CREATE TABLE IF NOT EXISTS "cms_items" (
  "id" UUID NOT NULL,
  "type" VARCHAR(30) NOT NULL,
  "slug" VARCHAR(150) NOT NULL,
  "title_ar" VARCHAR(255) NOT NULL,
  "title_en" VARCHAR(255) NOT NULL,
  "body_ar" TEXT,
  "body_en" TEXT,
  "image_url" VARCHAR(500),
  "target_url" VARCHAR(500),
  "placement" VARCHAR(50),
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "status" VARCHAR(20) NOT NULL DEFAULT 'draft',
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "starts_at" TIMESTAMPTZ,
  "ends_at" TIMESTAMPTZ,
  "revisions" JSONB NOT NULL DEFAULT '[]'::jsonb,
  "updated_by_staff_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "cms_items_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "cms_items_slug_key"
  ON "cms_items"("slug");
CREATE INDEX IF NOT EXISTS "cms_items_type_status_is_active_sort_order_idx"
  ON "cms_items"("type", "status", "is_active", "sort_order");

-- 12. Create notification_campaigns
CREATE TABLE IF NOT EXISTS "notification_campaigns" (
  "id" UUID NOT NULL,
  "title_ar" VARCHAR(200) NOT NULL,
  "title_en" VARCHAR(200) NOT NULL,
  "body_ar" TEXT NOT NULL,
  "body_en" TEXT NOT NULL,
  "audience_type" VARCHAR(30) NOT NULL DEFAULT 'all',
  "audience_filter" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "status" VARCHAR(30) NOT NULL DEFAULT 'draft',
  "scheduled_at" TIMESTAMPTZ,
  "sent_at" TIMESTAMPTZ,
  "estimated_recipients" INTEGER NOT NULL DEFAULT 0,
  "sent_count" INTEGER NOT NULL DEFAULT 0,
  "delivered_count" INTEGER NOT NULL DEFAULT 0,
  "failed_count" INTEGER NOT NULL DEFAULT 0,
  "created_by_staff_id" UUID,
  "approved_by_staff_id" UUID,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "notification_campaigns_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "notification_campaigns_status_created_at_idx"
  ON "notification_campaigns"("status", "created_at" DESC);
