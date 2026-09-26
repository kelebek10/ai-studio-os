import hashlib,json

def digest(x): return hashlib.sha256(json.dumps(x,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def adapt(scene, refs, provider='FLUX.2 Pro'):
    if scene.get('status')!='READY_FOR_RENDER': return {'status':'BLOCKED_SCENE_INVALID'}
    if not refs: return {'status':'BLOCKED_MISSING_REFERENCE'}
    if scene['scene_type'] not in {'DAY','DUSK','NIGHT'}: return {'status':'BLOCKED_UNSUPPORTED_SCENE'}
    return {'status':'READY_FOR_PROVIDER','provider':provider,'scene_id':scene['scene_id'],'layout_digest':scene['layout_digest'],'lighting_digest':scene['lighting_digest'],'reference_ids':refs,'output_format':'WEBP'}
layout={'id':'L','elements':[{'id':'path-01'}]}; lighting={'id':'X','elements':[{'id':'L1'}]}
base={'status':'READY_FOR_RENDER','scene_id':'SCENE-01','scene_type':'NIGHT','layout_digest':digest(layout),'lighting_digest':digest(lighting)}
assert adapt(base,['site-01'])['status']=='READY_FOR_PROVIDER'
assert adapt(base,[])['status']=='BLOCKED_MISSING_REFERENCE'
invalid=dict(base,status='BROKEN'); assert adapt(invalid,['site-01'])['status']=='BLOCKED_SCENE_INVALID'
unsupported=dict(base,scene_type='FOG'); assert adapt(unsupported,['site-01'])['status']=='BLOCKED_UNSUPPORTED_SCENE'
a=adapt(base,['site-01']); b=adapt(base,['site-01']); assert a==b
print('PASS READY_FOR_PROVIDER')
print('PASS BLOCKED_MISSING_REFERENCE')
print('PASS BLOCKED_SCENE_INVALID')
print('PASS BLOCKED_UNSUPPORTED_SCENE')
print('M21.16 FLUX ADAPTER GATE: 4/4 deterministic')
