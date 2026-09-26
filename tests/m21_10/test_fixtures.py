import json
from pathlib import Path

ROOT = Path(__file__).parent / "fixtures"
REQUIRED = {"fixture_id", "intent", "site", "expected"}
INTENTS = {"ENTRY_WELCOME", "BUTTERFLY_VIEW", "DRY_ROCK_GARDEN"}
FUNCTIONS = {"ENTRY_WELCOME": "ENTRY_COMPOSITION", "BUTTERFLY_VIEW": "BUTTERFLY_GARDEN", "DRY_ROCK_GARDEN": "DRY_ROCK_GARDEN"}

def load_cases():
    return [json.loads(p.read_text()) for p in sorted(ROOT.glob("*.json"))]

def validate(case):
    assert REQUIRED <= case.keys(), f"missing fixture fields: {case['fixture_id']}"
    intent = case["intent"]
    site = case["site"]
    expected = case["expected"]
    assert intent["intent_type"] in INTENTS
    assert intent["priority"] in {"CRITICAL", "HIGH", "MEDIUM", "LOW"}
    assert intent["spatial_relation"]
    assert intent["anchor"]["id"]
    assert "boundary" in site
    assert expected["function_type"] == FUNCTIONS[intent["intent_type"]]
    assert expected["function_type"] != "FLUX"
    if intent["intent_type"] == "BUTTERFLY_VIEW":
        windows = [x for x in site.get("fixed", []) if x.get("id") == intent["anchor"]["id"]]
        assert windows and "view_direction_deg" in windows[0]
        assert expected["preserve_view_corridor"] is True
    if intent["intent_type"] == "DRY_ROCK_GARDEN":
        zones = [x for x in site.get("zones", []) if x.get("id") == intent["anchor"]["id"]]
        assert zones and zones[0].get("drainage") and zones[0].get("sun")
        assert expected["preserve_access"] is True
    return True

cases = load_cases()
assert len(cases) == 3, f"expected 3 canonical fixtures, got {len(cases)}"
for case in cases:
    validate(case)
    print(f"READY {case['fixture_id']}")
print(f"M21.10 FIXTURE CONTRACT: {len(cases)}/{len(cases)} valid")
