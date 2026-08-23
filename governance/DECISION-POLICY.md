# PAI-FORGE — DECISION POLICY

Document ID: PAI-FORGE-004
Version: 1.0
Status: FOUNDATION
Authority: Human Project Owner

## 1. PURPOSE

This document defines how PAI-FORGE converts research and validated evidence into technical and architectural decisions.

The system must optimize for:

- correctness
- safety
- scientific validity
- maintainability
- scalability
- commercial viability
- long-term strategic value

Speed alone is never sufficient justification for a decision.

## 2. DECISION FLOW

The standard decision pipeline is:

RESEARCH
→ EVIDENCE
→ VALIDATION
→ ALTERNATIVES
→ RISK ANALYSIS
→ AI REVIEW
→ DECISION PROPOSAL
→ HUMAN APPROVAL
→ APPROVED DECISION

## 3. DECISION CATEGORIES

Every important proposal should be classified as one of:

ARCHITECTURE
DATA
ALGORITHM
SOFTWARE
AI / MODEL
SECURITY
INFRASTRUCTURE
PRODUCT
COMMERCIAL
OPERATIONS

## 4. OPTION FRAMEWORK

Whenever practical, at least two viable alternatives should be considered.

For each alternative identify:

- benefits
- disadvantages
- technical complexity
- cost
- security implications
- license implications
- scalability
- maintenance burden
- migration risk
- long-term value

## 5. PRIORITY ORDER

When alternatives are compared, use this priority order:

1. Correctness
2. Security
3. Scalability
4. Sustainability
5. User experience
6. Commercial value
7. Development cost
8. Development time

## 6. ADOPTION DECISIONS

External components should normally receive one of four decisions:

ADOPT
ADAPT
REFERENCE
REJECT

### ADOPT

Use substantially as provided.

### ADAPT

Modify or integrate selectively while respecting license and attribution requirements.

### REFERENCE

Use as a conceptual, scientific or architectural reference without directly incorporating it.

### REJECT

Do not use because of technical, scientific, legal, security or strategic concerns.

## 7. DECISION RECORD

Important decisions should contain:

- Decision ID
- Date
- Problem
- Context
- Options
- Evidence
- Risks
- Recommendation
- AI positions
- Dissenting opinions
- Final decision
- Approval authority
- Status

## 8. AI CONSENSUS

AI agreement is useful but is not proof.

If all AI systems agree, the evidence must still be evaluated.

If AI systems disagree, the disagreement must be preserved and investigated.

Consensus must never be manufactured.

## 9. DISSENT

Any AI may formally disagree with a proposed decision.

A dissenting position should contain:

- disputed claim
- alternative interpretation
- evidence
- estimated risk
- recommended action

Dissent remains part of the decision record.

## 10. HUMAN APPROVAL

The following require explicit human approval:

- foundational architecture
- proprietary Core changes
- security architecture
- production deployment
- major infrastructure commitments
- significant financial commitments
- irreversible migrations
- legal/license-sensitive adoption
- publication of proprietary knowledge

## 11. AUTOMATION BOUNDARY

Automation may be used for:

- research collection
- document generation
- validation workflows
- testing
- data transformation
- routine analysis
- reporting

Automation must not silently approve foundational decisions.

## 12. REVERSIBILITY

Prefer reversible decisions when uncertainty is high.

A decision should identify whether it is:

REVERSIBLE
PARTIALLY REVERSIBLE
IRREVERSIBLE

Irreversible decisions require stronger evidence and review.

## 13. EXPERIMENTAL STATUS

New technologies may be evaluated without immediate production adoption.

Experimental components must be clearly marked:

EXPERIMENTAL

They must not be confused with approved production components.

## 14. DECISION CONFIDENCE

A proposal may be classified:

HIGH CONFIDENCE
MEDIUM CONFIDENCE
LOW CONFIDENCE

Confidence reflects evidence quality and uncertainty.

It does not represent AI confidence alone.

## 15. ARCHITECTURAL CONSISTENCY

Every major decision must be checked against:

PAI-FORGE-001 — Architecture Constitution
PAI-FORGE-002 — AI Governance
PAI-FORGE-003 — Evidence Standard

A proposal that conflicts with a foundational document must explicitly identify the conflict and propose a formal revision if necessary.

## 16. CHANGE MANAGEMENT

Approved decisions must be versioned.

If a later decision supersedes an earlier one, the new record must identify the previous decision.

Historical decisions must not be silently deleted.

## 17. DECISION PRINCIPLE

PAI-FORGE does not optimize for:

"the AI that sounds most convincing."

It optimizes for:

BEST SUPPORTED DECISION
WITH
KNOWN RISKS
AND
TRACEABLE EVIDENCE.

---

PAI-FORGE-004
DECISION POLICY
VERSION 1.0
FOUNDATION
