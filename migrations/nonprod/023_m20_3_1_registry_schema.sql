-- PAI-FORGE M20.3.1 non-production registry schema
-- Agent Registry + Capability Registry foundation.
-- NON-PRODUCTION ONLY. No production objects are modified.
-- Extends M19 control-plane primitives; does not replace task/assignment/lease semantics.

BEGIN;

CREATE SCHEMA IF NOT EXISTS m19_control;

CREATE TABLE m19_control.agent (
  agent_id text PRIMARY KEY,
  agent_type text NOT NULL,
  provider text NOT NULL,
  name text NOT NULL,
  role text NOT NULL,
  parent_agent_id text NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  authority_level text NOT NULL DEFAULT 'NONE',
  environment text NOT NULL,
  model_ref text NOT NULL,
  source_commit text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT agent_id_nonempty_ck CHECK (btrim(agent_id) <> ''),
  CONSTRAINT agent_type_ck CHECK (agent_type IN ('CORE','PROVIDER','SPECIALIST')),
  CONSTRAINT agent_provider_ck CHECK (btrim(provider) <> ''),
  CONSTRAINT agent_name_nonempty_ck CHECK (btrim(name) <> ''),
  CONSTRAINT agent_role_nonempty_ck CHECK (btrim(role) <> ''),
  CONSTRAINT agent_status_ck CHECK (status IN ('ACTIVE','DISABLED','BLOCKED','RETIRED')),
  CONSTRAINT agent_authority_ck CHECK (authority_level IN ('NONE','EXECUTION','COORDINATION')),
  CONSTRAINT agent_environment_ck CHECK (environment IN ('NONPROD','PILOT','PRODUCTION')),
  CONSTRAINT agent_model_ref_nonempty_ck CHECK (btrim(model_ref) <> ''),
  CONSTRAINT agent_source_commit_nonempty_ck CHECK (btrim(source_commit) <> ''),
  CONSTRAINT agent_metadata_object_ck CHECK (jsonb_typeof(metadata) = 'object'),
  CONSTRAINT agent_parent_shape_ck CHECK (
    (agent_type IN ('CORE','PROVIDER') AND parent_agent_id IS NULL)
    OR
    (agent_type = 'SPECIALIST' AND parent_agent_id IS NOT NULL AND parent_agent_id <> agent_id)
  ),
  CONSTRAINT agent_nonproduction_authority_ck CHECK (
    environment <> 'PRODUCTION'
    OR authority_level IN ('NONE','EXECUTION','COORDINATION')
  ),
  CONSTRAINT agent_enabled_status_ck CHECK (
    enabled = false OR status = 'ACTIVE'
  ),
  CONSTRAINT agent_identity_environment_uq UNIQUE (agent_id, environment)
);

ALTER TABLE m19_control.agent
  ADD CONSTRAINT agent_parent_fk
  FOREIGN KEY (parent_agent_id)
  REFERENCES m19_control.agent(agent_id)
  ON DELETE RESTRICT
  DEFERRABLE INITIALLY IMMEDIATE;

CREATE TABLE m19_control.agent_capability (
  capability_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id text NOT NULL,
  capability text NOT NULL,
  scope text NOT NULL,
  allowed_actions jsonb NOT NULL DEFAULT '[]'::jsonb,
  prohibited_actions jsonb NOT NULL DEFAULT '[]'::jsonb,
  environment text NOT NULL,
  requires_review boolean NOT NULL DEFAULT true,
  requires_human boolean NOT NULL DEFAULT false,
  max_conflict_rounds integer NOT NULL DEFAULT 3,
  enabled boolean NOT NULL DEFAULT false,
  source_commit text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT agent_capability_agent_fk
    FOREIGN KEY (agent_id, environment)
    REFERENCES m19_control.agent(agent_id, environment)
    ON DELETE RESTRICT,
  CONSTRAINT agent_capability_name_ck CHECK (btrim(capability) <> ''),
  CONSTRAINT agent_capability_scope_ck CHECK (btrim(scope) <> ''),
  CONSTRAINT agent_capability_environment_ck CHECK (environment IN ('NONPROD','PILOT','PRODUCTION')),
  CONSTRAINT agent_capability_allowed_array_ck CHECK (jsonb_typeof(allowed_actions) = 'array'),
  CONSTRAINT agent_capability_prohibited_array_ck CHECK (jsonb_typeof(prohibited_actions) = 'array'),
  CONSTRAINT agent_capability_conflict_rounds_ck CHECK (max_conflict_rounds BETWEEN 0 AND 3),
  CONSTRAINT agent_capability_source_commit_ck CHECK (btrim(source_commit) <> '')
);

-- A capability is unique for one agent within one execution scope/environment.
CREATE UNIQUE INDEX agent_capability_identity_uq
  ON m19_control.agent_capability(agent_id, capability, scope, environment);

-- Registry lookup / eligibility paths.
CREATE INDEX agent_type_status_idx
  ON m19_control.agent(agent_type, status);

CREATE INDEX agent_provider_status_idx
  ON m19_control.agent(provider, status);

CREATE INDEX agent_environment_enabled_idx
  ON m19_control.agent(environment, enabled, status);

CREATE INDEX agent_parent_idx
  ON m19_control.agent(parent_agent_id);

CREATE INDEX agent_source_commit_idx
  ON m19_control.agent(source_commit);

CREATE INDEX agent_capability_lookup_idx
  ON m19_control.agent_capability(capability, scope, environment, enabled);

CREATE INDEX agent_capability_agent_idx
  ON m19_control.agent_capability(agent_id, enabled);

CREATE INDEX agent_capability_source_commit_idx
  ON m19_control.agent_capability(source_commit);

-- Explicitly forbid the registry from becoming an implicit approval authority.
-- No approval_authority column exists by design; governance approval remains outside
-- registry capability grants and inside the existing Human Gate / approval boundary.

COMMIT;
