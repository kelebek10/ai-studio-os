from runtime.visual_artifact_orchestrator import VisualArtifactOrchestrator
from runtime.telegram_delivery_adapter import TelegramDeliveryAdapter

REQ={"render_request_id":"RR-23-001","status":"READY_FOR_PROVIDER"}
ART={"render_id":"R-23-001","sha256":"sha-23","status":"READY_FOR_DELIVERY","mime_type":"image/webp"}
o=VisualArtifactOrchestrator(TelegramDeliveryAdapter(token="TEST_ONLY_TOKEN"))
assert o.preflight({"status":"BLOCKED"},ART,"CHAT").status=="BLOCKED_RENDER_REQUEST"
assert o.preflight(REQ,None,"CHAT").status=="BLOCKED_MISSING_ARTIFACT"
assert o.preflight(REQ,dict(ART,status="READY_FOR_PROVIDER"),"CHAT").status=="BLOCKED_ARTIFACT_NOT_READY"
assert o.preflight(REQ,ART,None).status=="BLOCKED_MISSING_DESTINATION"
assert o.preflight(REQ,ART,"CHAT").status=="READY_FOR_DELIVERY"
print("M21.23 visual artifact orchestrator: 5/5 PASS")
