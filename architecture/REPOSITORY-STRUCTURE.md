# PAI-FORGE — REPOSITORY STRUCTURE

Document ID: PAI-FORGE-008
Version: 1.0
Status: FOUNDATION
Classification: CORE ARCHITECTURE
Owner: PAI-FORGE Governance
Authority: PAI-FORGE Architecture Constitution

---

# 1. PURPOSE

This document defines the official repository structure of PAI-FORGE.

The repository is designed as a modular, evidence-grounded and model-agnostic system.

The structure separates:

- governance
- architecture
- research
- evidence
- core knowledge
- decision rules
- provenance
- AI agents
- applications
- infrastructure
- testing
- documentation
- operations

The repository must remain understandable, auditable and scalable.

No single AI model, application or external service may become the permanent architectural dependency of PAI-FORGE.

---

# 2. ARCHITECTURAL PRINCIPLE

PAI-FORGE follows:

Structured-First
→ Semantic-Second
→ LLM-Last

This means:

1. Structured data is preferred when available.
2. Deterministic rules are preferred for deterministic problems.
3. Semantic retrieval is used when structured retrieval is insufficient.
4. LLMs are used primarily for reasoning, synthesis, explanation and controlled interaction.
5. LLM output must never silently become authoritative knowledge.
6. External research must pass evidence and validation controls before entering Core.

---

# 3. ROOT REPOSITORY

The repository root represents the complete PAI-FORGE system.

Initial structure:

PAI-FORGE/
│
├── governance/
├── architecture/
├── research/
├── evidence/
├── core/
├── agents/
├── applications/
├── infrastructure/
├── tests/
└── docs/

Additional directories may only be introduced when a documented architectural requirement exists.

Unnecessary directory proliferation is prohibited.

---

# 4. GOVERNANCE

Directory:

governance/

Purpose:

Contains the constitutional, governance, decision, evidence and AI collaboration rules of PAI-FORGE.

Governance documents define what the system and participating AI models are allowed and required to do.

Initial files:

governance/
├── AI-GOVERNANCE.md
├── AI-ROLE-MATRIX.md
├── CORE-RESEARCH-BOUNDARY.md
├── DECISION-POLICY.md
├── EVIDENCE-STANDARD.md
├── PAI-FORGE-001-ARCHITECTURE-CONSTITUTION.md
└── RESEARCH-PROTOCOL.md

Governance is authoritative over implementation decisions.

Code must not override governance rules.

---

# 5. ARCHITECTURE

Directory:

architecture/

Purpose:

Contains structural definitions of the PAI-FORGE technical system.

Initial file:

architecture/
└── REPOSITORY-STRUCTURE.md

Future documents may include:

- system architecture
- data architecture
- core architecture
- AI orchestration architecture
- security architecture
- deployment architecture
- API architecture
- storage architecture

Architecture documents describe how components relate to each other.

They do not replace implementation code.

---

# 6. RESEARCH

Directory:

research/

Purpose:

Contains the complete research lifecycle.

Structure:

research/
├── missions/
├── raw/
├── screened/
├── verified/
├── approved/
└── rejected/

---

## 6.1 missions/

Contains research mission definitions.

Each mission must specify:

- research objective
- scope
- questions
- search strategy
- expected outputs
- responsible AI
- verification requirements
- completion criteria

Example:

research/missions/
└── MISSION-001-GITHUB-DISCOVERY.md

---

## 6.2 raw/

Contains unverified research outputs.

Raw research is considered untrusted external input.

Raw information must not be written directly into Core.

---

## 6.3 screened/

Contains research that has passed initial relevance and quality screening.

Screening does not mean scientific or technical approval.

---

## 6.4 verified/

Contains research that has passed evidence verification.

Verification may include:

- source validation
- repository validation
- license verification
- documentation verification
- scientific reference verification
- reproducibility checks
- version checks

---

## 6.5 approved/

Contains research assets approved for possible system integration.

Approval does not automatically mean that the asset will be installed.

Integration requires an additional architectural decision.

---

## 6.6 rejected/

Contains rejected research assets and their rejection reasons.

Rejected research must not simply disappear.

The rejection record provides institutional memory and prevents repeated investigation of known unsuitable resources.

---

# 7. EVIDENCE

Directory:

evidence/

Purpose:

Contains structured evidence supporting PAI-FORGE decisions.

Structure:

evidence/
├── sources/
├── datasets/
├── algorithms/
├── software/
└── scientific/

Evidence must be traceable to an original source whenever possible.

---

# 8. EVIDENCE SOURCES

Directory:

evidence/sources/

Contains source records.

A source record may include:

- source name
- source URL
- publisher
- author
- publication date
- access date
- source type
- reliability classification
- license
- citation
- verification status

---

# 9. DATASET EVIDENCE

Directory:

evidence/datasets/

Contains evidence records describing datasets.

Dataset records should include:

- dataset name
- provider
- geographic coverage
- temporal coverage
- spatial resolution
- variables
- format
- license
- commercial-use conditions
- update frequency
- scientific validation
- known limitations
- integration method

Examples of candidate external sources may include:

- GBIF
- World Flora Online
- SoilGrids
- CHELSA
- Copernicus datasets
- ERA5-Land
- regional Turkish datasets

External datasets must never be assumed to have identical licensing conditions.

License verification is mandatory before commercial integration.

---

# 10. ALGORITHM EVIDENCE

Directory:

evidence/algorithms/

Contains documented mathematical and scientific algorithms considered for PAI-FORGE.

Examples:

- FAO-56 Penman-Monteith
- WUCOLS methodology
- suitability models
- spatial analysis methods
- terrain analysis
- soil classification
- ecological constraint models

Each algorithm record must define:

- purpose
- inputs
- outputs
- assumptions
- mathematical basis
- scientific references
- limitations
- implementation options
- validation requirements

---

# 11. SOFTWARE EVIDENCE

Directory:

evidence/software/

Contains candidate open-source libraries, frameworks and software systems.

Each record must include:

- project name
- repository
- version
- license
- commercial-use status
- dependencies
- maintenance status
- security considerations
- integration complexity
- architectural role
- replacement strategy

No GitHub repository becomes part of PAI-FORGE merely because it is open source.

---

# 12. SCIENTIFIC EVIDENCE

Directory:

evidence/scientific/

Contains scientific literature and authoritative references.

Priority should be given to:

1. peer-reviewed scientific literature
2. official institutions
3. standards organizations
4. authoritative technical documentation
5. validated open datasets
6. reputable research repositories

Unverified web content must not be treated as scientific authority.

---

# 13. CORE

Directory:

core/

Purpose:

The Core contains the durable intellectual and computational assets of PAI-FORGE.

Structure:

core/
├── knowledge/
├── rules/
├── data/
├── provenance/
└── decisions/

The Core is the protected center of the system.

External research does not automatically become Core knowledge.

---

# 14. CORE KNOWLEDGE

Directory:

core/knowledge/

Contains validated knowledge intended for long-term reuse.

Knowledge may include:

- plant knowledge
- environmental knowledge
- landscape knowledge
- regional knowledge
- technical knowledge
- validated domain relationships

Knowledge must have provenance.

---

# 15. CORE RULES

Directory:

core/rules/

Contains deterministic decision rules.

Examples:

- plant hard constraints
- soil compatibility rules
- irrigation rules
- environmental thresholds
- safety rules
- regional suitability rules

Rules must be:

- explicit
- versioned
- testable
- auditable
- independently reviewable

LLM-generated suggestions must not silently become deterministic rules.

---

# 16. CORE DATA

Directory:

core/data/

Contains structured canonical data used by the Core.

Examples:

- plant records
- taxonomy
- environmental parameters
- soil parameters
- climate parameters
- irrigation parameters
- regional classifications
- project data

Data should be machine-readable and normalized.

---

# 17. CORE PROVENANCE

Directory:

core/provenance/

Contains the lineage of Core information.

Each important knowledge object should be traceable to:

Source
→ Evidence
→ Verification
→ Decision
→ Core Record
→ Application Output

The system must preserve provenance wherever practical.

---

# 18. CORE DECISIONS

Directory:

core/decisions/

Contains approved architectural and scientific decisions.

Each decision should document:

- decision ID
- date
- problem
- alternatives
- evidence
- decision
- rationale
- consequences
- review conditions

This prevents important decisions from remaining only inside AI conversations.

---

# 19. AI AGENTS

Directory:

agents/

Purpose:

Contains role-specific AI configuration, instructions, task definitions and integration contracts.

Structure:

agents/
├── chatgpt/
├── claude/
├── gemini/
└── kimi/

AI models are replaceable execution components.

No AI model owns the Core.

No AI model may independently redefine the architecture.

---

# 20. AI AGENT RESPONSIBILITY

Each agent directory may contain:

- role definition
- system instructions
- task templates
- input schema
- output schema
- evaluation criteria
- limitations
- known failure modes

Example:

agents/claude/
├── ROLE.md
├── TASKS.md
└── OUTPUT-SCHEMA.md

The exact structure may evolve according to project requirements.

---

# 21. AI COLLABORATION MODEL

The four AI systems may operate independently within their assigned roles.

Their outputs converge into a shared evidence and decision process.

Conceptually:

AI Research
     ↓
Raw Research
     ↓
Screening
     ↓
Evidence Verification
     ↓
Common Evidence Pool
     ↓
Independent Analysis
     ↓
Decision Review
     ↓
Approved Decision
     ↓
Core

No AI may bypass this process for authoritative knowledge.

---
