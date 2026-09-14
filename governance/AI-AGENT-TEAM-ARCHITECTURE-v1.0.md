# PEYZAJ AI — Multi-Agent Team Architecture v1.0

Status: CONTROLLED DESIGN INPUT
Owner: Human Project Owner
Branch: phase-1-3-foundation

## Objective
Create an autonomous-capable but authority-bounded internal AI team. Agents collaborate, independently review one another, produce evidence and stop on uncertainty or control violations.

## Roles
- `control`: read-only operational supervisor; detects conflicts, stalls, unauthorized activity and governance alarms.
- `orchestrator`: decomposes approved work, routes tasks and coordinates results; no approval authority.
- `architect`: architecture, security, data and integration review; no approval authority.
- `researcher`: evidence and source research; no authority.
- `implementer`: scoped repository implementation and non-production testing; no authority.
- `reviewer`: adversarial independent review; no authority.
- `evidence`: provenance, integrity and reproducibility verification; no authority.

## Authority hierarchy
1. Human Project Owner — final authority.
2. M14 Approval Authority — technical approval boundary.
3. Governance/policy gates — enforce permitted transitions.
4. Agents — execution, analysis, review and evidence only.

## Core rule
Agents may operate autonomously within granted scope, but no agent may grant itself, another agent or a workflow human authority.

## Collaboration
Typical flow:
`Task -> Control -> Orchestrator -> Architect/Researcher -> Implementer -> Reviewer -> Evidence -> Control -> Human Gate`

Reviewer and Evidence are independent control points. Agent consensus is never approval.

## Fail-closed
`FAIL`, `UNKNOWN`, `TIMEOUT`, missing evidence, provenance/integrity mismatch, authority conflict, scope ambiguity or reviewer unavailability => `BLOCKED`.

Maximum automated resolution rounds: 3. Unresolved disagreement after the limit => Human Gate.

## Safety boundaries
- `main` remains untouched by this design work.
- Production mutation remains prohibited.
- `governance/CURRENT-STATE.md` remains human-controlled.
- M14 authority controls remain unchanged.
- No secret or credential is stored in repository files.

## Implementation status
Role contracts are being introduced incrementally on `phase-1-3-foundation`. Runtime orchestration is not yet claimed operational until a controlled end-to-end test produces evidence.
