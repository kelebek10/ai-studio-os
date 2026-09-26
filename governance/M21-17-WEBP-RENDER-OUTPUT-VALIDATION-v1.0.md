# M21-17 — WEBP RENDER OUTPUT VALIDATION v1.0

**Status:** DESIGN BASELINE

## Purpose
Validate rendered visual artifacts before delivery. Rendering success is separate from design truth and provider success.

## Required Artifact Metadata
- `render_id`
- `project_id`
- `scene_id`
- `scene_type`
- `layout_digest`
- `lighting_digest`
- `provider`
- `provider_contract_version`
- `output_format`
- `mime_type`
- `width`
- `height`
- `byte_size`
- `sha256`
- `created_at`
- `provenance`

## Validation Gates
1. File exists and is readable.
2. MIME/container is valid WEBP.
3. Dimensions meet configured minimums.
4. File size is non-zero and within configured operational limits.
5. SHA-256 is calculated and stored.
6. Scene metadata matches the render request.
7. Layout and lighting digests match the originating scene package.
8. Provider response does not overwrite project truth.

## Failure States
`BLOCKED_INVALID_ARTIFACT | BLOCKED_FORMAT | BLOCKED_DIMENSIONS | BLOCKED_METADATA_MISMATCH | BLOCKED_DIGEST_MISMATCH | READY_FOR_DELIVERY`.

## Delivery Rule
Only `READY_FOR_DELIVERY` artifacts may enter Telegram/customer delivery. A render artifact never becomes authoritative geometry.

**Version:** 1.0
