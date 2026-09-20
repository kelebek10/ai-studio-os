# PAI-FORGE — PRODUCT TARGET (PINNED)

**Status:** ACTIVE / PINNED  
**Purpose:** This document is the product boundary and development compass for PAI-FORGE.

## 1. Product Goal

PAI-FORGE is an AI-supported **Landscape Intelligence Engine**.

Its purpose is to use real, structured landscape knowledge to make existing image-generation AI models produce landscape designs more consciously, then evaluate the resulting design for landscape applicability.

PAI-FORGE is **not** an image-generation model and is **not** a general-purpose AI operating system.

## 2. Target E2E Flow

User Input
→ Landscape Knowledge Core
→ Landscape Decision Engine
→ Design Spec
→ Visual Brief
→ Existing Image AI
→ Visual Result
→ Visual / Applicability Validation

The first commercial-quality proof is one complete working loop for a real Balıkesir landscape case.

## 3. Development Order — DO NOT REORDER

1. Landscape Knowledge Core
2. Landscape Decision Engine
3. Design Spec
4. Visual Brief
5. Existing AI image generation
6. Visual / Applicability Validation
7. Validation with 10–20 real field cases

No new broad infrastructure work should displace this sequence.

## 4. Architecture Boundary

### Product layer — ACTIVE

- Landscape Knowledge Core
- Landscape Decision Engine
- Design Spec
- Visual Brief
- Image-provider adapter
- Applicability Validation
- Regional landscape data and evidence

### Development infrastructure — FROZEN / SECONDARY

Existing runtime/governance work is retained and must not be deleted, but it is not the current product objective.

Frozen unless a concrete PAI-FORGE requirement proves necessity:

- broad A2A orchestration
- advanced agent conflict/round lineage
- generic Agent Registry expansion
- Claude auto-wakeup expansion
- GitHub Bridge expansion
- generic AI Operating Layer extraction
- CI-001 expansion
- M15-A expansion
- new governance layers unrelated to the product path

## 5. AI Roles

AI models are workers, not product authorities.

- **GPT-5.6:** architecture, orchestration, validation, product integrity
- **Gemini:** landscape research, evidence gathering, knowledge preparation
- **Claude:** controlled implementation / coding / testing
- **Copilot:** GitHub-native engineering and delivery support

No AI independently defines the product architecture or becomes the authority for Landscape Core data.

## 6. Image Generation Strategy

PAI-FORGE does not become an image-generation platform.

It produces a structured **Visual Brief** and sends it through a replaceable image-provider adapter.

Possible providers include Gemini, OpenAI image APIs, FLUX-based services and future providers.

The provider must remain replaceable.

Cost principle:

> **Pay for usage, not unused capacity.**

Do not build or rent dedicated GPU infrastructure before real usage proves it necessary.

## 7. Core Design Principle

**Structured-First → Semantic-Second → LLM-Last**

The Landscape Knowledge Core must be deterministic, traceable, updateable and evidence-grounded.

LLMs may research, transform and assist, but must not directly mutate trusted Core data.

## 8. First Knowledge Core Scope

Initial canonical entities:

- Plant
- Region
- Climate
- Sun
- Water
- Soil
- Use Case
- Landscape Constraint
- Plant Suitability
- Evidence / Provenance

Initial target: a verified Balıkesir/North Aegean knowledge base, starting with a controlled set of real plant records.

## 9. Definition of Success

PAI-FORGE is progressing correctly when a real user case can travel through the complete chain:

**input → landscape decisions → structured design → visual brief → AI visual → applicability validation**

and the result can be tested against real field cases.

Infrastructure complexity, number of agents, number of repositories, or number of AI integrations are **not** success metrics.

## 10. Hard Stop Rule

If a proposed task does not directly improve one of the seven development stages, or does not remove a demonstrated blocker to them, it should normally be deferred.

Before adding infrastructure, ask:

1. Is it required by the current product stage?
2. Can the stage work without it?
3. Is the need proven by a real use case?
4. Does it reduce long-term technical debt rather than create abstraction?

If the answer is not sufficiently clear, do not build it.

## 11. Current Strategic Decision

**PAI-FORGE product development has priority.**

The project must now move directly toward the first working landscape-intelligence E2E loop.

**Next active task: Landscape Knowledge Core v0.1.**
