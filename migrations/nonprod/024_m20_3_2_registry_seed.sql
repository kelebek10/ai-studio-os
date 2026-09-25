-- PAI-FORGE M20.3.2 non-production registry seed
-- Seeds the controlled multi-agent registry; does NOT activate external provider runtime.
-- NON-PRODUCTION ONLY. Provider agents remain disabled until operational connectivity,
-- authentication boundary, capability mapping and evidence path are verified.

BEGIN;

INSERT INTO m19_control.agent (
  agent_id, agent_type, provider, name, role, parent_agent_id,
  status, authority_level, environment, model_ref, source_commit, enabled, metadata
) VALUES
(
  'core:orchestrator', 'CORE', 'internal',
  'PAI-FORGE Orchestrator', 'Controlled task orchestration',
  NULL, 'ACTIVE', 'COORDINATION', 'NONPROD',
  'orchestrator-runtime', 'ecc362fe6f9403480ef8a3d929f56f5c480b3345', true,
  '{"orchestration_root":true,"approval_authority":false}'::jsonb
),
(
  'core:security-intelligence', 'CORE', 'internal',
  'Security Intelligence Director', 'Security and intelligence control',
  NULL, 'ACTIVE', 'COORDINATION', 'NONPROD',
  'security-intelligence-runtime', 'ecc362fe6f9403480ef8a3d929f56f5c480b3345', true,
  '{"approval_authority":false,"dispatch_boundary":"orchestrator"}'::jsonb
),
(
  'provider:claude', 'PROVIDER', 'anthropic',
  'Claude', 'Independent architecture reviewer',
  NULL, 'ACTIVE', 'EXECUTION', 'NONPROD',
  'claude-runtime-pending', 'ecc362fe6f9403480ef8a3d929f56f5c480b3345', false,
  '{"orchestrator":"core:orchestrator","runtime_activation":"PENDING","approval_authority":false}'::jsonb
),
(
  'provider:gemini', 'PROVIDER', 'google',
  'Gemini', 'Independent data-model and scalability reviewer',
  NULL, 'ACTIVE', 'EXECUTION', 'NONPROD',
  'gemini-runtime-pending', 'ecc362fe6f9403480ef8a3d929f56f5c480b3345', false,
  '{"orchestrator":"core:orchestrator","runtime_activation":"PENDING","approval_authority":false}'::jsonb
),
(
  'provider:copilot', 'PROVIDER', 'github',
  'Copilot', 'SQL and implementation reviewer',
  NULL, 'ACTIVE', 'EXECUTION', 'NONPROD',
  'copilot-runtime-pending', 'ecc362fe6f9403480ef8a3d929f56f5c480b3345', false,
  '{"orchestrator":"core:orchestrator","runtime_activation":"PENDING","approval_authority":false}'::jsonb
),
(
  'specialist:qwen:security-evidence-analyst', 'SPECIALIST', 'other',
  'Qwen Security Evidence Analyst', 'Security evidence analysis',
  'core:orchestrator', 'ACTIVE', 'EXECUTION', 'NONPROD',
  'qwen3:1.7b', 'ecc362fe6f9403480ef8a3d929f56f5c480b3345', true,
  '{"orchestrator":"core:orchestrator","approval_authority":false,"reference_implementation":true}'::jsonb
)
ON CONFLICT (agent_id) DO UPDATE SET
  agent_type = EXCLUDED.agent_type,
  provider = EXCLUDED.provider,
  name = EXCLUDED.name,
  role = EXCLUDED.role,
  parent_agent_id = EXCLUDED.parent_agent_id,
  status = EXCLUDED.status,
  authority_level = EXCLUDED.authority_level,
  environment = EXCLUDED.environment,
  model_ref = EXCLUDED.model_ref,
  source_commit = EXCLUDED.source_commit,
  enabled = EXCLUDED.enabled,
  metadata = EXCLUDED.metadata,
  updated_at = now();

INSERT INTO m19_control.agent_capability (
  agent_id, capability, scope, allowed_actions, prohibited_actions,
  environment, requires_review, requires_human, max_conflict_rounds,
  enabled, source_commit
) VALUES
(
  'specialist:qwen:security-evidence-analyst',
  'security_evidence_analysis', 'M20.3/nonprod',
  '["read_task","inspect_evidence","produce_analysis","submit_evidence"]'::jsonb,
  '["production_write","governance_approve","task_self_assign","agent_assign","human_gate_bypass"]'::jsonb,
  'NONPROD', true, false, 3, true,
  'ecc362fe6f9403480ef8a3d929f56f5c480b3345'
),
(
  'provider:claude',
  'architecture_review', 'M20.3/nonprod',
  '["read_task","inspect_schema","produce_review","submit_evidence"]'::jsonb,
  '["production_write","governance_approve","task_self_assign","agent_assign","human_gate_bypass"]'::jsonb,
  'NONPROD', true, false, 3, false,
  'ecc362fe6f9403480ef8a3d929f56f5c480b3345'
),
(
  'provider:gemini',
  'data_model_scalability_review', 'M20.3/nonprod',
  '["read_task","inspect_schema","produce_review","submit_evidence"]'::jsonb,
  '["production_write","governance_approve","task_self_assign","agent_assign","human_gate_bypass"]'::jsonb,
  'NONPROD', true, false, 3, false,
  'ecc362fe6f9403480ef8a3d929f56f5c480b3345'
),
(
  'provider:copilot',
  'sql_test_review', 'M20.3/nonprod',
  '["read_task","inspect_sql","inspect_tests","produce_review","submit_evidence"]'::jsonb,
  '["production_write","governance_approve","task_self_assign","agent_assign","human_gate_bypass"]'::jsonb,
  'NONPROD', true, false, 3, false,
  'ecc362fe6f9403480ef8a3d929f56f5c480b3345'
)
ON CONFLICT (agent_id, capability, scope, environment) DO UPDATE SET
  allowed_actions = EXCLUDED.allowed_actions,
  prohibited_actions = EXCLUDED.prohibited_actions,
  requires_review = EXCLUDED.requires_review,
  requires_human = EXCLUDED.requires_human,
  max_conflict_rounds = EXCLUDED.max_conflict_rounds,
  enabled = EXCLUDED.enabled,
  source_commit = EXCLUDED.source_commit,
  updated_at = now();

COMMIT;
