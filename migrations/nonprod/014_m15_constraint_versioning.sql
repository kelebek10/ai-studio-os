-- M15 Constraint Versioning — NON-PRODUCTION ONLY
-- Production migration / production execution: BLOCKED.
-- M14 approval authority is not implemented or replaced here.

BEGIN;

-- F0: fail closed before schema mutation.
DO $$
BEGIN
  IF current_setting('paz.m15_nonprod', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'M15 BLOCKED: non-production session marker missing';
  END IF;
  IF lower(coalesce(current_setting('paz.environment', true), '')) IN ('prod','production') THEN
    RAISE EXCEPTION 'M15 BLOCKED: production environment marker detected';
  END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS governance;

-- F1: immutable audit ledger for applied constraint versions.
CREATE TABLE governance.constraint_versions (
  version text NOT NULL,
  scope text NOT NULL,
  idempotency_key text NOT NULL,
  provenance_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  created_by text NOT NULL,
  status text NOT NULL,
  source_version text,
  target_version text,
  CONSTRAINT constraint_versions_pk PRIMARY KEY (scope, version, idempotency_key),
  CONSTRAINT constraint_versions_scope_idempotency_uq UNIQUE (scope, idempotency_key),
  CONSTRAINT constraint_versions_status_ck CHECK (status IN ('ACTIVE','SUPERSEDED','ROLLED_BACK')),
  CONSTRAINT constraint_versions_nonempty_ck CHECK (
    length(trim(version)) > 0 AND
    length(trim(scope)) > 0 AND
    length(trim(idempotency_key)) > 0 AND
    length(trim(provenance_hash)) >= 16 AND
    length(trim(created_by)) > 0
  )
);

-- F2: controlled test catalog. v1 is the initial state; v2 is the only
-- supported forward transition in this non-production M15 fixture.
CREATE TABLE governance.constraint_version_catalog (
  version text PRIMARY KEY,
  scope text NOT NULL,
  status text NOT NULL DEFAULT 'APPLICABLE',
  CONSTRAINT constraint_version_catalog_status_ck CHECK (status IN ('APPLICABLE','RETIRED'))
);

INSERT INTO governance.constraint_version_catalog(version, scope)
VALUES ('v1','M15_TEST'), ('v2','M15_TEST');

INSERT INTO governance.constraint_versions
  (version, scope, idempotency_key, provenance_hash, created_by, status, source_version, target_version)
VALUES
  ('v1','M15_TEST','m15-bootstrap-v1',repeat('0',64),'M15_NONPROD_TEST','ACTIVE','v1','v1');

-- F3: canonical apply interface. SECURITY INVOKER is intentional.
-- p_actor is provenance only; it is NOT approval authority and cannot create
-- or infer M14/HUMAN_APPROVER authorization.
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
  v_existing text;
  v_catalog_scope text;
BEGIN
  IF current_setting('paz.m15_nonprod', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'M15 BLOCKED: non-production session marker missing';
  END IF;

  IF p_version IS NULL OR trim(p_version) = '' THEN
    RAISE EXCEPTION 'M15 BLOCKED: version missing';
  END IF;
  IF p_scope IS NULL OR trim(p_scope) = '' THEN
    RAISE EXCEPTION 'M15 BLOCKED: scope missing';
  END IF;
  IF p_idempotency_key IS NULL OR trim(p_idempotency_key) = '' THEN
    RAISE EXCEPTION 'M15 BLOCKED: idempotency key missing';
  END IF;
  IF p_provenance_hash IS NULL OR length(trim(p_provenance_hash)) < 16 THEN
    RAISE EXCEPTION 'M15 BLOCKED: provenance missing';
  END IF;
  IF p_actor IS NULL OR trim(p_actor) = '' THEN
    RAISE EXCEPTION 'M15 BLOCKED: authority context/provenance actor missing';
  END IF;

  SELECT scope INTO v_catalog_scope
  FROM governance.constraint_version_catalog
  WHERE version = p_version AND status = 'APPLICABLE';

  IF v_catalog_scope IS NULL THEN
    RAISE EXCEPTION 'M15 BLOCKED: unknown or retired version';
  END IF;
  IF v_catalog_scope <> p_scope THEN
    RAISE EXCEPTION 'M15 BLOCKED: unauthorized scope substitution';
  END IF;

  SELECT version INTO v_existing
  FROM governance.constraint_versions
  WHERE scope = p_scope AND idempotency_key = p_idempotency_key;

  IF v_existing IS NOT NULL THEN
    IF v_existing <> p_version THEN
      RAISE EXCEPTION 'M15 BLOCKED: idempotency/version substitution';
    END IF;
    RETURN v_existing;
  END IF;

  SELECT version INTO v_current
  FROM governance.constraint_versions
  WHERE scope = p_scope AND status = 'ACTIVE'
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_current IS NULL THEN
    RAISE EXCEPTION 'M15 BLOCKED: current version unknown';
  END IF;

  IF p_version = v_current THEN
    RETURN v_current;
  END IF;

  IF NOT (v_current = 'v1' AND p_version = 'v2') THEN
    RAISE EXCEPTION 'M15 BLOCKED: unsupported version transition';
  END IF;

  UPDATE governance.constraint_versions
  SET status = 'SUPERSEDED'
  WHERE scope = p_scope AND version = v_current AND status = 'ACTIVE';

  INSERT INTO governance.constraint_versions
    (version, scope, idempotency_key, provenance_hash, created_by, status, source_version, target_version)
  VALUES
    (p_version, p_scope, p_idempotency_key, p_provenance_hash, p_actor, 'ACTIVE', v_current, p_version);

  RETURN p_version;
END;
$$;

-- No production roles, grants, credentials, or approval records are created.
-- No CURRENT-STATE mutation occurs.

COMMIT;
