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

# 22. APPLICATIONS

Directory:

applications/

Purpose:

Contains user-facing and service-facing applications built on top of the PAI-FORGE Core.

Structure:

applications/
├── api/
├── web/
└── mobile/

Applications must consume validated Core capabilities.

Applications must not become the primary storage location for authoritative knowledge.

---

# 23. API

Directory:

applications/api/

Purpose:

Provides controlled programmatic access to PAI-FORGE services.

Potential responsibilities:

- authentication
- authorization
- project operations
- plant queries
- suitability queries
- irrigation calculations
- evidence retrieval
- AI orchestration
- reporting
- audit access

API contracts must be versioned.

Breaking changes require an architectural decision.

---

# 24. WEB

Directory:

applications/web/

Purpose:

Contains the web interface of PAI-FORGE.

The web application must remain replaceable.

Business logic should remain in Core/API layers rather than being duplicated inside the frontend.

---

# 25. MOBILE

Directory:

applications/mobile/

Purpose:

Contains the mobile-first user experience.

Mobile is a primary interaction channel for PAI-FORGE.

The mobile layer should prioritize:

- simplicity
- speed
- low bandwidth
- offline tolerance where practical
- field usability
- camera and location capabilities
- clear decision presentation

The mobile application must consume the same Core and API contracts as other applications.

---

# 26. INFRASTRUCTURE

Directory:

infrastructure/

Purpose:

Contains deployment and infrastructure definitions.

Structure:

infrastructure/
├── database/
├── storage/
├── vector/
└── deployment/

Infrastructure components must remain replaceable where practical.

---

# 27. DATABASE

Directory:

infrastructure/database/

Purpose:

Contains database configuration, migrations, schemas and database-related infrastructure.

The relational database should be considered the primary structured data layer.

Candidate technology:

PostgreSQL.

Spatial extension:

PostGIS.

Vector extension:

pgvector where appropriate.

Technology selection remains subject to formal architectural evaluation.

---

# 28. STORAGE

Directory:

infrastructure/storage/

Purpose:

Contains object/file storage configuration.

Potential data:

- photographs
- project documents
- research files
- satellite data
- raster datasets
- generated reports
- model artifacts

Large files should not be unnecessarily stored inside Git.

---

# 29. VECTOR

Directory:

infrastructure/vector/

Purpose:

Contains semantic retrieval infrastructure.

Possible technologies include:

- pgvector
- Qdrant
- Weaviate
- other compatible vector systems

Selection must be based on:

- data ownership
- self-hosting capability
- performance
- filtering
- operational complexity
- licensing
- backup strategy
- migration capability

The vector layer must never become the sole source of truth.

---

# 30. DEPLOYMENT

Directory:

infrastructure/deployment/

Purpose:

Contains deployment configuration.

Potential components:

- Docker
- container configuration
- environment definitions
- CI/CD
- monitoring
- backups
- infrastructure-as-code

Secrets must never be committed to the repository.

---

# 31. TESTS

Directory:

tests/

Purpose:

Contains automated and manual validation systems.

Structure:

tests/
├── unit/
├── integration/
├── evaluation/
└── security/

Testing is mandatory for Core decision logic.

---

# 32. UNIT TESTS

Directory:

tests/unit/

Purpose:

Tests individual deterministic functions and modules.

Examples:

- suitability calculations
- environmental constraints
- irrigation equations
- taxonomy normalization
- unit conversions
- scoring functions

Deterministic calculations should have explicit expected outputs.

---

# 33. INTEGRATION TESTS

Directory:

tests/integration/

Purpose:

Tests interactions between system components.

Examples:

Database
→ Core
→ API

Core
→ Retrieval
→ LLM

Mobile
→ API
→ Core

Integration tests must verify data contracts.

---

# 34. EVALUATION

Directory:

tests/evaluation/

Purpose:

Evaluates AI and system-level performance.

Possible metrics:

- factual accuracy
- evidence grounding
- retrieval accuracy
- hallucination rate
- decision consistency
- rule adherence
- latency
- cost
- model performance

AI models must be evaluated against controlled test cases before being assigned critical responsibilities.

---

# 35. SECURITY TESTING

Directory:

tests/security/

Purpose:

Contains security and adversarial testing.

Testing areas include:

- prompt injection
- malicious files
- malicious repositories
- dependency vulnerabilities
- secret leakage
- unauthorized access
- data exfiltration
- privilege escalation
- unsafe tool execution

External research must be treated as untrusted input until verified.

---

# 36. DOCUMENTATION

Directory:

docs/

Purpose:

Contains operational and explanatory documentation.

Structure:

docs/
├── decisions/
├── specifications/
├── research/
└── operations/

---

# 37. DECISION DOCUMENTATION

Directory:

docs/decisions/

Contains human-readable explanations of important decisions.

Decision records should reference the authoritative record in:

core/decisions/

---

# 38. SPECIFICATIONS

Directory:

docs/specifications/

Contains detailed system specifications.

Examples:

- API specifications
- data schemas
- module specifications
- UI specifications
- integration specifications
- security specifications

---

# 39. RESEARCH DOCUMENTATION

Directory:

docs/research/

Contains human-readable research summaries.

Research summaries must reference the underlying evidence.

A summary is not a replacement for evidence.

---

# 40. OPERATIONS DOCUMENTATION

Directory:

docs/operations/

Contains operational procedures.

Examples:

- installation
- deployment
- backup
- recovery
- monitoring
- maintenance
- incident response
- upgrade procedures

---

# 41. README

The root README.md provides the public orientation of the repository.

It should explain:

- what PAI-FORGE is
- project purpose
- high-level architecture
- repository navigation
- development status
- contribution rules where applicable

The README must not become the authoritative location for architectural decisions.

---

# 42. SOURCE OF TRUTH HIERARCHY

PAI-FORGE uses the following hierarchy:

1. Architecture Constitution
2. Governance documents
3. Approved architectural decisions
4. Core schemas and rules
5. Verified evidence
6. Implementation
7. AI-generated working material

Lower-level material must not silently override higher-level authority.

---

# 43. EXTERNAL INPUT BOUNDARY

All information entering PAI-FORGE from outside the Core must initially be treated as untrusted.

This includes:

- websites
- GitHub repositories
- datasets
- uploaded files
- APIs
- AI outputs
- generated code
- third-party documentation

External information must pass the appropriate validation process before becoming authoritative.

---

# 44. RESEARCH → CORE PIPELINE

The standard pipeline is:

DISCOVER
↓
COLLECT
↓
SCREEN
↓
VERIFY
↓
COMPARE
↓
DECIDE
↓
APPROVE
↓
INTEGRATE
↓
TEST
↓
MONITOR

No step should be silently skipped for high-value Core components.

---

# 45. LICENSE CONTROL

Every external software component and dataset proposed for integration must have a license record.

The record must identify:

- license
- version
- copyright holder where relevant
- commercial-use conditions
- redistribution conditions
- modification requirements
- attribution requirements
- network-copyleft implications
- compatibility with PAI-FORGE

"Open source" does not automatically mean "safe for every architectural use."

---

# 46. DEPENDENCY CONTROL

External dependencies must be inventoried.

Each dependency should have:

- name
- version
- license
- purpose
- direct/transitive status
- security status
- maintenance status
- replacement option

Critical dependencies should have a documented fallback strategy.

---

# 47. MODEL-AGNOSTIC PRINCIPLE

PAI-FORGE must not depend permanently on:

- Gemini
- ChatGPT
- Claude
- Kimi
- any single future AI model

AI models are interchangeable execution engines.

The durable value remains in:

- Core data
- Core rules
- validated knowledge
- evidence
- provenance
- project records
- evaluations
- decision history

---

# 48. AI OUTPUT CONTROL

AI-generated output is not automatically authoritative.

AI output may be classified as:

- DRAFT
- RESEARCH
- HYPOTHESIS
- VERIFIED
- APPROVED
- REJECTED

Only approved information may enter authoritative Core structures.

---

# 49. DETERMINISTIC-FIRST PRINCIPLE

Whenever a problem can be solved reliably using:

- mathematics
- database queries
- explicit rules
- validated scientific models
- spatial computation
- deterministic algorithms

the deterministic method should be preferred over an LLM.

Examples:

Plant suitability
→ rules + environmental data

Irrigation calculation
→ FAO-based mathematical model

Spatial intersection
→ GIS engine

Taxonomy normalization
→ validated taxonomy source

LLM use should occur only where it adds genuine value.

---

# 50. LLM-LAST PRINCIPLE

LLMs should primarily perform:

- explanation
- synthesis
- natural language interaction
- controlled reasoning
- research assistance
- interpretation of validated information
- workflow coordination where appropriate

LLMs should not silently replace deterministic scientific calculations.

---

# 51. DATA OWNERSHIP

PAI-FORGE's long-term architecture should prioritize self-controlled infrastructure.

Where commercially and technically feasible:

- databases should be self-controlled
- object storage should be self-controlled
- vector storage should be self-controlled
- backups should be self-controlled
- Core knowledge should remain exportable
- AI providers should be replaceable

Cloud services may be used as infrastructure providers without making them the owner of the Core.

---

# 52. PRIVATE CORE

The authoritative PAI-FORGE Core is private.

Public open-source components may be used inside the system according to their licenses.

Using open-source software does not require publishing the private PAI-FORGE Core unless a specific license obligation requires it.

Each dependency must therefore be reviewed individually.

---

# 53. OPEN-SOURCE COMPONENT POLICY

PAI-FORGE may reuse open-source components when:

- license compatibility is confirmed
- security is acceptable
- maintenance is acceptable
- architectural dependency is understood
- replacement is feasible
- integration does not compromise Core ownership

Open-source components are dependencies.

They are not automatically part of PAI-FORGE's intellectual property.

---

# 54. DATA CENTER STRATEGY

PAI-FORGE may operate on:

- local infrastructure
- private server
- dedicated server
- private cloud
- hybrid infrastructure

The architecture should support migration between these environments.

The objective is infrastructure independence rather than dependence on one vendor.

---

# 55. BACKUP PRINCIPLE

Critical information must have independent backups.

At minimum, the backup strategy should cover:

- Core database
- Core knowledge
- provenance
- decisions
- project records
- configuration
- critical object storage

Backup restoration must be tested periodically.

---

# 56. VERSIONING

Important artifacts must be versioned.

Version-controlled artifacts include:

- architecture
- governance
- schemas
- rules
- datasets
- AI instructions
- APIs
- evaluation sets
- deployment configuration

Changes must be traceable.

---

# 57. CHANGE MANAGEMENT

Significant architectural changes require:

1. Change proposal
2. Impact analysis
3. Evidence review
4. Alternative evaluation
5. Decision
6. Implementation
7. Testing
8. Documentation update

Direct modification of foundational architecture without review is prohibited.

---

# 58. BRANCHING PRINCIPLE

Git branches may be used for:

- experiments
- feature development
- research
- security fixes
- architectural proposals

The main branch should represent the controlled project state.

Unverified experimental code must not be treated as production-ready.

---

# 59. COMMIT PRINCIPLE

Commits should describe the actual change.

Recommended format:

TYPE: concise description

Examples:

ARCH: update architecture specification

GOV: update governance policy

RESEARCH: add verified research

CORE: update knowledge schema

DATA: update dataset

TEST: add validation

SECURITY: patch security issue

DOCS: update documentation

---

# 60. PULL REQUEST PRINCIPLE

Significant changes should be reviewable before integration.

A pull request should explain:

- objective
- changes
- affected modules
- evidence
- risks
- tests
- rollback considerations

AI-generated code should receive independent review before entering critical paths.

---

# 61. AI RESEARCH INDEPENDENCE

Multiple AI models may independently research the same problem.

This is intentional.

Independent research reduces:

- model-specific blind spots
- confirmation bias
- premature architectural commitment

Results should converge through evidence rather than model authority.

---

# 62. COMMON EVIDENCE POOL

Research outputs from different AI systems should converge into a common evidence pool.

Conceptually:

Gemini ─┐
Claude ─┤
ChatGPT ├──→ Evidence Pool → Verification → Decision
Kimi ───┘

The evidence pool is the common reference layer.

No model's private conversation history is considered authoritative.

---

# 63. DECISION MECHANISM

Architectural decisions should be based on:

1. Evidence
2. Requirements
3. Security
4. Correctness
5. Maintainability
6. Scalability
7. Cost
8. Implementation complexity

AI consensus is useful but is not itself proof.

A unanimous AI decision can still be wrong.

---

# 64. HUMAN OVERSIGHT

High-impact decisions require human approval unless an explicit autonomous policy has been formally approved.

High-impact areas include:

- Core architecture
- security
- data ownership
- commercial licensing
- destructive operations
- production deployment
- irreversible migrations

---

# 65. AUTONOMOUS OPERATION

PAI-FORGE may progressively automate:

- research discovery
- evidence collection
- dataset screening
- testing
- code review
- documentation
- monitoring
- routine maintenance

Autonomy must remain bounded by permissions and validation gates.

---

# 66. FAILURE PRINCIPLE

When evidence is insufficient, the correct system behavior is:

UNKNOWN

not:

GUESS

The system must preserve uncertainty explicitly.

---

# 67. STATUS MODEL

Important data may use controlled statuses:

KNOWN
UNKNOWN
ESTIMATED
USER-PROVIDED
MEASURED
VISION-INFERRED
VERIFIED
APPROVED
REJECTED

Status must not be inferred silently.

---

# 68. AUDITABILITY

A qualified reviewer should be able to determine:

- what the system decided
- why it decided it
- what data it used
- what evidence supported it
- which algorithm was used
- which AI participated
- when the decision occurred
- which version was active

---

# 69. SECURITY BY DESIGN

Security is an architectural requirement, not a later feature.

Security controls should exist across:

- research ingestion
- file handling
- repositories
- dependencies
- databases
- APIs
- authentication
- authorization
- AI tools
- model inputs
- model outputs
- deployment

---

# 70. NO SECRET STORAGE

The repository must never contain:

- API keys
- passwords
- private tokens
- credentials
- private certificates
- production secrets

Secrets must be supplied through secure secret-management mechanisms.

---

# 71. DATA MINIMIZATION

PAI-FORGE should collect only data required for the intended function.

Sensitive information must have:

- purpose
- access control
- retention policy
- deletion strategy

---

# 72. OBSERVABILITY

Production systems should expose sufficient telemetry to understand:

- errors
- latency
- resource consumption
- AI usage
- retrieval performance
- decision failures
- security events

Observability data must not expose secrets.

---

# 73. PERFORMANCE

Performance optimization must follow measurement.

The project should avoid premature optimization.

Optimization priorities:

1. correctness
2. reliability
3. security
4. measurable performance
5. cost efficiency

---

# 74. SCALABILITY

The architecture should allow growth in:

- users
- projects
- plant records
- environmental records
- evidence
- AI workloads
- geographic coverage
- storage
- API traffic

Scaling should not require rewriting the Core.

---

# 75. REGIONAL EXPANSION

The initial scientific focus may be Balıkesir.

The architecture must not hard-code Balıkesir into the Core in a way that prevents future regions.

Regional knowledge should be represented as data.

Future regions may include:

- other Turkish provinces
- other Mediterranean regions
- international regions

---

# 76. LOCAL KNOWLEDGE ADVANTAGE

Regional datasets that cannot be obtained from global sources may become strategic PAI-FORGE assets.

Examples:

- local flora
- nursery availability
- local soil observations
- irrigation practices
- local climate observations
- local project experience
- regional landscape practices

Such data should be collected with provenance and quality controls.

---

# 77. SCIENTIFIC VALIDATION

Scientific claims used in the Core should preferably have:

- authoritative source
- reproducible method
- defined uncertainty
- version information
- applicable geographic scope

A global dataset must not automatically be assumed to be accurate at local parcel scale.

---

# 78. SPATIAL DATA PRINCIPLE

Spatial information should preserve:

- coordinate reference system
- spatial resolution
- acquisition date
- source
- accuracy
- transformation history

Spatial calculations must not silently mix incompatible coordinate systems.

---

# 79. TEMPORAL DATA PRINCIPLE

Environmental and project data must preserve time.

Important temporal fields may include:

- observation date
- measurement date
- dataset version
- validity period
- update date

Current information must not be confused with historical information.

---

# 80. INSTALLATION DECISION GATE

No external component should be installed into production solely because research identified it.

Before installation:

DISCOVERY
→ LICENSE CHECK
→ SECURITY CHECK
→ ARCHITECTURE CHECK
→ PERFORMANCE CHECK
→ OWNERSHIP CHECK
→ TEST
→ APPROVAL
→ INSTALL

---

# 81. REUSE / ADAPT / REFERENCE / REJECT

Every researched component should receive one of four actions:

REUSE
Use with minimal modification.

ADAPT
Modify or integrate selected concepts/components.

REFERENCE
Use as knowledge or design inspiration without integrating the software/data directly.

REJECT
Do not use.

The action must be evidence-based.

---

# 82. CURRENT OPEN-SOURCE RESEARCH PRINCIPLE

Current research has identified promising candidates including:

- GBIF
- World Flora Online
- SoilGrids
- CHELSA
- ERA5-Land
- FAO-56 methodologies
- WUCOLS methodology
- H3
- pgvector
- Qdrant
- pyfao56
- EcoCrop-related implementations
- plant trait databases
- plant identification systems
- geospatial libraries
- terrain analysis tools
- open-source design tools

These are candidates, not final installation decisions.

---

# 83. INSTALLATION STATUS

The current repository structure does not authorize automatic installation of any researched component.

Each candidate must pass its own decision gate.

This protects PAI-FORGE from:

- unnecessary dependencies
- incompatible licenses
- security vulnerabilities
- abandoned projects
- architectural coupling
- premature complexity

---

# 84. MINIMAL FOUNDATION

The initial implementation should remain minimal.

The project should not prematurely introduce:

- microservices
- unnecessary agent frameworks
- unnecessary vector databases
- unnecessary orchestration layers
- unnecessary cloud services
- unnecessary infrastructure complexity

Architecture should evolve according to demonstrated requirements.

---

# 85. MODULARITY

Every major subsystem should have a defined boundary.

Modules should be:

- independently testable
- independently replaceable
- versionable
- observable
- documented

Internal coupling should be minimized.

---

# 86. PORTABILITY

Core data and knowledge must remain portable.

Where practical, the system should support export to:

- PostgreSQL-compatible formats
- JSON
- CSV
- GeoJSON
- standard raster formats
- standard document formats

Vendor-specific formats should not become the only representation of critical knowledge.

---

# 87. INTEROPERABILITY

PAI-FORGE should prefer open standards where practical.

Relevant standards may include:

- JSON
- GeoJSON
- REST
- OpenAPI
- SQL
- GeoTIFF
- Parquet
- standard coordinate reference systems
- recognized botanical identifiers

Standards selection remains subject to implementation requirements.

---

# 88. FINAL PRINCIPLE

PAI-FORGE is not an AI chatbot with a collection of plugins.

It is intended to become:

A controlled knowledge system
+
A deterministic decision engine
+
A semantic retrieval layer
+
An AI reasoning layer
+
A project execution platform

The durable asset is the controlled Core.

AI models, libraries, databases and cloud providers are replaceable components around that Core.

---

# 89. DOCUMENT STATUS

Document:

PAI-FORGE-008

Title:

Repository Structure

Version:

1.0

Status:

FOUNDATION

This document defines the initial repository structure.

Future structural changes must be documented through the governance and architecture decision process.

END OF DOCUMENT
