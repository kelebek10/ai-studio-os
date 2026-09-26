M21.18
FLUX.2 Pro Provider Adapter
Status: IMPLEMENTATION
Provider: Black Forest Labs API
Endpoint: /v1/flux-2-pro
Credential: BFL_API_KEY environment only

## Purpose
Provide a deterministic provider boundary between an approved M21.16 render request and the external FLUX.2 Pro API.

## Authority
The adapter may transport an approved render request only. It may not modify project truth, layout, planting, lighting, scene geometry, or render constraints.

## Provider contract
- Provider: Black Forest Labs
- Model endpoint: `POST https://api.bfl.ai/v1/flux-2-pro`
- Authentication: `x-key` header from `BFL_API_KEY` environment secret
- Request mode: asynchronous
- Required provider input: prompt; width; height as normalized by the render contract
- Provider response must expose a polling URL; the adapter must use that returned URL and must not reconstruct it.
- Terminal provider states are accepted only as explicit success/failure states.
- A successful provider response yields an external image URL which is downloaded into the M21.17 validation pipeline.

## Credential gate
Missing, empty, or placeholder credentials produce `BLOCKED_MISSING_CREDENTIAL`. Credentials are never logged, serialized into project artifacts, committed, or returned in adapter output.

## Mock mode
A deterministic mock provider is mandatory for CI and architecture tests. Mock mode never calls the external API and returns a controlled WEBP fixture/reference for M21.17 validation.

## Failure states
`BLOCKED_MISSING_CREDENTIAL`, `BLOCKED_INVALID_REQUEST`, `BLOCKED_PROVIDER_ERROR`, `BLOCKED_PROVIDER_TIMEOUT`, `BLOCKED_PROVIDER_RESULT`, `READY_FOR_OUTPUT_VALIDATION`.

## Security
No API key in source code, fixtures, JSON artifacts, Git history, Telegram messages, or logs. Provider URLs and request IDs may be logged; secrets may not.

## Acceptance
1. Mock provider PASS without credentials.
2. Missing credential blocks real-provider execution.
3. Request normalization is deterministic.
4. Provider response is never treated as authoritative project truth.
5. Successful image output is handed to M21.17 WEBP validation.
6. External polling URL is consumed exactly as returned by provider.
