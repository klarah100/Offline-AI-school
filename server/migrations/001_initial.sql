CREATE TABLE IF NOT EXISTS organizations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('school_group','ngo','government','corporate','other')),
  billing_email TEXT,
  subscription_status TEXT NOT NULL DEFAULT 'trial'
    CHECK (subscription_status IN ('trial','active','past_due','cancelled')),
  plan_code TEXT,
  learner_limit INTEGER NOT NULL DEFAULT 0 CHECK (learner_limit >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS schools (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  organization_id TEXT REFERENCES organizations(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('learner','teacher','admin')),
  school_id TEXT REFERENCES schools(id) ON DELETE SET NULL,
  organization_id TEXT REFERENCES organizations(id) ON DELETE SET NULL,
  learner_id TEXT UNIQUE,
  grade TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS attempts (
  id BIGSERIAL PRIMARY KEY,
  client_id TEXT NOT NULL UNIQUE,
  learner_id TEXT NOT NULL,
  question_id TEXT NOT NULL,
  topic_id TEXT NOT NULL,
  correct BOOLEAN NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  attempt_type TEXT NOT NULL CHECK (attempt_type IN ('diagnostic','practice')),
  selected_answer TEXT,
  duration_ms INTEGER,
  difficulty SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 3),
  server_received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscription_plans (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  interval TEXT NOT NULL CHECK (interval IN ('monthly','annual','custom')),
  price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
  currency TEXT NOT NULL DEFAULT 'USD',
  learner_limit INTEGER NOT NULL CHECK (learner_limit > 0),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  plan_code TEXT NOT NULL REFERENCES subscription_plans(code),
  status TEXT NOT NULL CHECK (status IN ('trial','active','past_due','cancelled','expired')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  current_period_end TIMESTAMPTZ,
  external_customer_id TEXT,
  external_subscription_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organization_licenses (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ends_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active','expired','cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS billing_events (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  amount_cents INTEGER,
  currency TEXT NOT NULL DEFAULT 'USD',
  reference TEXT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_school_role ON users(school_id, role);
CREATE INDEX IF NOT EXISTS idx_users_org_role ON users(organization_id, role);
CREATE INDEX IF NOT EXISTS idx_attempts_learner_topic_time ON attempts(learner_id, topic_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_attempts_learner_type ON attempts(learner_id, attempt_type);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_schools_org ON schools(organization_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_org_status ON subscriptions(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_licenses_org_status ON organization_licenses(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_billing_events_org_time ON billing_events(organization_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_time ON audit_logs(user_id, created_at);

CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS users_touch_updated_at ON users;
CREATE TRIGGER users_touch_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS organizations_touch_updated_at ON organizations;
CREATE TRIGGER organizations_touch_updated_at
BEFORE UPDATE ON organizations
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS subscriptions_touch_updated_at ON subscriptions;
CREATE TRIGGER subscriptions_touch_updated_at
BEFORE UPDATE ON subscriptions
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_anon_organizations ON organizations;
DROP POLICY IF EXISTS deny_auth_organizations ON organizations;
CREATE POLICY deny_anon_organizations ON organizations FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_organizations ON organizations FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_anon_schools ON schools;
DROP POLICY IF EXISTS deny_auth_schools ON schools;
CREATE POLICY deny_anon_schools ON schools FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_schools ON schools FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_anon_users ON users;
DROP POLICY IF EXISTS deny_auth_users ON users;
CREATE POLICY deny_anon_users ON users FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_users ON users FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_anon_refresh_tokens ON refresh_tokens;
DROP POLICY IF EXISTS deny_auth_refresh_tokens ON refresh_tokens;
CREATE POLICY deny_anon_refresh_tokens ON refresh_tokens FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_refresh_tokens ON refresh_tokens FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_anon_attempts ON attempts;
DROP POLICY IF EXISTS deny_auth_attempts ON attempts;
CREATE POLICY deny_anon_attempts ON attempts FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_attempts ON attempts FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_anon_subscription_plans ON subscription_plans;
DROP POLICY IF EXISTS deny_auth_subscription_plans ON subscription_plans;
CREATE POLICY deny_anon_subscription_plans ON subscription_plans FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_subscription_plans ON subscription_plans FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_anon_subscriptions ON subscriptions;
DROP POLICY IF EXISTS deny_auth_subscriptions ON subscriptions;
CREATE POLICY deny_anon_subscriptions ON subscriptions FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_subscriptions ON subscriptions FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_anon_organization_licenses ON organization_licenses;
DROP POLICY IF EXISTS deny_auth_organization_licenses ON organization_licenses;
CREATE POLICY deny_anon_organization_licenses ON organization_licenses FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_organization_licenses ON organization_licenses FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_anon_billing_events ON billing_events;
DROP POLICY IF EXISTS deny_auth_billing_events ON billing_events;
CREATE POLICY deny_anon_billing_events ON billing_events FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_billing_events ON billing_events FOR ALL TO authenticated USING (false) WITH CHECK (false);

DROP POLICY IF EXISTS deny_anon_audit_logs ON audit_logs;
DROP POLICY IF EXISTS deny_auth_audit_logs ON audit_logs;
CREATE POLICY deny_anon_audit_logs ON audit_logs FOR ALL TO anon USING (false) WITH CHECK (false);
CREATE POLICY deny_auth_audit_logs ON audit_logs FOR ALL TO authenticated USING (false) WITH CHECK (false);

INSERT INTO subscription_plans(code,name,description,interval,price_cents,currency,learner_limit)
VALUES
  ('school_small','Small School','Up to 100 learners','annual',30000,'USD',100),
  ('school_medium','Medium School','Up to 300 learners','annual',75000,'USD',300),
  ('school_large','Large School','Up to 1000 learners','annual',200000,'USD',1000),
  ('institution_custom','Institutional','Custom deployment and licensing','custom',0,'USD',1)
ON CONFLICT (code) DO NOTHING;
