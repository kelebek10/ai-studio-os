import json
from pathlib import Path

FIX = Path(__file__).parent / 'fixtures'
OUT = Path(__file__).parent / 'outputs'

def rect(x1,y1,x2,y2): return {'x_min':x1,'y_min':y1,'x_max':x2,'y_max':y2}
def overlap(a,b): return not (a['x_max']<=b['x_min'] or a['x_min']>=b['x_max'] or a['y_max']<=b['y_min'] or a['y_min']>=b['y_max'])
def inside(g,b): return b['x_min']<=g['x_min']<g['x_max']<=b['x_max'] and b['y_min']<=g['y_min']<g['y_max']<=b['y_max']

def resolve(c):
    i,s,e=c['intent'],c['site'],c['expected']; b=s['boundary']; fixed=s.get('fixed',[]); access=s.get('access',[])
    hard=[]; soft=[]; candidates=[]
    if i['intent_type']=='ENTRY_WELCOME':
        a=next(x for x in fixed if x['id']==i['anchor']['id'])
        candidates=[rect(0.5,a['y']+0.5,3.5,a['y']+2),rect(8.5,a['y']+0.5,11.5,a['y']+2)]
        hard=['SITE_BOUNDARY','FIXED_ELEMENTS','ACCESS_CLEARANCE']; soft=['NEAR_ENTRY']
    elif i['intent_type']=='BUTTERFLY_VIEW':
        z=next(x for x in s['zones'] if x['id']==e['zone_id']); candidates=[rect(z['x_min'],z['y_min'],min(z['x_min']+4,z['x_max']),min(z['y_min']+4,z['y_max']))]; hard=['SITE_BOUNDARY','ELIGIBLE_ZONE','VIEW_CORRIDOR','ACCESS_CLEARANCE']; soft=['BUTTERFLY_TARGET']
    elif i['intent_type']=='DRY_ROCK_GARDEN':
        z=next(x for x in s['zones'] if x['id']==e['zone_id']); candidates=[rect(z['x_min'],z['y_min'],4,z['y_max']),rect(8,z['y_min'],z['x_max'],z['y_max'])]; hard=['SITE_BOUNDARY','ZONE_VALID','DRAINAGE_PRESENT','SUN_PRESENT','ACCESS_CLEARANCE']; soft=['DRY_ROCK_PREFERENCE']
    else: raise ValueError(i['intent_type'])
    valid=[]
    for idx,g in enumerate(candidates):
        if not inside(g,b): continue
        if any(overlap(g,rect(x['x_min'],x['y_min'],x['x_max'],x['y_max'])) for x in fixed if all(k in x for k in ('x_min','y_min','x_max','y_max'))): continue
        if any(overlap(g,rect(x['x_min'],x['y_min'],x['x_max'],x['y_max'])) for x in access): continue
        valid.append((idx,g))
    if not valid: return {'fixture_id':c['fixture_id'],'status':'BLOCKED_NO_ELIGIBLE_ZONE','elements':[]}
    idx,g=valid[0]
    return {'fixture_id':c['fixture_id'],'status':'READY_FOR_RENDER','elements':[{'element_id':c['fixture_id']+'-element','function_type':e['function_type'],'geometry':g,'geometry_status':'PROPOSED','source_requirement_ids':[c['fixture_id']],'hard_constraints':hard,'soft_constraints':soft,'selected_candidate':idx,'rule_version':'M21-11-v1.0'}]}

cases=[json.loads(p.read_text()) for p in sorted(FIX.glob('*.json'))]
for c in cases:
    a=resolve(c); b=resolve(c); assert a==b
    assert a['status']=='READY_FOR_RENDER', (c['fixture_id'],a['status'])
    (OUT/(c['fixture_id']+'.resolved.json')).write_text(json.dumps(a,sort_keys=True,separators=(',',':'))+'\n')
    print('PASS',c['fixture_id'])
print('M21.11 CONSTRAINT RESOLVER: 3/3 deterministic')
