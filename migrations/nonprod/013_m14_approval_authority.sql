-- PEYZAJ AI / PAI-FORGE
-- M14 Approval Authority: technical principal enforcement
-- Scope: disposable non-production evidence only. No production/Core mutation.
-- Objective: approval authority must be enforced by database principal/privilege,
-- not by a caller-supplied actor_type/actor_id parameter.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
DROP SCHEMA IF EXISTS m14_approval_authority CASCADE;
CREATE SCHEMA m14_approval_authority;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'paiforge_m14_human_approver') THEN CREATE ROLE paiforge_m14_human_approver NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'paiforge_m14_ai_agent') THEN CREATE ROLE paiforge_m14_ai_agent NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'paiforge_m14_workflow') THEN CREATE ROLE paiforge_m14_workflow NOLOGIN; END IF;
END $$;

CREATE TABLE m14_approval_authority.design_candidate (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    state text NOT NULL CHECK (state IN ('VERIFIED','APPROVED')),
    version integer NOT NULL DEFAULT 1,
    payload text NOT NULL,
    payload_hash text NOT NULL,
    approved_by text,
    approved_at timestamptz
);

INSERT INTO m14_approval_authority.design_candidate(state, payload, payload_hash)
VALUES ('VERIFIED', 'M14-AUTHORITY-CANDIDATE', encode(digest('M14-AUTHORITY-CANDIDATE','sha256'),'hex'));

CREATE OR REPLACE FUNCTION m14_approval_authority.approve_candidate(p_id bigint, p_expected_version integer)
RETURNS integer LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE v_rows integer;
BEGIN
    IF current_user <> 'paiforge_m14_human_approver' THEN
        RAISE EXCEPTION 'M14 AUTHORITY REJECTED: principal % is not the human approval principal', current_user;
    END IF;
    UPDATE m14_approval_authority.design_candidate
       SET state='APPROVED', version=version+1, approved_by=current_user, approved_at=now()
     WHERE id=p_id AND state='VERIFIED' AND version=p_expected_version;
    GET DIAGNOSTICS v_rows=ROW_COUNT;
    RETURN v_rows;
END;
$$;

REVOKE ALL ON SCHEMA m14_approval_authority FROM PUBLIC;
GRANT USAGE ON SCHEMA m14_approval_authority TO paiforge_m14_human_approver, paiforge_m14_ai_agent, paiforge_m14_workflow;
REVOKE ALL ON FUNCTION m14_approval_authority.approve_candidate(bigint,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION m14_approval_authority.approve_candidate(bigint,integer) TO paiforge_m14_human_approver;
REVOKE ALL ON TABLE m14_approval_authority.design_candidate FROM PUBLIC;
GRANT SELECT ON TABLE m14_approval_authority.design_candidate TO paiforge_m14_human_approver;

DO $$
BEGIN
    SET LOCAL ROLE paiforge_m14_ai_agent;
    BEGIN
        PERFORM m14_approval_authority.approve_candidate(1,1);
        RAISE EXCEPTION 'M14 T01 FAIL: AI principal executed approval';
    EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'M14 T01 PASS: AI principal denied by privilege boundary';
    WHEN OTHERS THEN IF SQLERRM LIKE 'M14 AUTHORITY REJECTED:%' THEN RAISE EXCEPTION 'M14 T01 FAIL: AI reached approval function; privilege boundary is insufficient'; ELSE RAISE EXCEPTION 'M14 T01 FAIL: unexpected error: %',SQLERRM; END IF;
    END;
END $$;

DO $$
BEGIN
    SET LOCAL ROLE paiforge_m14_workflow;
    BEGIN
        PERFORM m14_approval_authority.approve_candidate(1,1);
        RAISE EXCEPTION 'M14 T02 FAIL: workflow principal executed approval';
    EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'M14 T02 PASS: workflow principal denied by privilege boundary';
    WHEN OTHERS THEN IF SQLERRM LIKE 'M14 AUTHORITY REJECTED:%' THEN RAISE EXCEPTION 'M14 T02 FAIL: workflow reached approval function; privilege boundary is insufficient'; ELSE RAISE EXCEPTION 'M14 T02 FAIL: unexpected error: %',SQLERRM; END IF;
    END;
END $$;

DO $$
BEGIN
    SET LOCAL ROLE paiforge_m14_ai_agent;
    IF has_function_privilege(current_user,'m14_approval_authority.approve_candidate(bigint,integer)','EXECUTE') THEN RAISE EXCEPTION 'M14 T03 FAIL: AI principal has approval EXECUTE privilege'; END IF;
    RAISE NOTICE 'M14 T03 PASS: AI cannot self-assert human approval authority';
END $$;

DO $$
DECLARE v_result integer;
BEGIN
    SET LOCAL ROLE paiforge_m14_human_approver;
    v_result:=m14_approval_authority.approve_candidate(1,1);
    IF v_result<>1 THEN RAISE EXCEPTION 'M14 T04 FAIL: authorized human principal could not approve'; END IF;
    RAISE NOTICE 'M14 T04 PASS: authorized human approval principal accepted';
END $$;

DO $$
DECLARE r record;
BEGIN
    SELECT state,version,approved_by INTO r FROM m14_approval_authority.design_candidate WHERE id=1;
    IF r.state<>'APPROVED' OR r.version<>2 OR r.approved_by<>'paiforge_m14_human_approver' THEN RAISE EXCEPTION 'M14 T05 FAIL: approval provenance is not bound to actual principal'; END IF;
    RAISE NOTICE 'M14 T05 PASS: approval state and principal provenance verified';
END $$;

DO $$
DECLARE v_result integer;
BEGIN
    SET LOCAL ROLE paiforge_m14_human_approver;
    v_result:=m14_approval_authority.approve_candidate(1,1);
    IF v_result<>0 THEN RAISE EXCEPTION 'M14 T06 FAIL: stale/duplicate approval was accepted'; END IF;
    RAISE NOTICE 'M14 T06 PASS: duplicate/stale approval rejected';
END $$;

DO $$ BEGIN RAISE NOTICE 'M14 AUTHORITY TEST SUITE COMPLETE: T01-T06 PASS'; END $$;
