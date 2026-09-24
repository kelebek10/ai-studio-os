import json, urllib.request, urllib.error

URL = "http://127.0.0.1:8091/task"

def run(i):
    payload=json.dumps({"prompt":f"M18.5 controlled delegation test {i}: provide one short factual observation about evidence provenance. Do not approve or provision.","requires_human":True}).encode()
    req=urllib.request.Request(URL,data=payload,headers={"Content-Type":"application/json"},method="POST")
    with urllib.request.urlopen(req,timeout=90) as r:
        body=json.loads(r.read())
        assert r.status==200
        assert body["status"]=="HUMAN_GATE"
        assert body["review"]=="REVIEWED"
        assert body["human_gate"] is True
        assert body["evidence_digest"]
        assert body["correlation_id"]
        return body

if __name__ == "__main__":
    passed=0
    for i in range(1,11):
        b=run(i)
        passed += 1
        print(f"M18.5_TASK_{i}: PASS {b['correlation_id']}")
    print(f"M18.5_CONSECUTIVE_DELEGATION: {passed}/10 PASS")
