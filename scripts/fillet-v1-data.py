#!/usr/bin/env python3
"""Install the selected Fillet contract without replacing another fighter's tuning/art.

The JSON extension layout is shared by the integer core and both editor adapters.
The immutable implementation package remains the reviewable source of this import.
"""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGIONS = ['legs', 'torsoArms', 'head', 'extension']
ACTION_PARAMS = 'policy contactKind groundLeft groundBottom groundRight groundTop airLeft airBottom airRight airTop lowCrushStart lowCrushEnd passStart passEnd refaceFrame stopAtBody groundedLift bleedDelay bleedWindowStart bleedWindowEnd captureFreeze pairTicks releaseFreeze ownerRecovery victimRecovery releaseGap throwGrace techTicks pairTrack friction'.split()
CHAR_PARAMS = 'policy bleedDuration bleedInitial bleedGrowth bleedInterval bleedBlockPercent bleedCap groundSpeedPercent airSpeedPercent coastCap backdashLock halfWidth standingHeight crouchingHeight airBottom airTop walkStride runStride'.split()
PROFILE_NAMES = ['ready','crouch','air','hit_reel'] + [f'{name}/{i}' for name,n in [('walk_keys',8),('backwalk_keys',8),('run_keys',8),('block_keys',6)] for i in range(n)] + ['hard_downed','soft_downed'] + [f'wakeup_keys/{i}' for i in range(4)] + ['backdash','prejump','airdash_pause','airdash_burst','landing']

def body(boxes):
    return [sum(1 << i for i,r in enumerate(REGIONS) if r in boxes)] + [v for r in REGIONS for v in boxes.get(r,[0]*4)]

def layout():
    # Named parameters stay readable in JSON; arrays pack only at the engine boundary.
    return {'version':1,'actionParams':ACTION_PARAMS,'characterParams':CHAR_PARAMS,
            'profiles':PROFILE_NAMES,'routeNames':['normal','special','follow','bleed'],
            'actionSections':[['params',30,1],['routes',4,2],['hurtboxes',32,18],['pushboxes',8,5],['rootTrack',8,5],['verticalRootKeys',8,2]],
            'characterSections':[['params',18,1],['profiles',len(PROFILE_NAMES),17],['pairTracks',4,41]]}

def action_ext(a,ids):
    move=a['movement']; routes=a['cancels']; capture=a.get('capture',a.get('wound',{}))
    kind=3 if a['id']=='5D' else 2 if a['id'] in ('236D','214D') else 1 if a['id'] in ('4P+K','6P+K') else 0
    low=a['contacts']['lowCrushFrames'] or [0,0]
    params=[1,kind,*a['pushbox']['ground'],*a['pushbox']['air'],*low,
            9 if a['id']=='236K' else 0,20 if a['id']=='236K' else 0,21 if a['id']=='236K' else 0,
            int(kind==2),int(bool(move.get('verticalRootKeys'))),5,*routes.get('bleedGrabWindow',[0,0]),
            capture.get('captureHitstop',0),capture.get('pairTicks',0),capture.get('releaseHitstop',0),
            capture.get('actorPostReleaseTicks',0),capture.get('victimPostReleaseTicks',0),capture.get('releaseCenterGap',0),
            capture.get('graceAfterVictimActionability',capture.get('postReleaseThrowGrace',5 if kind else 0)),
            6 if kind==1 else 0,0 if kind==3 else 2 if a['id']=='4P+K' else 1 if kind==1 else 3 if kind==2 else 0,
            move['attackFrictionPerTick']]
    assert len(params)==len(ACTION_PARAMS)
    return {'version':1,'params':dict(zip(ACTION_PARAMS,params)),
            'routes':{name:sorted(ids.index(x) for x in routes[key]) for name,key in zip(['normal','special','follow','bleed'],['normalTargets','specialTargets','followTargets','bleedGrabTargets'])},
            'hurtboxes':copy.deepcopy(a['hurtboxTimeline']['keys']),
            'pushboxes':copy.deepcopy(a.get('pushboxTimeline',{}).get('keys',[])),
            'rootTrack':[{k:r.get(k,0) for k in ['first','last','dx','dy']} | {'collision':1 if any(word in r.get('collision','') for word in ['ignore','pass_through']) else 2 if 'stop_at' in r.get('collision','') else 0} for r in move['rootTrack']],
            'verticalRootKeys':copy.deepcopy(move.get('verticalRootKeys',[])),
            'art':{'name':a['name'],'role':a['role'],'animation':a['animation'],'hitboxGuide':a['hitboxTimeline'],**({'rig':a['productionRig']} if 'productionRig' in a else {})}}

def character_ext(spec):
    m=spec['movementContract'];b=spec['bleed'];p=m['pushProfile']
    params=[1,b['duration'],b['initialGrey'],b['tickGrey'],b['tickInterval'],b['blockGreyPercent'],b['cap'],b['groundMovementPercent'],b['airDashPercent'],m['postAirDashCoastExtension']['baseCapRaw'],4,p['halfWidth'],p['standingHeight'],p['crouchingHeight'],p['airBottom'],p['airBottom']+p['airHeight'],1900,3360]
    profiles={}
    for name in PROFILE_NAMES:
        parts=name.split('/'); v=m['collisionProfiles'][parts[0]]
        if len(parts)>1:v=v[int(parts[1])]
        profiles[name]=v['boxesLocalRaw']
    pairs=[]
    for contract in m['pairedThrowGuide']['contracts'][:4]:
        pairs.append([{'tick':k['C'],'owner':[int(v*100) for v in k['owner']],'victim':[0,0] if isinstance(k['victim'],str) else [int(v*100) for v in k['victim']]} for k in contract['rootTrack']])
    assert len(pairs)==4
    return {'version':1,'params':dict(zip(CHAR_PARAMS,params)),'profiles':profiles,'pairTracks':pairs,
            'art':{'movementContract':m,'direction':spec['lockedDirection']}}

def pack(ext,char=False):
    if not ext:return [0]*(947 if char else 714)
    if char:
        out=[ext['params'][k] for k in CHAR_PARAMS]
        for name in PROFILE_NAMES:out+=body(ext['profiles'][name])
        for track in ext['pairTracks']:
            out += [len(track)] + [v for k in track for v in [k['tick'],*k['owner'],*k['victim']]] + [0]*((8-len(track))*5)
        return out
    out=[ext['params'][k] for k in ACTION_PARAMS]
    for name in ['normal','special','follow','bleed']:
        bits=sum(1<<slot for slot in ext['routes'][name])
        for word in [bits&0xffffffff,bits>>32]:out.append(word if word<2**31 else word-2**32)
    for name,max_count,width,convert in [
        ('hurtboxes',32,18,lambda k:[k['frame'],*body(k['boxes'])]),
        ('pushboxes',8,5,lambda k:[k['frame'],*k['box']]),
        ('rootTrack',8,5,lambda k:[k['first'],k['last'],k['dx'],k['dy'],k['collision']]),
        ('verticalRootKeys',8,2,lambda k:[k['frame'],k['y']])]:
        keys=ext[name];out += [len(keys)]+[v for k in keys for v in convert(k)]+[0]*((max_count-len(keys))*width)
    return out

def apply_playtest_routes(fillet):
    """November 20 tuning: explicit OTG confirms, without rewriting the v1 packet."""
    for slot in (6, 26, 27):
        action = fillet['moves'][slot]
        assert action['knockdown'] == 2 and fillet['moves'][13]['extensions']['params']['contactKind'] == 3
        action['extensions']['routes']['special'] = sorted(set(action['extensions']['routes']['special']) | {13})


def install():
    spec=json.loads((ROOT/'art/characters/fillet-v1/FILLET_SPEC.json').read_text())
    src=ROOT/'godot/data/starter_moves.json';data=json.loads(src.read_text())
    for c in data['characters']:
        if len(c['moves'])==45:
            for id_,motion in [('236D',236),('214D',214)]:
                m=copy.deepcopy(c['moves'][12]);m.update(id=id_,motion=motion,enabled=0,category=4,button=4,mechanic=0,followFrom=-1,followFrom2=-1,air=0,artPose=0,hitPose=5)
                m.pop('path',None);m.pop('geometry',None);m['hitboxTimeline']={'multiHit':False,'keys':[]};m['hurtboxes']={}
                c['moves'].append(m)
    fillet=data['characters'][5];ids=[m['id'] for m in fillet['moves']]
    fillet['movement']=spec['movementContract']['mobility42'];fillet['extensions']=character_ext(spec)
    for a in spec['actions']+spec['disabledStableSlots']:
        i=a['slot'];old=fillet['moves'][i];m=dict(a['schema22Scalars'],id=a['id'],hitPose=1+a['schema22Scalars']['button'])
        m['geometry']=[m['hitboxBack'],m['bottom'],m['reach'],m['bottom']+m['height']]
        m['hitboxTimeline']=a['hitboxTimeline'];m['hurtboxes']=a.get('legacyHurtPhaseFallback',a.get('hurtboxes',{}))
        if a in spec['actions']:m['extensions']=action_ext(a,ids)
        fillet['moves'][i]=m
    apply_playtest_routes(fillet)
    src.write_text(json.dumps(data,indent=2)+'\n')
    (ROOT/'godot/data/extension_layout.json').write_text(json.dumps(layout(),indent=2)+'\n')
    print('Imported 26 enabled Fillet actions, 21 disabled stable slots; other 5 fighters preserved.')
    print('Action extension words:',len(pack(action_ext(spec['actions'][0],ids))))
    print('Character extension words:',len(pack(fillet['extensions'],True)))

if __name__=='__main__':install()
