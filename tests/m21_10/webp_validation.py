import hashlib, mimetypes

def validate(a):
    if not a.get('exists'): return 'BLOCKED_INVALID_ARTIFACT'
    if a.get('format')!='WEBP' or a.get('mime')!='image/webp': return 'BLOCKED_FORMAT'
    if a.get('width',0)<512 or a.get('height',0)<512: return 'BLOCKED_DIMENSIONS'
    if a.get('layout_digest')!=a.get('expected_layout_digest') or a.get('lighting_digest')!=a.get('expected_lighting_digest'): return 'BLOCKED_DIGEST_MISMATCH'
    if a.get('scene_id')!=a.get('expected_scene_id'): return 'BLOCKED_METADATA_MISMATCH'
    if not a.get('sha256'): return 'BLOCKED_INVALID_ARTIFACT'
    return 'READY_FOR_DELIVERY'
base={'exists':True,'format':'WEBP','mime':'image/webp','width':1024,'height':768,'layout_digest':'L1','lighting_digest':'X1','expected_layout_digest':'L1','expected_lighting_digest':'X1','scene_id':'NIGHT-01','expected_scene_id':'NIGHT-01','sha256':hashlib.sha256(b'fixture').hexdigest()}
assert validate(base)=='READY_FOR_DELIVERY'
for key,expected in [('format','BLOCKED_FORMAT'),('width','BLOCKED_DIMENSIONS'),('layout_digest','BLOCKED_DIGEST_MISMATCH'),('scene_id','BLOCKED_METADATA_MISMATCH')]:
 x=dict(base); x[key]='BAD' if key not in {'width'} else 256; assert validate(x)==expected
print('PASS READY_FOR_DELIVERY')
print('PASS BLOCKED_FORMAT')
print('PASS BLOCKED_DIMENSIONS')
print('PASS BLOCKED_DIGEST_MISMATCH')
print('PASS BLOCKED_METADATA_MISMATCH')
print('M21.17 WEBP VALIDATION: 5/5 deterministic')
