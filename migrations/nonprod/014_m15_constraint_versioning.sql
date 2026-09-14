-- M15 Constraint Versioning — NON-PRODUCTION ONLY
-- Safety boundary:
--   * Disposable PostgreSQL test database only.
--   * No production connection, credentials, schemas, or environment lookup.
--   * This migration intentionally refuses to run unless the session explicitly
--     identifies itself as the M15 disposable test context.
--   * This file is NOT a production migration and MUST NOT be promoted directly.
--
-- M14 boundary:
--   * No approval state is created here.
--   * No CURRENT-STATE mutation is performed here.
--   * Human approval remains exclusively under the M14 approval boundary.

BEGIN;

-- ---------------------------------------------------------------------------
-- F0 — Fail-closed execution guard
-- ---------------------------------------------------------------------------
-- The test harness must explicitly set this session-local marker.
-- A missing marker aborts the migration before any schema mutation.
SELECT CASE
  WHEN current_setting('paz.m15_nonprod', true) = 'true'
    THEN true
  ELSE pg_catalog.raise_exception('M15 migration BLOCKED: non-production session marker missing')
END;

-- Reject sessions that look production-like by convention.
SELECT CASE
  WHEN lower(coalesce(current_setting('paz.environment', true), '')) IN ('prod', 'production')
    THEN pg_catalog.raise_exception('M15 migration BLOCKED: production environment marker detected')
  ELSE true
END;

-- ---------------------------------------------------------------------------
-- F1 — Canonical version state
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS m15_constraint_versions (
  version text PRIMARY KEY,
  scope text NOT NULL,
  idempotency_key text NOT NULL UNIQUE,
  provenance_hash text NOT NULL,
  state text NOT NULL DEFAULT 'ACTIVE',
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  CHECK (version ~ '^v[0-9]+$'),
  CHECK (length(trim(scope)) > 0),
  CHECK (length(trim(idempotency_key)) > 0),
  CHECK (length(trim(provenance_hash)) >= 16),
  CHECK (state IN ('ACTIVE', 'SUPERSEDED', 'ROLLED_BACK'))
);

-- The initial controlled test version is deterministic and disposable.
INSERT INTO m15_constraint_versions
  (version, scope, idempotency_key, provenance_hash, state)
VALUES
  ('v1', 'M15_TEST', 'm15-bootstrap-v1', repeat('0', 64), 'ACTIVE')
ON CONFLICT (version) DO NOTHING;

-- ---------------------------------------------------------------------------
-- F2 — Canonical apply function
-- ---------------------------------------------------------------------------
-- SECURITY INVOKER is deliberate. This function does not create authority and
-- cannot substitute for the M14 approval boundary.
CREATE OR REPLACE FUNCTION m15_apply_constraint_version(
  p_version text,
  p_scope text,
  p_idempotency_key text,
  p_provenance_hash text,
  p_expected_current_version text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_current text;
  v_existing text;
BEGIN
  IF current_setting('paz.m15_nonprod', true) <> 'true' THEN
    RAISE EXCEPTION 'M15 BLOCKED: non-production session marker missing';
  END IF;

  IF p_version IS NULL OR p_version !~ '^v[0-9]+$' THEN
    RAISE EXCEPTION 'M15 invalid constraint version';
  END IF;

  IF p_scope IS NULL OR trim(p_scope) = '' THEN
    RAISE EXCEPTION 'M15 invalid scope';
  END IF;

  IF p_idempotency_key IS NULL OR trim(p_idempotency_key) = '' THEN
    RAISE EXCEPTION 'M15 idempotency key required';
  END IF;

  IF p_provenance_hash IS NULL OR length(trim(p_provenance_hash)) < 16 THEN
    RAISE EXCEPTION 'M15 provenance hash required';
  END IF;

  SELECT version INTO v_existing
  FROM m15_constraint_versions
  WHERE idempotency_key = p_idempotency_key;

  IF v_existing IS NOT NULL THEN
    IF v_existing <> p_version THEN
      RAISE EXCEPTION 'M15 idempotency/scope substitution detected';
    END IF;
    RETURN v_existing;
  END IF;

  SELECT version INTO v_current
  FROM m15_constraint_versions
  WHERE state = 'ACTIVE'
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_current IS NULL THEN
    RAISE EXCEPTION 'M15 BLOCKED: no active constraint version';
  END IF;

  IF p_expected_current_version IS NOT NULL
     AND p_expected_current_version <> v_current THEN
    RAISE EXCEPTION 'M15 concurrent/version conflict';
  END IF;

  IF p_scope <> 'M15_TEST' THEN
    RAISE EXCEPTION 'M15 unauthorized scope';
  END IF;

  IF p_version = v_current THEN
    RETURN v_current;
  END IF;

  IF ('v' || ((substring(v_current from 2))::integer + 1)) <> p_version THEN
    RAISE EXCEPTION 'M15 unsupported version transition';
  END IF;

  UPDATE m15_constraint_versions
  SET state = 'SUPERSEDED'
  WHERE version = v_current
    AND state = 'ACTIVE';

  INSERT INTO m15_constraint_versions
    (version, scope, idempotency_key, provenance_hash, state)
  VALUES
    (p_version, p_scope, p_idempotency_key, p_provenance_hash, 'ACTIVE');

  RETURN p_version;
END;
$$;

-- ---------------------------------------------------------------------------
-- F3 — Explicit test-only permission surface
-- ---------------------------------------------------------------------------
-- No role grants are created here. The disposable test owner executes the
-- migration. Production roles are intentionally untouched.

COMMIT;
