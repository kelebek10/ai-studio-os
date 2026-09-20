-- Non-production verification tests for Communication & Trigger Core v0.1
-- Run against an isolated PostgreSQL test database only.
-- Expected outcome: every positive case succeeds; every negative case is rejected.

BEGIN;

CREATE TEMP TABLE test_ids (
    task_id uuid NOT NULL,
    correlation_id uuid NOT NULL
);

INSERT INTO communication_core.task_execution (
    task_id, correlation_id, agent, task_type, scope, source_commit
) VALUES (
    gen_random_uuid(), gen_random_uuid(),
    'test-agent', 'TEST', 'communication-core', 'test'
)
RETURNING task_id, correlation_id
INTO TEMP TABLE created_task;

INSERT INTO test_ids SELECT task_id, correlation_id FROM created_task;

UPDATE communication_core.task_execution
SET status = 'ROUTING', ack_at = now(), updated_at = now()
WHERE (task_id, correlation_id) IN (SELECT task_id, correlation_id FROM created_task);

UPDATE communication_core.task_execution
SET status = 'EXECUTING', updated_at = now()
WHERE (task_id, correlation_id) IN (SELECT task_id, correlation_id FROM created_task);

UPDATE communication_core.task_execution
SET status = 'COMPLETED',
    result = '{"ok": true}'::jsonb,
    evidence = '[{"type":"test","value":"verified"}]'::jsonb,
    updated_at = now()
WHERE (task_id, correlation_id) IN (SELECT task_id, correlation_id FROM created_task);

DO $$
DECLARE
    t uuid;
    c uuid;
BEGIN
    SELECT task_id, correlation_id INTO t, c FROM created_task;

    BEGIN
        UPDATE communication_core.task_execution
        SET status = 'ROUTING'
        WHERE task_id = t AND correlation_id = c;
        RAISE EXCEPTION 'NEGATIVE_TEST_FAILED: backward transition accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE 'INVALID_TASK_TRANSITION:%' THEN RAISE; END IF;
    END;

    BEGIN
        INSERT INTO communication_core.task_execution (
            task_id, correlation_id, agent, task_type, scope, source_commit, status
        ) VALUES (gen_random_uuid(), gen_random_uuid(), 'test-agent', 'TEST', 'communication-core', 'test', 'EXECUTING');
        RAISE EXCEPTION 'NEGATIVE_TEST_FAILED: invalid initial status accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE 'INVALID_INITIAL_TASK_STATUS:%' THEN RAISE; END IF;
    END;

    BEGIN
        UPDATE communication_core.task_execution
        SET status = 'COMPLETED', evidence = '[]'::jsonb
        WHERE task_id = t AND correlation_id = c;
        RAISE EXCEPTION 'NEGATIVE_TEST_FAILED: completion without evidence accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM <> 'COMPLETED_REQUIRES_EVIDENCE' THEN RAISE; END IF;
    END;

    BEGIN
        UPDATE communication_core.task_execution
        SET status = 'BLOCKED', result = '{}'::jsonb
        WHERE task_id = t AND correlation_id = c;
        RAISE EXCEPTION 'NEGATIVE_TEST_FAILED: blocked without reason accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM <> 'BLOCKED_REQUIRES_REASON' THEN RAISE; END IF;
    END;

    BEGIN
        UPDATE communication_core.task_execution
        SET problem_solving_round = 4
        WHERE task_id = t AND correlation_id = c;
        RAISE EXCEPTION 'NEGATIVE_TEST_FAILED: round 4 accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE <> '23514' THEN RAISE; END IF;
    END;

    BEGIN
        UPDATE communication_core.task_execution
        SET problem_solving_round = 1, problem_solving_declared = false
        WHERE task_id = t AND correlation_id = c;
        RAISE EXCEPTION 'NEGATIVE_TEST_FAILED: undeclared problem round accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE <> '23514' THEN RAISE; END IF;
    END;
END;
$$;

-- Idempotency identity: duplicate (task_id, correlation_id) must be rejected.
DO $$
DECLARE
    t uuid;
    c uuid;
BEGIN
    SELECT task_id, correlation_id INTO t, c FROM created_task;
    BEGIN
        INSERT INTO communication_core.task_execution (
            task_id, correlation_id, agent, task_type, scope, source_commit
        ) VALUES (t, c, 'test-agent', 'REPLAY', 'communication-core', 'test');
        RAISE EXCEPTION 'NEGATIVE_TEST_FAILED: duplicate task identity accepted';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;
END;
$$;

ROLLBACK;
