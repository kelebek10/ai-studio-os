-- PEYZAJ AI / PAI-FORGE
-- M09 optimistic concurrency — non-production CAS prototype
-- Design-only execution boundary: disposable test DB only.

CREATE TABLE IF NOT EXISTS governance.design_head (
    design_id uuid PRIMARY KEY,
    state_version bigint NOT NULL,
    state_hash text NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION governance.compare_and_set_design_head(
    p_design_id uuid,
    p_expected_state_version bigint,
    p_expected_state_hash text,
    p_new_state_version bigint,
    p_new_state_hash text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = governance, pg_catalog
AS $$
DECLARE
    v_version bigint;
    v_hash text;
BEGIN
    SELECT state_version, state_hash
      INTO v_version, v_hash
      FROM governance.design_head
     WHERE design_id = p_design_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'DESIGN_HEAD_NOT_FOUND';
    END IF;

    IF v_version <> p_expected_state_version THEN
        RAISE EXCEPTION 'STALE_STATE_VERSION';
    END IF;

    IF v_hash <> p_expected_state_hash THEN
        RAISE EXCEPTION 'STALE_STATE_HASH';
    END IF;

    IF p_new_state_version <= p_expected_state_version THEN
        RAISE EXCEPTION 'INVALID_NEXT_STATE_VERSION';
    END IF;

    UPDATE governance.design_head
       SET state_version = p_new_state_version,
           state_hash = p_new_state_hash,
           updated_at = now()
     WHERE design_id = p_design_id;
END;
$$;

REVOKE ALL ON governance.design_head FROM PUBLIC;
REVOKE ALL ON FUNCTION governance.compare_and_set_design_head(uuid,bigint,text,bigint,text) FROM PUBLIC;

-- Explicit grant is intentionally limited to the controlled test role.
GRANT SELECT, UPDATE ON governance.design_head TO test_admin;
GRANT EXECUTE ON FUNCTION governance.compare_and_set_design_head(uuid,bigint,text,bigint,text) TO test_admin;
