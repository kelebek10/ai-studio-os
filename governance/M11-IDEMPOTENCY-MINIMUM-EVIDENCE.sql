-- PEYZAJ AI / PAI-FORGE
-- M11 minimum evidence strengthening
-- DISPOSABLE PostgreSQL ONLY

DROP SCHEMA IF EXISTS m11_test CASCADE;
CREATE SCHEMA m11_test;

CREATE TABLE m11_test.effects (
    id BIGSERIAL PRIMARY KEY,
    event_key TEXT NOT NULL UNIQUE,
    payload TEXT NOT NULL,
    payload_hash TEXT NOT NULL,
    effect_count INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION m11_test.apply_event(
    p_event_key TEXT,
    p_payload TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_existing_hash TEXT;
BEGIN
    v_existing_hash := (
        SELECT payload_hash
        FROM m11_test.effects
        WHERE event_key = p_event_key
        FOR UPDATE
    );

    IF v_existing_hash IS NOT NULL THEN
        IF v_existing_hash = encode(sha256(convert_to(p_payload, 'UTF8')), 'hex') THEN
            RETURN 'EXACT_REPLAY';
        ELSE
            RAISE EXCEPTION 'M11 conflicting replay: canonical identity already exists with different payload';
        END IF;
    END IF;

    INSERT INTO m11_test.effects(event_key, payload, payload_hash)
    VALUES (
        p_event_key,
        p_payload,
        encode(sha256(convert_to(p_payload, 'UTF8')), 'hex')
    );

    RETURN 'APPLIED';
END;
$$;

-- T01 Exact Replay
DO $$
DECLARE
    v_result TEXT;
    v_count INTEGER;
BEGIN
    v_result := m11_test.apply_event('M11-EVENT-001', '{"action":"CREATE","value":100}');
    IF v_result <> 'APPLIED' THEN
        RAISE EXCEPTION 'T01 FAIL: first application was not APPLIED';
    END IF;

    v_result := m11_test.apply_event('M11-EVENT-001', '{"action":"CREATE","value":100}');
    SELECT count(*) INTO v_count FROM m11_test.effects WHERE event_key = 'M11-EVENT-001';

    IF v_result <> 'EXACT_REPLAY' OR v_count <> 1 THEN
        RAISE EXCEPTION 'T01 FAIL: result=%, row_count=%', v_result, v_count;
    END IF;

    RAISE NOTICE 'M11 T01 PASS: exact replay rejected as duplicate effect; canonical row_count=%', v_count;
END;
$$;

-- T02 Conflicting Replay
DO $$
DECLARE
    v_rejected BOOLEAN := FALSE;
    v_payload TEXT;
BEGIN
    BEGIN
        PERFORM m11_test.apply_event('M11-EVENT-001', '{"action":"CREATE","value":999}');
    EXCEPTION
        WHEN OTHERS THEN
            v_rejected := TRUE;
            IF position('canonical identity already exists' IN SQLERRM) = 0 THEN
                RAISE;
            END IF;
    END;

    SELECT payload INTO v_payload FROM m11_test.effects WHERE event_key = 'M11-EVENT-001';

    IF NOT v_rejected THEN
        RAISE EXCEPTION 'T02 FAIL: conflicting replay was accepted';
    END IF;

    IF v_payload <> '{"action":"CREATE","value":100}' THEN
        RAISE EXCEPTION 'T02 FAIL: canonical payload changed: %', v_payload;
    END IF;

    RAISE NOTICE 'M11 T02 PASS: conflicting replay rejected; canonical payload preserved';
END;
$$;

-- T03 Canonical Identity Integrity
DO $$
DECLARE
    v_before_key TEXT;
    v_before_hash TEXT;
    v_after_key TEXT;
    v_after_hash TEXT;
BEGIN
    SELECT event_key, payload_hash INTO v_before_key, v_before_hash
    FROM m11_test.effects WHERE event_key = 'M11-EVENT-001';

    PERFORM m11_test.apply_event('M11-EVENT-001', '{"action":"CREATE","value":100}');

    SELECT event_key, payload_hash INTO v_after_key, v_after_hash
    FROM m11_test.effects WHERE event_key = 'M11-EVENT-001';

    IF v_before_key <> v_after_key THEN
        RAISE EXCEPTION 'T03 FAIL: canonical identity changed';
    END IF;
    IF v_before_hash <> v_after_hash THEN
        RAISE EXCEPTION 'T03 FAIL: canonical payload hash changed';
    END IF;

    RAISE NOTICE 'M11 T03 PASS: canonical identity and payload hash unchanged';
END;
$$;

-- T04 Rollback After Successful Attempt + Retry
DO $$
DECLARE
    v_result TEXT;
    v_count INTEGER;
BEGIN
    BEGIN
        v_result := m11_test.apply_event('M11-EVENT-ROLLBACK', '{"action":"CREATE","value":200}');
        IF v_result <> 'APPLIED' THEN
            RAISE EXCEPTION 'T04 FAIL: initial application did not succeed';
        END IF;
        RAISE EXCEPTION 'M11 intentional rollback';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM <> 'M11 intentional rollback' THEN
                RAISE;
            END IF;
    END;

    SELECT count(*) INTO v_count FROM m11_test.effects WHERE event_key = 'M11-EVENT-ROLLBACK';
    IF v_count <> 0 THEN
        RAISE EXCEPTION 'T04 FAIL: rolled-back effect still exists: %', v_count;
    END IF;

    v_result := m11_test.apply_event('M11-EVENT-ROLLBACK', '{"action":"CREATE","value":200}');
    SELECT count(*) INTO v_count FROM m11_test.effects WHERE event_key = 'M11-EVENT-ROLLBACK';

    IF v_result <> 'APPLIED' OR v_count <> 1 THEN
        RAISE EXCEPTION 'T04 FAIL: retry result=%, row_count=%', v_result, v_count;
    END IF;

    RAISE NOTICE 'M11 T04 PASS: rollback removed prior effect; retry created exactly one effect';
END;
$$;

-- Final verification
DO $$
DECLARE
    v_event_count INTEGER;
    v_rollback_count INTEGER;
BEGIN
    SELECT count(*) INTO v_event_count FROM m11_test.effects WHERE event_key = 'M11-EVENT-001';
    SELECT count(*) INTO v_rollback_count FROM m11_test.effects WHERE event_key = 'M11-EVENT-ROLLBACK';

    IF v_event_count <> 1 OR v_rollback_count <> 1 THEN
        RAISE EXCEPTION 'M11 FINAL FAIL: event_count=%, rollback_count=%', v_event_count, v_rollback_count;
    END IF;

    RAISE NOTICE '===== M11 MINIMUM EVIDENCE COMPLETE =====';
    RAISE NOTICE 'T01 EXACT REPLAY: PASS';
    RAISE NOTICE 'T02 CONFLICTING REPLAY: PASS';
    RAISE NOTICE 'T03 CANONICAL IDENTITY: PASS';
    RAISE NOTICE 'T04 ROLLBACK + RETRY: PASS';
    RAISE NOTICE 'FINAL canonical_effect_count=1';
    RAISE NOTICE 'FINAL rollback_retry_effect_count=1';
    RAISE NOTICE 'M11 TEST COMPLETE';
END;
$$;
