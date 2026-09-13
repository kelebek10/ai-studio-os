-- PAI-FORGE M10 Event Sequencing — non-production test skeleton
-- Disposable PostgreSQL only. Do not run against production.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_database() <> 'paiforge_test' THEN
    RAISE EXCEPTION 'M10_TEST_GUARD: unexpected database %', current_database();
  END IF;
END $$;

-- M10-P01: ordered transition evidence must be monotonic.
-- M10-N01: predecessor/order mismatch must be rejected.
-- M10-N02: duplicate canonical event identity must be idempotent.
-- M10-N03: rejected transition must leave no partial event/state mutation.
-- M10-N04: immutable event evidence must reject direct UPDATE/DELETE.
-- M10-N05: concurrent event writers must not create an impossible order.

SELECT 'M10 test skeleton loaded' AS status;
