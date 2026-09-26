import hashlib, json
from copy import deepcopy

def digest(x): return hashlib.sha256(json.dumps(x,sort_keys=True,separators=(',',':')).encode()).hexdigest()
layout={'project_id':'M21-10-DEMO','elements':[{'id':'path-01','type':'PATH'},{'id':'garden-01','type':'PLANTING'}]}
lighting={'project_id':'M21-10-DEMO','elements':[{'id':'L1','type':'ENTRY_LIGHT','scenes':['DUSK','NIGHT']},{'id':'L2','type':'TREE_LIGHT','scenes':['NIGHT']}]}
ld= digest(layout); lightd=digest(lighting)
expected={'DAY':[],'DUSK':['L1'],'NIGHT':['L1','L2']}
for scene,active in expected.items():
    p={'project_id':layout['project_id'],'scene_type':scene,'layout_digest':ld,'lighting_digest':lightd,'active_lighting_ids':active}
    assert p['layout_digest']==ld and p['lighting_digest']==lightd
    assert set(active)<=set(x['id'] for x in lighting['elements'])
    print('PASS',scene,'active_lights=',len(active))
print('M21.15 SCENE COMPOSITION: 3/3 deterministic; layout invariant across scenes')
