-- M15 Constraint Versioning — NON-PRODUCTION ONLY
-- Safety boundary: disposable PostgreSQL only; no production credentials,
-- endpoints, schemas, data, infrastructure, or CURRENT-STATE mutation.
-- Requires explicit session marker: paz.m15_nonprod=true.
-- M14 remains the sole human approval boundary.

BEGIN;

-- F0 — fail closed before schema mutation.
DO $$
BEGIN
  IF current_setting('paz.m15_nonprod', true) <> 'true' THEN
    RAISE EXCEPTION 'M15 migration BLOCKED: non-production session marker missing';
  END IF;
  IF lower(coalesce(current_setting('paz.environment', true), '')) IN ('prod', 'production') THEN
    RAISE EXCEPTION 'M15 migration BLOCKED: production environment marker detected';
  END IF;
END;
$$;

-- F1 — canonical M15 version ledger.
CREATE SCHEMA IF NOT EXISTS governance;

CREATE TABLE IF NOT EXISTS governance.constraint_versions (
  version text PRIMARY KEY,
  scope text NOT NULL,
  idempotency_key text NOT NULL UNIQUE,
  provenance_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  created_by text NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  source_version text,
  target_version text,
  CHECK (version ~ '^v[0-9]+$'),
  CHECK (length(trim(scope)) > 0),
  CHECK (length(trim(idempotency_key)) > 0),
  CHECK (length(trim(provenance_hash)) >= 16),
  CHECK (length(trim(created_by)) > 0),
  CHECK (status IN ('ACTIVE', 'SUPERSEDED', 'ROLLED_BACK')),
  CHECK ((source_version IS NULL AND target_version IS NULL)
      OR (source_version ~ '^v[0-9]+$' AND target_version ~ '^v[0-9]+$'))
);

INSERT INTO governance.constraint_versions
  (version, scope, idempotency_key, provenance_hash, created_by, status)
VALUES
  ('v1', 'M15_TEST', 'm15-bootstrap-v1', repeat('0', 64), 'NON_HUMAN_TEST_ACTOR', 'ACTIVE')
ON CONFLICT (version) DO NOTHING;

-- F2 — canonical apply function.
-- created_by is provenance only, never approval authority.
-- SECURITY INVOKER preserves the M14 authority boundary.
CREATE OR REPLACE FUNCTION governance.apply_constraint_version(
  p_version text,
  p_scope text,
  p_idempotency_key text,
  p_provenance_hash text,
  p_actor text
)
RETURNS text
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_current text;
  v_existing_version text;
  v_existing_scope text;
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
  IF p_actor IS NULL OR trim(p_actor) = '' THEN
    RAISE EXCEPTION 'M15 actor/provenance identity required';
  END IF;

  SELECT version, scope INTO v_existing_version, v_existing_scope
  FROM governance.constraint_versions
  WHERE idempotency_key = p_idempotency_key;

  IF v_existing_version IS NOT NULL THEN
    IF v_existing_version <> p_version OR v_existing_scope <> p_scope THEN
      RAISE EXCEPTION 'M15 idempotency/scope/version substitution detected';
    END IF;
    RETURN v_existing_version;
  END IF;

  SELECT version INTO v_current
  FROM governance.constraint_versions
  WHERE status = 'ACTIVE'
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_current IS NULL THEN
    RAISE EXCEPTION 'M15 BLOCKED: no active constraint version';
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

  UPDATE governance.constraint_versions
  SET status = 'SUPERSEDED'
  WHERE version = v_current AND status = 'ACTIVE';

  INSERT INTO governance.constraint_versions
    (version, scope, idempotency_key, provenance_hash, created_by,
     status, source_version, target_version)
  VALUES
    (p_version, p_scope, p_idempotency_key, p_provenance_hash, p_actor,
     'ACTIVE', v_current, p_version);

  RETURN p_version;
END;
$$;

-- No role grants are created. No production roles or M14 approval records
-- are touched. This migration is intentionally non-production only.

COMMIT;
