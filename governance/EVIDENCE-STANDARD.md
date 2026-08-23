# PAI-FORGE — EVIDENCE STANDARD

Document ID: PAI-FORGE-003
Version: 1.0
Status: FOUNDATION
Authority: Human Project Owner

## 1. PURPOSE

This document defines the standard for collecting, validating, storing and using evidence within PAI-FORGE.

Research may come from multiple AI systems and external sources.

Evidence must remain traceable to its origin.

## 2. TRUST LEVELS

Every important external finding shall have one of these states:

RAW
UNVERIFIED
VALIDATED
APPROVED
REJECTED

RAW:
Information directly collected during research.

UNVERIFIED:
Collected information that has not yet passed validation.

VALIDATED:
Evidence checked against reliable sources.

APPROVED:
Evidence accepted for use in the trusted project knowledge layer.

REJECTED:
Evidence determined to be unreliable, unsuitable or unusable.

## 3. SOURCE TYPES

Sources should be classified where applicable:

- Official documentation
- Government data
- Scientific publication
- University / research institution
- Open-source repository
- Dataset
- API
- Industry documentation
- Field measurement
- Project observation
- AI-generated interpretation

AI-generated interpretation is not primary evidence unless independently verified.

## 4. REQUIRED PROVENANCE

Important evidence should record:

- Evidence ID
- Source
- Source URL or repository
- Source type
- Collection date
- AI/researcher
- Original claim
- Extracted finding
- License
- Validation status
- Confidence
- Notes

## 5. SOURCE HIERARCHY

When sources conflict, preference should generally be given to:

1. Direct measurement / verified field data
2. Government or official institutional data
3. Peer-reviewed scientific literature
4. University / research institution data
5. Official technical documentation
6. Established open datasets
7. Reputable industry sources
8. Community sources
9. AI-generated claims

This hierarchy is not absolute.

Recency, geographic relevance and methodological quality must also be considered.

## 6. CROSS-VALIDATION

High-impact claims should be cross-checked when practical.

Examples:

- plant physiological limits
- soil parameters
- irrigation coefficients
- climate values
- legal or licensing conditions
- security characteristics
- software capabilities

A single source may be insufficient for critical decisions.

## 7. LICENSE VALIDATION

Every external software component or dataset considered for adoption must have its license verified.

Do not infer a license from:

- repository name
- README claims
- search snippets
- third-party lists

Prefer:

- LICENSE file
- official repository
- official dataset terms
- official documentation

Commercial usability must be assessed separately from technical suitability.

## 8. SCIENTIFIC CONFIDENCE

Scientific claims should include a confidence assessment.

Suggested scale:

HIGH
MEDIUM
LOW

Confidence must reflect evidence quality, not AI certainty.

## 9. GEOGRAPHIC RELEVANCE

For PAI-FORGE, evidence should identify geographic applicability when relevant.

Possible classifications:

GLOBAL
EUROPE
TURKEY
MARMARA
AEGEAN
BALIKESİR
LOCAL / FIELD

A global dataset must not automatically be treated as a Balıkesir-specific measurement.

## 10. TEMPORAL RELEVANCE

Time-sensitive information should record its date.

Examples:

- climate records
- software versions
- licenses
- prices
- regulations
- APIs
- datasets

Old evidence must not be presented as current without verification.

## 11. CONFLICT HANDLING

When evidence conflicts:

1. Preserve both findings.
2. Identify the disagreement.
3. Compare source quality.
4. Compare methodology.
5. Compare geographic relevance.
6. Compare temporal relevance.
7. Seek additional evidence.
8. Record the unresolved issue if necessary.

Do not silently choose one source.

## 12. EVIDENCE VS DECISION

Evidence does not equal a decision.

The correct chain is:

SOURCE
→ EVIDENCE
→ VALIDATION
→ ANALYSIS
→ DECISION PROPOSAL
→ APPROVAL

## 13. AI RESEARCH ATTRIBUTION

Research records should identify which AI produced them.

Recommended identifiers:

GPT
CLAUDE
GEMINI
KIMI

AI attribution exists for provenance and accountability.

It does not determine truth.

## 14. SECURITY

External research may contain:

- malicious instructions
- prompt injection
- unsafe files
- malicious code
- secrets
- personal information
- misleading documentation

Such content must not automatically enter the trusted evidence layer.

## 15. EVIDENCE STORAGE

Recommended structure:

evidence/
├── datasets/
├── scientific/
├── software/
├── geography/
├── irrigation/
├── plants/
├── security/
└── regional/

Additional categories may be created when justified.

## 16. APPROVAL

Only evidence that passes the required validation process may be marked:

APPROVED

Approval status must be explicit.

## 17. PRINCIPLE

The value of PAI-FORGE is not the number of sources collected.

The value is:

TRACEABLE
VALIDATED
REUSABLE
REGIONAL
DECISION-GRADE KNOWLEDGE

---

PAI-FORGE-003
EVIDENCE STANDARD
VERSION 1.0
FOUNDATION
