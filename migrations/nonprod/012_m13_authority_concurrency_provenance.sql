-- PEYZAJ AI / PAI-FORGE
-- M13 Authority Strengthening: Concurrency + Provenance Integrity
-- Scope: disposable non-production evidence only. No production/Core mutation.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
DROP SCHEMA IF EXISTS m13_strengthening CASCADE;
CREATE SCHEMA m13_strengthening;

CREATE TABLE m13_strengthening.design_candidate (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    state text NOT NULL CHECK (state IN ('CANDIDATE','VERIFIED','APPROVED')),
    actor_type text NOT NULL CHECK (actor_type IN ('HUMAN_REVIEWER','AI','SYSTEM')),
    version integer NOT NULL DEFAULT 1,
    payload text NOT NULL,
    payload_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE m13_strengthening.provenance (
    candidate_id bigint PRIMARY KEY REFERENCES m13_strengthening.design_candidate(id),
    payload_hash text NOT NULL,
    chain_hash text NOT NULL,
    valid boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION m13_strengthening.approve_candidate(
    p_id bigint,
    p_expected_version integer,
    p_actor_type text,
    p_actor_id text,
    p_new_state text
) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE
    v_payload_hash text;
    v_chain_hash text;
    v_rows integer;
BEGIN
    IF p_actor_type <> 'HUMAN_REVIEWER' OR p_new_state <> 'APPROVED' THEN
        RAISE EXCEPTION 'M13 AUTHORITY REJECTED';
    END IF;

    UPDATE m13_strengthening.design_candidate
       SET state = 'APPROVED',
           actor_type = p_actor_type,
           version = version + 1
     WHERE id = p_id
       AND state = 'VERIFIED'
       AND version = p_expected_version;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 0 THEN
        RETURN 0;
    END IF;

    SELECT payload_hash INTO v_payload_hash
      FROM m13_strengthening.design_candidate WHERE id = p_id;

    v_chain_hash := encode(digest(
        p_id::text || '|' || v_payload_hash || '|' || 'APPROVED' || '|' ||
        (p_expected_version + 1)::text || '|' || p_actor_id,
        'sha256'), 'hex');

    INSERT INTO m13_strengthening.provenance(candidate_id,payload_hash,chain_hash)
    VALUES (p_id,v_payload_hash,v_chain_hash)
    ON CONFLICT (candidate_id) DO NOTHING;

    RETURN 1;
END;
$$;

-- One candidate is prepared for the two-session concurrency test.
INSERT INTO m13_strengthening.design_candidate(state,actor_type,payload,payload_hash)
VALUES ('VERIFIED','HUMAN_REVIEWER','M13-CONCURRENCY-CANDIDATE',
        encode(digest('M13-CONCURRENCY-CANDIDATE','sha256'),'hex'));

-- Provenance baseline is created independently for the candidate.
INSERT INTO m13_strengthening.provenance(candidate_id,payload_hash,chain_hash)
SELECT id, payload_hash,
       encode(digest(id::text || '|' || payload_hash || '|VERIFIED|1','sha256'),'hex')
FROM m13_strengthening.design_candidate
WHERE state='VERIFIED';

-- T01: independent provenance recomputation must match stored chain hash.
DO $$
DECLARE r record; v_hash text;
BEGIN
  SELECT d.id,d.payload_hash,p.chain_hash INTO r
  FROM m13_strengthening.design_candidate d
  JOIN m13_strengthening.provenance p ON p.candidate_id=d.id;
  v_hash := encode(digest(r.id::text || '|' || r.payload_hash || '|VERIFIED|1','sha256'),'hex');
  IF v_hash <> r.chain_hash THEN RAISE EXCEPTION 'M13 P01 provenance mismatch'; END IF;
  RAISE NOTICE 'M13 P01 PASS: provenance chain independently verified';
END $$;

-- T02: controlled tamper must be detectable by independent recomputation.
UPDATE m13_strengthening.provenance
SET chain_hash = repeat('0',64), valid = false;

DO $$
DECLARE r record; v_hash text;
BEGIN
  SELECT d.id,d.payload_hash,p.chain_hash,p.valid INTO r
  FROM m13_strengthening.design_candidate d
  JOIN m13_strengthening.provenance p ON p.candidate_id=d.id;
  v_hash := encode(digest(r.id::text || '|' || r.payload_hash || '|VERIFIED|1','sha256'),'hex');
  IF r.chain_hash = v_hash OR r.valid THEN RAISE EXCEPTION 'M13 P02 tamper not detected'; END IF;
  RAISE NOTICE 'M13 P02 PASS: provenance tamper detected and retained';
END $$;

-- Restore the baseline and leave the database ready for the two-session test.
UPDATE m13_strengthening.provenance p
SET chain_hash = encode(digest(d.id::text || '|' || d.payload_hash || '|VERIFIED|1','sha256'),'hex'),
    valid = true
FROM m13_strengthening.design_candidate d
WHERE d.id=p.candidate_id;

DO $$
BEGIN
  RAISE NOTICE 'M13 STRENGTHENING SETUP READY: run approve_candidate concurrently from two sessions with expected_version=1';
END $$;
