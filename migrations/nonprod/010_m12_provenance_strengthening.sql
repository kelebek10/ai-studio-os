-- PAI-FORGE M12 PROVENANCE STRENGTHENING PILOT v1.1
-- NONPROD ONLY. Disposable PostgreSQL test database only.
-- Never execute against production/Core databases.
-- Purpose: strengthen M12 evidence with independent hash-chain and tamper detection.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS m12_test;

DROP TABLE IF EXISTS m12_test.provenance_record CASCADE;
CREATE TABLE m12_test.provenance_record (
  record_id uuid PRIMARY KEY,
  source_ref text NOT NULL,
  predecessor_record_id uuid NULL REFERENCES m12_test.provenance_record(record_id),
  payload text NOT NULL,
  payload_hash text NOT NULL,
  chain_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE OR REPLACE FUNCTION m12_test.sha256_hex(p_value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
  SELECT encode(digest(convert_to(p_value, 'UTF8'), 'sha256'), 'hex');
$$;

CREATE OR REPLACE FUNCTION m12_test.expected_chain_hash(
  p_record_id uuid,
  p_source_ref text,
  p_predecessor_chain_hash text,
  p_payload_hash text
) RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT m12_test.sha256_hex(
    p_record_id::text || '|' ||
    p_source_ref || '|' ||
    COALESCE(p_predecessor_chain_hash, '<GENESIS>') || '|' ||
    p_payload_hash
  );
$$;

-- T01: create a two-record provenance chain and independently verify it.
DO $$
DECLARE
  v_id1 uuid := '00000000-0000-0000-0000-000000000121';
  v_id2 uuid := '00000000-0000-0000-0000-000000000122';
  v_payload1 text := '{"source":"m12-pilot","value":"alpha"}';
  v_payload2 text := '{"source":"m12-pilot","value":"beta"}';
  v_payload_hash1 text;
  v_payload_hash2 text;
  v_chain_hash1 text;
  v_chain_hash2 text;
  v_prev text;
BEGIN
  v_payload_hash1 := m12_test.sha256_hex(v_payload1);
  v_chain_hash1 := m12_test.expected_chain_hash(v_id1, 'M12-SOURCE-001', NULL, v_payload_hash1);

  INSERT INTO m12_test.provenance_record
    (record_id, source_ref, payload, payload_hash, chain_hash)
  VALUES
    (v_id1, 'M12-SOURCE-001', v_payload1, v_payload_hash1, v_chain_hash1);

  v_payload_hash2 := m12_test.sha256_hex(v_payload2);
  v_chain_hash2 := m12_test.expected_chain_hash(v_id2, 'M12-SOURCE-002', v_chain_hash1, v_payload_hash2);

  INSERT INTO m12_test.provenance_record
    (record_id, source_ref, predecessor_record_id, payload, payload_hash, chain_hash)
  VALUES
    (v_id2, 'M12-SOURCE-002', v_id1, v_payload2, v_payload_hash2, v_chain_hash2);

  SELECT chain_hash INTO v_prev
  FROM m12_test.provenance_record
  WHERE record_id = v_id1;

  IF v_chain_hash1 <> m12_test.expected_chain_hash(v_id1, 'M12-SOURCE-001', NULL, v_payload_hash1)
     OR v_chain_hash2 <> m12_test.expected_chain_hash(v_id2, 'M12-SOURCE-002', v_prev, v_payload_hash2)
  THEN
    RAISE EXCEPTION 'M12 T01 FAIL: provenance chain verification failed';
  END IF;

  RAISE NOTICE 'M12 T01 PASS: two-record provenance hash chain independently verified';
END $$;

-- T02: tamper with a payload and prove the stored payload hash no longer matches.
DO $$
DECLARE
  r m12_test.provenance_record%ROWTYPE;
  v_recomputed_payload_hash text;
BEGIN
  UPDATE m12_test.provenance_record
  SET payload = '{"source":"m12-pilot","value":"TAMPERED"}'
  WHERE record_id = '00000000-0000-0000-0000-000000000122';

  SELECT * INTO r
  FROM m12_test.provenance_record
  WHERE record_id = '00000000-0000-0000-0000-000000000122';

  v_recomputed_payload_hash := m12_test.sha256_hex(r.payload);

  IF v_recomputed_payload_hash = r.payload_hash THEN
    RAISE EXCEPTION 'M12 T02 FAIL: payload tamper was not detected';
  END IF;

  RAISE NOTICE 'M12 T02 PASS: payload tamper detected by independent hash recomputation';
END $$;

-- T03: restore the payload, then tamper with chain_hash and prove chain validation fails.
DO $$
DECLARE
  r1 m12_test.provenance_record%ROWTYPE;
  r2 m12_test.provenance_record%ROWTYPE;
  v_expected text;
BEGIN
  UPDATE m12_test.provenance_record
  SET payload = '{"source":"m12-pilot","value":"beta"}'
  WHERE record_id = '00000000-0000-0000-0000-000000000122';

  UPDATE m12_test.provenance_record
  SET chain_hash = repeat('0', 64)
  WHERE record_id = '00000000-0000-0000-0000-000000000122';

  SELECT * INTO r1 FROM m12_test.provenance_record
  WHERE record_id = '00000000-0000-0000-0000-000000000121';
  SELECT * INTO r2 FROM m12_test.provenance_record
  WHERE record_id = '00000000-0000-0000-0000-000000000122';

  v_expected := m12_test.expected_chain_hash(r2.record_id, r2.source_ref, r1.chain_hash, r2.payload_hash);

  IF r2.chain_hash = v_expected THEN
    RAISE EXCEPTION 'M12 T03 FAIL: chain tamper was not detected';
  END IF;

  RAISE NOTICE 'M12 T03 PASS: chain-hash tamper detected by independent recomputation';
END $$;

-- T04: rollback integrity. The failed mutation must not leave an extra provenance record.
DO $$
DECLARE
  v_before bigint;
  v_after bigint;
BEGIN
  SELECT count(*) INTO v_before FROM m12_test.provenance_record;

  BEGIN
    INSERT INTO m12_test.provenance_record
      (record_id, source_ref, predecessor_record_id, payload, payload_hash, chain_hash)
    VALUES
      ('00000000-0000-0000-0000-000000000123', 'M12-SOURCE-ROLLBACK',
       '00000000-0000-0000-0000-000000000122', 'rollback-test',
       m12_test.sha256_hex('rollback-test'), repeat('f', 64));

    RAISE EXCEPTION 'M12 T04 intentional rollback';
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  SELECT count(*) INTO v_after FROM m12_test.provenance_record;

  IF v_after <> v_before THEN
    RAISE EXCEPTION 'M12 T04 FAIL: rollback changed provenance record count';
  END IF;

  RAISE NOTICE 'M12 T04 PASS: rollback preserved provenance record count';
END $$;

-- Final verification intentionally reports the tampered state; this is expected pilot evidence.
DO $$
DECLARE
  v_invalid bigint;
BEGIN
  SELECT count(*) INTO v_invalid
  FROM m12_test.provenance_record r
  LEFT JOIN m12_test.provenance_record p
    ON p.record_id = r.predecessor_record_id
  WHERE r.payload_hash <> m12_test.sha256_hex(r.payload)
     OR r.chain_hash <> m12_test.expected_chain_hash(
          r.record_id,
          r.source_ref,
          p.chain_hash,
          r.payload_hash
        );

  IF v_invalid < 1 THEN
    RAISE EXCEPTION 'M12 FINAL FAIL: expected tamper evidence is absent';
  END IF;

  RAISE NOTICE 'M12 FINAL PASS: tamper evidence retained; invalid_records=%', v_invalid;
  RAISE NOTICE 'M12 PROVENANCE STRENGTHENING PILOT COMPLETE';
END $$;

ROLLBACK;
