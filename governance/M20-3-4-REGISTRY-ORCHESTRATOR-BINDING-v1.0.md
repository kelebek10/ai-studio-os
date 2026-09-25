# M20.3.4 — Registry → Orchestrator Binding

Status: DESIGN_READY

## Binding Order
Orchestrator → Agent Registry → Capability Registry → eligibility check → bounded dispatch.

## Mandatory Checks
- agent exists
- environment matches
- status is ACTIVE
- enabled=true only for operationally activated agents
- requested capability exists and is enabled
- parent relationship is valid for specialists
- authority level permits the requested execution
- conflict_round <= max_conflict_rounds
- prohibited actions are enforced
- production target is rejected unless separately authorized

## Provider State
Claude/Gemini/Copilot remain registered but operationally disabled until M20.3.3 connectivity PASS and explicit human activation approval.

## Specialist State
Specialists may be registered under an approved parent, but cannot self-assign, self-escalate, approve governance, bypass Human Gate, or write production directly.

## Failure
Any failed eligibility check => DISPATCH_BLOCKED with structured reason. No automatic enablement or fallback activation.

## Evidence
Every dispatch decision must retain agent_id, capability, environment, eligibility result, reason, and correlation/task reference.

## Next
Implement the binding as a read-only eligibility/dispatch gate before enabling additional providers.
