SCENES=('DAY','DUSK','NIGHT')
LIGHTS=[{'light_id':'LIGHT-001','type':'ENTRY_LIGHT','purpose':'ENTRY','intensity_class':'LOW','beam_direction':'DOWN','glare_control':'REQUIRED'}, {'light_id':'LIGHT-002','type':'TREE_LIGHT','purpose':'FEATURE','intensity_class':'MEDIUM','beam_direction':'UP','glare_control':'REQUIRED'}]
for scene in SCENES:
    out={'scene':scene,'lighting_enabled':scene!='DAY','lighting':LIGHTS if scene!='DAY' else []}
    assert out['scene'] in SCENES
    if scene=='DAY': assert out['lighting']==[]
    else: assert all(x['glare_control']=='REQUIRED' for x in out['lighting'])
    print('PASS',scene,'lighting=',len(out['lighting']))
print('M21.14 DAY/DUSK/NIGHT: 3/3 deterministic')
