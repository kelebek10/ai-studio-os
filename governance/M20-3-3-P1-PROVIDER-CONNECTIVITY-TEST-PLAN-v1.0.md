# M20.3.3-P1 — NONPROD Provider Connectivity Test Contract

## Scope
Claude, Gemini and Copilot gerçek provider bağlantısını NONPROD ortamında doğrulamak.

## Hard Invariants
- Registry `enabled=false` kalır; test hiçbir şekilde enable etmez.
- Provider capability `enabled=false` kalır.
- Production erişimi yoktur.
- Secret değerleri loglanmaz, Git'e yazılmaz.
- Provider erişilebilir olsa bile registry disabled olduğu için dispatch BLOCKED olmalıdır.

## Test Sequence
T01 credential presence (value disclosure yok)
T02 endpoint reachability
T03 minimum-cost authentication + single request
T04 provider/model identity evidence
T05 registry enabled-state before/after
T06 disabled-provider dispatch must BLOCK
T07 secret leakage scan
T08 invalid credential/endpoint/timeout/4xx/5xx failure handling
T09 retry boundary max 3; unresolved => BLOCKED
T10 cross-provider isolation
T11 evidence contract
T12 final invariant: Claude/Gemini/Copilot enabled=false; capabilities enabled=false

## PASS Criteria
Gerçek bağlantı + authentication + minimal request + evidence + no secret leakage + failure isolation + enabled=false before/after + dispatch BLOCKED.

## Gates
- Gate A: Connectivity
- Gate B: Registry protection
- Gate C: Dispatch protection
- Gate D: Evidence integrity

## Provider Credential Sources
Credentials must already exist in the secure NONPROD runtime environment. Never paste secrets into chat.
- Claude: approved Anthropic credential/enterprise route
- Gemini: approved Google Gemini API credential
- Copilot: explicit approved GitHub/Copilot credential; do not rely on interactive login fallback

## Next Gate
All provider tests PASS before M20.3.4 Operational Activation.