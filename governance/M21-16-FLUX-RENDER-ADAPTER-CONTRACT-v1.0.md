# M21-16 — FLUX RENDER ADAPTER CONTRACT v1.0

**Status:** DESIGN BASELINE

## Purpose
Convert an approved canonical scene package into a deterministic, auditable render request for FLUX.2 Pro without transferring design authority to the renderer.

## Inputs
- `scene package` with `READY_FOR_RENDER` status;
- authoritative layout digest;
- lighting digest when applicable;
- approved site/reference images;
- render constraints;
- provider contract/version.

## Output
A provider-neutral render request containing:
- `render_request_id`
- `project_id`
- `scene_id`
- `scene_type`
- `layout_digest`
- `lighting_digest`
- `reference_ids`
- `render_instruction`
- `output_format`
- `provider`
- `provider_contract_version`
- `provenance`
- `status`

## Authority Rules
1. The adapter may describe authoritative geometry; it may not alter it.
2. It may translate structured constraints into render instructions.
3. It may not add plants, structures, paths, lighting elements or terrain absent from authoritative inputs.
4. FLUX output is never used to update `layout.json` or `lighting.json` automatically.
5. Provider credentials and API execution remain outside this contract.

## Reference Gate
Required reference evidence must be present before a request reaches the provider.
Missing or invalid reference state → `BLOCKED_MISSING_REFERENCE`.

## Fail-Closed States
`BLOCKED_MISSING_REFERENCE | BLOCKED_SCENE_INVALID | BLOCKED_DIGEST_MISMATCH | BLOCKED_UNSUPPORTED_SCENE | READY_FOR_PROVIDER`

## Output Contract
The preferred visual transport format is `WEBP` after rendering. The adapter itself does not claim successful rendering; provider execution and output validation are separate gates.

## Acceptance Criteria
- identical authoritative inputs produce identical request content;
- layout and lighting digests are preserved;
- provider request contains no invented authoritative design facts;
- missing reference blocks dispatch;
- unsupported scene blocks dispatch;
- provider output cannot silently modify source project truth.

**Version:** 1.0
