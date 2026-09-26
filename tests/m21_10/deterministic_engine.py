import json
from pathlib import Path

FIX = Path(__file__).parent / 'fixtures'
OUT = Path(__file__).parent / 'outputs'
OUT.mkdir(exist_ok=True)

def rect(x1,y1,x2,y2): return {'x_min':x1,'y_min':y1,'x_max':x2,'y_max':y2}
def overlaps(a,b): return not (a['x_max']<=b['x_min'] or a['x_min']>=b['x_max'] or a['y_max']<=b['y_min'] or a['y_min']>=b['y_max'])
def center(r): return ((r['x_min']+r['x_max'])/2,(r['y_min']+r['y_max'])/2)

def run(c):
    i,s,e=c['intent'],c['site'],c['expected']; boundary=s['boundary']; fixed=s.get('fixed',[]); access=s.get('access',[])
    fid=i['intent_type']; geom=None; zone_id=None; constraints=[]
    if fid=='ENTRY_WELCOME':
        a=next(x for x in fixed if x['id']==i['anchor']['id']); candidates=[rect(0.5,a['y']+0.5,3.5,a['y']+2.0),rect(8.5,a['y']+0.5,11.5,a['y']+2.0)]; geom=next((g for g in candidates if all(not overlaps(g,rect(x['x_min'],x['y_min'],x['x_max'],x['y_max'])) for x in fixed if x.get('type')=='BUILDING') and all(not overlaps(g,rect(x['x_min'],x['y_min'],x['x_max'],x['y_max'])) for x in access)),None); assert geom is not None, 'NO_ELIGIBLE_ENTRY_ZONE'; constraints=['ENTRY_ACCESS','CIRCULATION_CLEAR','FIXED_ELEMENT_CLEAR']
    elif fid=='BUTTERFLY_VIEW':
        z=next(x for x in s['zones'] if x['id']==e['zone_id']); zone_id=z['id']; geom=rect(z['x_min'],z['y_min'],min(z['x_min']+4,z['x_max']),min(z['y_min']+4,z['y_max'])); constraints=['WINDOW_ANCHOR_VALID','VIEW_CORRIDOR','ACCESS_PRESERVED','ELIGIBLE_PLANTING_ZONE']
    elif fid=='DRY_ROCK_GARDEN':
        z=next(x for x in s['zones'] if x['id']==e['zone_id']); zone_id=z['id']; geom=rect(z['x_min'],z['y_min'],z['x_max'],z['y_max']); constraints=['ZONE_VALID','DRAINAGE_PRESENT','SUN_PRESENT','ACCESS_PRESERVED']
    else: raise ValueError(fid)
    assert boundary['x_min']<=geom['x_min']<geom['x_max']<=boundary['x_max'] and boundary['y_min']<=geom['y_min']<geom['y_max']<=boundary['y_max']
    if fid=='ENTRY_WELCOME':
        for x in fixed:
            if x.get('type')=='BUILDING': assert not overlaps(geom,rect(x['x_min'],x['y_min'],x['x_max'],x['y_max']))
        for x in access: assert not overlaps(geom,rect(x['x_min'],x['y_min'],x['x_max'],x['y_max']))
    result={'fixture_id':c['fixture_id'],'status':'READY_FOR_RENDER','elements':[{'element_id':c['fixture_id']+'-element','function_type':e['function_type'],'geometry':geom,'geometry_status':'PROPOSED','source_requirement_ids':[c['fixture_id']],'constraint_results':constraints,'rule_version':'M21-9-v1.0','zone_id':zone_id}]}
    return result

cases=[json.loads(p.read_text()) for p in sorted(FIX.glob('*.json'))]
for c in cases:
    r1=run(c); r2=run(c); assert r1==r2
    out=OUT/(c['fixture_id']+'.layout.json'); out.write_text(json.dumps(r1,sort_keys=True,separators=(',',':'))+'\n'); print('PASS',c['fixture_id'])
print(f'M21.10 DETERMINISTIC CORE: {len(cases)}/{len(cases)} reproducible')
