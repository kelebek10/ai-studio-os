-- PAI-FORGE M09 CAS VERIFICATION v1.0
-- Disposable PostgreSQL only. Design/prototype boundary; never production.

BEGIN;
DO $$
BEGIN
 IF current_database() <> 'paiforge_test' THEN RAISE EXCEPTION 'NONPROD_TARGET_GUARD'; END IF;
 IF current_user <> 'test_admin' THEN RAISE EXCEPTION 'NONPROD_TARGET_GUARD'; END IF;
END $$;

CREATE TABLE IF NOT EXISTS governance.design_head (
 design_id uuid PRIMARY KEY,
 design_state_id uuid NOT NULL REFERENCES governance.design_state(design_state_id) ON DELETE RESTRICT,
 state_version bigint NOT NULL CHECK(state_version>0),
 state_hash text NOT NULL,
 updated_at timestamptz NOT NULL DEFAULT now(),
 updated_by uuid NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_design_head_state_version ON governance.design_head(design_id,state_version);

CREATE OR REPLACE FUNCTION governance.cas_design_head(
 p_design_id uuid,
 p_expected_state_version bigint,
 p_expected_state_hash text,
 p_new_design_state_id uuid,
 p_new_state_version bigint,
 p_new_state_hash text,
 p_actor_id uuid
) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path=governance,core,public AS $$
DECLARE h governance.design_head%ROWTYPE;
BEGIN
 SELECT * INTO h FROM governance.design_head WHERE design_id=p_design_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'DESIGN_HEAD_NOT_FOUND'; END IF;
 IF h.state_version<>p_expected_state_version OR h.state_hash<>p_expected_state_hash THEN
   RAISE EXCEPTION 'STALE_DESIGN_HEAD';
 END IF;
 UPDATE governance.design_head
 SET design_state_id=p_new_design_state_id,state_version=p_new_state_version,state_hash=p_new_state_hash,updated_at=now(),updated_by=p_actor_id
 WHERE design_id=p_design_id;
 RETURN true;
END;
$$;

REVOKE UPDATE,DELETE ON governance.design_head FROM PUBLIC;

DO $$
DECLARE
 d uuid:=gen_random_uuid(); s1 uuid:=gen_random_uuid(); s2 uuid:=gen_random_uuid(); a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid();
BEGIN
 INSERT INTO governance.design_state(design_state_id,design_id,state_version,state_hash,ruleset_version,created_by)
 VALUES(s1,d,1,'m09-head-v1','r1',a);
 INSERT INTO governance.design_head(design_id,design_state_id,state_version,state_hash,updated_by)
 VALUES(d,s1,1,'m09-head-v1',a);
 INSERT INTO governance.design_state(design_state_id,design_id,state_version,state_hash,ruleset_version,created_by)
 VALUES(s2,d,2,'m09-head-v2','r1',a);
 PERFORM governance.cas_design_head(d,1,'m09-head-v1',s2,2,'m09-head-v2',a);
 BEGIN
   PERFORM governance.cas_design_head(d,1,'m09-head-v1',s2,2,'m09-head-v2',b);
   RAISE EXCEPTION 'M09-N05_EXPECTED_STALE_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM <> 'STALE_DESIGN_HEAD' THEN RAISE; END IF;
 END;
 IF (SELECT state_version FROM governance.design_head WHERE design_id=d)<>2 THEN
   RAISE EXCEPTION 'M09-N05_HEAD_ADVANCEMENT_INVALID';
 END IF;
 RAISE NOTICE 'M09-N05 DESIGN-HEAD CAS VERIFICATION: PASS';
END $$;

ROLLBACK;
