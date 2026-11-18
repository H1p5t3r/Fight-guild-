#!/usr/bin/env python3
"""Smoke's saved Dizzy normal baseline + Leo diagram corrections for Tapper.

Reads the immutable completed Tapper draft. Never reads/writes browser saves.
Other uploaded character values and artwork notes are preserved.
"""
from pathlib import Path
import copy, hashlib, json
ROOT=Path(__file__).resolve().parents[1]
SOURCE='2026-11-18-tapper/FightGuild-Tapper.json'
DEST='2026-11-18-smoke/FightGuild-Smoke-Tapper.json'
load=lambda p:json.loads((ROOT/p).read_text())
base=load('godot/data/starter_moves.json')
raw=(ROOT/'godot/data/workshop'/SOURCE).read_bytes(); draft=json.loads(raw)
fields=load('godot/data/stance_fields.json')
for data in [base,draft]:
    for c in data['characters']:
        if len(c['moves'])==43:
            for id,button in [('6[Hs]',3),('5[D]',4)]:
                m=copy.deepcopy(c['moves'][0]);m.update({f['key']:f['default'] for f in fields})
                m.update(id=id,button=button,category=1 if button==3 else 3,direction=6 if button==3 else 5,
                         motion=0,air=0,enabled=0,artPose=0,projectileKind=0,mechanic=0,
                         hurtboxes={},hitboxTimeline={'multiHit':False,'keys':[]})
                if data is base:m['hitPose']=1+button
                c['moves'].append(m)
        assert len(c['moves'])==45
draft['schema']=draft['coreVersion']=19
notes=draft.setdefault('_moveWorkshop',{'version':1,'notes':{}})['notes']
source=load('references/frame-data/queen-dizzy-2026-11-18/source.json')
rows={m['Input']:m for m in source['moves']}
traces=load('references/frame-data/queen-dizzy-2026-11-18/traces.json')['moves']

def key(frame,boxes,hit=1,**overrides):
    result=dict(frame=frame,hit=hit,boxes=copy.deepcopy(boxes),damage=-1,hitstun=-1,blockstun=-1,hitstop=-1)
    result.update(overrides)
    return result

def geometry(m,boxes):
    l=min(b[0] for b in boxes);bottom=min(b[1] for b in boxes)
    r=max(b[2] for b in boxes);top=max(b[3] for b in boxes)
    m.update(hitboxBack=l,reach=r,bottom=bottom,height=top-bottom)
    m['geometry']=[l,bottom,r,top]

entries=[('5P',0,'Vapor Check'),('5K',1,'Caustic Kick'),('c.S',32,'Chimney Coil'),('f.S',2,'Fivefold Fume'),
         ('5H',3,'Flashover'),('2P',4,'Low Pressure'),('2K',5,'Ankle Leak'),('2S',6,'Soot Ribbon'),
         ('2H',7,'Backdraft'),('2D',22,'Floor Spill'),('6P',8,'Updraft'),('6H',11,'Smoke Hammer'),
         ('6[H]',43,'Flashpoint Hammer'),('5D',13,'Fire Veil'),('5[D]',44,'Rising Ignition'),
         ('j.P',17,'Air Check'),('j.K',18,'Caustic Heel'),('j.S',19,'Vapor Lance'),('j.H',20,'Cinder Scythe'),('j.D',21,'Drifting Ember')]
visuals=[
 ('Shoulder-high palm chamber.','Short lime cloud from a high palm jab; narrow high horizontal reach.'),
 ('Load the knee, rear foot planted.','Long straight mid-height boot kick with a small lime vapor toe puff.'),
 ('Compress knees and coil the near hand.','Close, tall gray smoke curl rises beside the open palm.'),
 ('Draw the palm behind the torso.','Long pointed poison ribbon at chest height; five distinct pulses use one connected silhouette.'),
 ('Cup compressed vapor near the chest.','Three orange/ivory ignition pulses; final choking vapor causes extended stun. No damage-over-time status.'),
 ('Crouch with palm tucked beside chest.','Short shoulder-level lime palm check from a crouch; a mid.'),
 ('Low knee retracts.','Boot extends along the floor with a small poison puff; low.'),
 ('Low crouch and palm chamber.','Broad gray horizontal ribbon with lime edge; MID despite the crouching pose.'),
 ('Crouch and wind the arm down.','Tall orange/ivory fire column in front; the attack boxes change through three stages.'),
 ('Low coiled hand behind hip.','Long ankle-height poison sweep; universal hard knockdown.'),
 ('Compact lowered torso, protected raised forearm.','Diagonal upward slate smoke palm. Body stays vulnerable below the upper-body protection.'),
 ('Both palms load an unlit dense cloud overhead.','Compressed slate smoke mass driven down and forward; MID, not overhead.'),
 ('Hold the overhead cloud under pressure.','Ignited orange edge around the descending smoke hammer; guard crush, still MID.'),
 ('Hand coiled above/behind the head.','Short downward orange flame veil; overhead.'),
 ('Hold the compressed overhead ignition.','Larger overhead flare and launch; no homing jump subsystem.'),
 ('Tucked airborne palm chamber.','Short diagonal-down lime palm jab.'),
 ('Tucked airborne knees, arms guarded.','Diagonal down-forward boot with a poison toe puff.'),
 ('Airborne palm chamber, knees tucked.','Long thin horizontal slate/lime vapor lance.'),
 ('Airborne arm loaded behind head.','Broad downward charcoal smoke crescent with ember edge; drives airborne targets down.'),
 ('Tucked airborne body, tiny ember in palm.','Small fingertip release; separate slowly advancing fireball. Brief air stall then recoil.')]

smoke=copy.deepcopy(draft['characters'][2]);moves=smoke['moves']
# These command normals have no counterpart in the supplied kit.
for slot in [9,10,12,*range(33,43)]:moves[slot]['enabled']=0
for art,(src,slot,label) in enumerate(entries,1):
    r=rows[src];m=moves[slot]
    m.update({f['key']:f['default'] for f in fields})
    level=int(r['Level']) if r['Level'].isdigit() else 1 # j.D source leaves this blank.
    active=10 if src=='f.S' else 18 if src=='5H' else 1 if src=='j.D' else int(r['Active'])
    recovery=19 if src=='j.D' else int(r['Recovery'])
    last_active=2 if src=='f.S' else 6 if src=='5H' else active
    block=int(r['On-Block'])+last_active-1+recovery if not src.startswith('j.') else [9,11,13,16,18][level]
    hit=block+3
    m.update(enabled=1,startup=int(r['Startup']),active=active,recovery=recovery,damage=int(r['Damage'].split('×')[0]),
        hitstun=hit,blockstun=block,hitstop=8 if level<3 else 10,attackLevel=level,
        counterTier={'Very Small':0,'Small':1,'Mid':2,'Large':3}[r['Counter Type']],
        starterProration=int(r['Proration'].strip('%')),counterFreezeFrames=-1,counterSlowFrames=0,counterHitstop=3,counterHitstun=4,
        artPose=art,motion=0,air=int(src.startswith('j.')),mechanic=0,projectileKind=0,followFrom=-1,followFrom2=-1,followHit=0,
        advance=0,travelSpeed=0,pullFrames=0,hitAngle=0,guardBreak=0,chipDamage=0,
        hitLevel=1 if r['Guard']=='Low' else 2 if r['Guard']=='High' else 0,
        specialCancel=1,jumpCancel=int(src in ['5K','c.S','f.S','2S','j.K','j.S','j.H','j.D']),selfCancel=int(src in ['5P','2P','j.P']),whiffCancel=0,
        normalRoutes=-1,commandRoutes=-1,normalCancelStart=1,normalCancelEnd=0,specialCancelStart=1,specialCancelEnd=0,jumpCancelStart=1,jumpCancelEnd=0,
        followCancelStart=1,followCancelEnd=0,cancelOn=3,reversalEligible=0,
        knockdown=0,knockdownFrames=6,wakeupFrames=8,launch=0,airLaunch=700,pushback=700,airPushback=1400,blockPushback=600,
        hurtMaskWindup=15,hurtMaskActive=15,hurtMaskRecovery=15,hurtboxes={},smearMode=0,
        simpleDirection=0,simpleButton=m['button'],landingRecovery=3 if src.startswith('j.') else 0)
    source_move='6H' if src=='6[H]' else '5D' if src=='5[D]' else src
    trace=traces[source_move]
    geometry(m,trace[0]['boxes'])
    m['hitboxTimeline']={'multiHit':src in ['f.S','5H'],'keys':[key(t['activeFrame'],t['boxes']) for t in trace]}
    if src=='f.S':m['hitboxTimeline']['keys']=[key(f,trace[0]['boxes'],i+1) for i,f in enumerate([1,3,5,7,9])]
    if src=='5H':
        m['hitstun']=19
        m['hitboxTimeline']['keys']=[key(f,trace[0]['boxes'],i+1) for i,f in enumerate([1,7,13])]
        m['hitboxTimeline']['keys'][-1]['hitstun']=89
    if src=='c.S':m.update(button=2,category=0,direction=5,groundBounce=1100,blockPushback=300)
    if src=='f.S':m.update(proximityMove=32,proximityRange=11000)
    if src=='5K':m['airLaunch']=1100
    if src=='2H':m.update(launch=1600,airLaunch=1600,knockdown=1)
    if src=='2D':m.update(knockdown=2,knockdownFrames=65,wakeupFrames=8)
    if src=='6P':m.update(hurtWindowStart=1,hurtWindowEnd=17,hurtWindowMask=1,airCounterKnockdown=2)
    if src=='6H':m.update(actionType=5,holdFollow=43,holdFrame=36)
    if src=='6[H]':m.update(groundBounce=1100,guardBreak=1,knockdown=1,launch=1000,knockdownFrames=29)
    if src=='5D':m.update(actionType=5,holdFollow=44,holdFrame=28,hitstun=28,hitstop=16)
    if src=='5[D]':m.update(launch=1500,airLaunch=1500,knockdown=1,knockdownFrames=28,hitstop=16)
    if src=='j.H':m.update(airLaunch=-900,groundBounce=800)
    if src=='j.D':
        l,b,rr,t=m['geometry'];m.update(projectileKind=1,projectileSpawnFrame=16,projectileSpeedX=220,projectileSpeedY=0,
            projectileGravity=0,projectileLife=90,projectileOffsetX=(l+rr)//2,projectileOffsetY=(b+t)//2,
            projectileWidth=rr-l,projectileHeight=t-b,projectileHits=1,projectileDurability=1,projectilePersist=1,projectileMelee=0,
            actionType=6,diveSpeedX=-220,diveSpeedY=0)
        m['hitboxTimeline']={'multiHit':False,'keys':[]}
    wind,active_brief=visuals[art-1]
    notes['Smoke/'+m['id']]={'label':label,'intent':f'Queen Dizzy {src}: {r["Startup"]}/{r["Active"] or "projectile"}/{r["Recovery"]}; source damage {r["Damage"]}, on block {r["On-Block"]}. Saved 18 Nov 2026. Attack rectangles traced from embedded diagrams and scaled; spatial calibration/transition keys remain editable. Fight Guild gatlings and body-only hurtboxes apply.',
        'windup':wind+' Fixed olive/ivory/brown costume, dark hair, mature slim proportions. No emitted smear.',
        'active':active_brief+' Lime gas, slate smoke and orange/ivory fire use hard-edged cel-shaded shapes. No transition smear frames.'}
    if src=='j.D':notes['Smoke/'+m['id']]['intent']+=' Actor emission counts as the first of 20 recovery ticks (1 active +19 recovery). Projectile speed/life, recoil and unspecified level1 are provisional.'
    if src=='5H':notes['Smoke/'+m['id']]['intent']+=' Final hit uses 89f choking stun to reproduce +69 timing; this is not the full Strive Frozen State system.'
    m['hitPose']=1+m['button']
for m in smoke['moves']:
    m['hitPose']=1+m['button']
    m.setdefault('geometry',[m['hitboxBack'],m['bottom'],m['reach'],m['bottom']+m['height']])
base['characters'][2]=copy.deepcopy(smoke)
for m in smoke['moves']:m.pop('hitPose',None);m.pop('geometry',None)
draft['characters'][2]=smoke

# Leo images adjust only Tapper's attack geometry. Timing, damage, motion,
# custom Drive, rolling stance, grabs and player-authored body fits stay intact.
leo=load('references/frame-data/leo-whitefang-2026-11-18/traces.json')['moves']
mapping={'5P':0,'5K':1,'c.S':32,'2P':4,'2K':5,'2S':6,'2H':7,'j.P':17,'j.K':18,'j.S':19,'j.H':20,'6K':9,'6H':11,'[s/h] h/s':34}
for src,slot in mapping.items():
    for data in [base,draft]:
        m=data['characters'][3]['moves'][slot];ts=leo[src];geometry(m,ts[0]['boxes'])
        if src=='j.S':
            for k in m['hitboxTimeline']['keys']:
                if k['frame'] in [1,7]:k['boxes']=copy.deepcopy(ts[0 if k['frame']==1 else 1]['boxes'])
        else:m['hitboxTimeline']={'multiHit':False,'keys':[key(t['activeFrame'],t['boxes']) for t in ts]}
        if data is draft:m.pop('geometry',None)
    note=notes.setdefault('Tapper/'+draft['characters'][3]['moves'][slot]['id'],{})
    note['intent']=note.get('intent','')+' Attack boxes corrected from the uploaded Leo hitbox diagrams; scaled geometry, not a numeric engine dump.'

(ROOT/'godot/data/starter_moves.json').write_text(json.dumps(base,indent=2)+'\n')
out=ROOT/'godot/data/workshop'/DEST;out.parent.mkdir(exist_ok=True,parents=True)
out.write_text(json.dumps(draft,indent=2,ensure_ascii=False)+'\n')
manifest={'label':'Smoke normals + Tapper box corrections ·18 November2026','status':'playable reference-based iteration',
    'file':DEST,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'sourceFile':SOURCE,'sourceSha256':hashlib.sha256(raw).hexdigest(),
    'previousFile':SOURCE,'baseCommit':'7689c65','note':'Queen Dizzy frame data and traced normal hitboxes for Smoke; Leo diagrams correct Tapper normal hitboxes only. Preserves Tapper custom stance, Fillet/Shark edits and existing artwork notes. Local drafts remain untouched.'}
(ROOT/'godot/data/workshop/current.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
print('Authored 20 Smoke source normals; corrected 14 Tapper actions; schema19 draft preserves other characters.')
