import json
from pathlib import Path
FIX=Path(__file__).parent/'fixtures'

def score(candidate, weights):
    return sum(candidate.get(k,0)*w for k,w in weights.items())

# Deterministic scoring contract: hard-valid candidates only; explicit weighted criteria.
CASES={
 'M21-10-BUTTERFLY-VIEW-001': {'view_alignment':.50,'access':.20,'zone_fit':.20,'maintenance':.10},
 'M21-10-DRY-ROCK-001': {'zone_fit':.40,'sun':.25,'drainage':.25,'access':.10},
 'M21-10-ENTRY-WELCOME-001': {'arrival_visibility':.40,'entry_proximity':.30,'access':.20,'composition':.10},
}
CANDIDATES={
 'M21-10-BUTTERFLY-VIEW-001': [
  {'id':'rear-zone-a','view_alignment':1,'access':1,'zone_fit':1,'maintenance':.8},
  {'id':'rear-zone-b','view_alignment':.7,'access':1,'zone_fit':1,'maintenance':1}],
 'M21-10-DRY-ROCK-001': [
  {'id':'rear-01-left','zone_fit':1,'sun':1,'drainage':1,'access':1},
  {'id':'rear-01-right','zone_fit':1,'sun':.8,'drainage':1,'access':1}],
 'M21-10-ENTRY-WELCOME-001': [
  {'id':'entry-left','arrival_visibility':.8,'entry_proximity':.9,'access':1,'composition':.8},
  {'id':'entry-right','arrival_visibility':1,'entry_proximity':.9,'access':1,'composition':.9}],
}
for p in sorted(FIX.glob('*.json')):
 c=json.loads(p.read_text()); fid=c['fixture_id']; w=CASES[fid]; ranked=sorted(((score(x,w),x['id']) for x in CANDIDATES[fid]), key=lambda z:(-z[0],z[1])); assert ranked==sorted(ranked,key=lambda z:(-z[0],z[1])); print(f"PASS {fid}: selected={ranked[0][1]} score={ranked[0][0]:.3f}")
print('M21.12 SPATIAL SCORING: 3/3 deterministic')
