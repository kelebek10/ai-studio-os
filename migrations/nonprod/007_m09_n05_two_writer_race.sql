-- M09-N05 — two-writer stale-writer race verification
-- Run only on disposable non-production PostgreSQL.
-- Requires 006_m09_design_head_cas_prototype.sql.

-- SESSION A
BEGIN;
SELECT governance.compare_and_set_design_head(
  '00000000-0000-0000-0000-000000000901'::uuid,
  10, 'H10', 11, 'H11'
);
-- Keep this transaction open until SESSION B has attempted the stale write.

-- SESSION B (while SESSION A remains open)
-- BEGIN;
-- SELECT governance.compare_and_set_design_head(
--   '00000000-0000-0000-0000-000000000901'::uuid,
--   10, 'H10', 12, 'H12'
-- );
-- Expected: STALE_STATE_VERSION after SESSION A commits.
-- ROLLBACK;

-- SESSION A
COMMIT;

-- SESSION B: retry the exact stale writer after A commits.
BEGIN;
DO $$
BEGIN
  PERFORM governance.compare_and_set_design_head(
    '00000000-0000-0000-0000-000000000901'::uuid,
    10, 'H10', 12, 'H12'
  );
  RAISE EXCEPTION 'M09-N05 FAIL: stale writer unexpectedly succeeded';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLERRM <> 'STALE_STATE_VERSION' THEN
      RAISE;
    END IF;
END;
$$;

DO $$
DECLARE v bigint; h text;
BEGIN
  SELECT state_version, state_hash INTO v,h
  FROM governance.design_head
  WHERE design_id='00000000-0000-0000-0000-000000000901'::uuid;
  IF v <> 11 OR h <> 'H11' THEN
    RAISE EXCEPTION 'M09-N05 FAIL: head changed after stale writer';
  END IF;
  RAISE NOTICE 'M09-N05 PASS: stale writer rejected; head remains (11,H11)';
END;
$$;
ROLLBACK;
