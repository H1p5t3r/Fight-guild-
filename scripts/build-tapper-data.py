#!/usr/bin/env python3
"""Author the first Tapper kit over the immutable third workshop batch.
Re-running reproduces the shipped authoring draft; never reads browser/local saves.
"""
from pathlib import Path
import copy, hashlib, json
R=Path(__file__).resolve().parents[1]
SOURCE='2026-11-17-batch-03/FightGuild-moves-2026-11-17 _2_.json'
DEST='2026-11-18-tapper/FightGuild-Tapper.json'
raw=(R/'godot/data/workshop'/SOURCE).read_bytes();draft=json.loads(raw)
fields=json.loads((R/'godot/data/stance_fields.json').read_text())
base=json.loads((R/'godot/data/starter_moves.json').read_text())
for c,defaults in zip(draft['characters'],base['characters']):
    for m in c['moves']:m.update({r['key']:r['default'] for r in fields})
    c['moves'] += [dict(copy.deepcopy(c['moves'][0]), id=m['id']) for m in defaults['moves'][32:]]
    for m in c['moves'][32:]:m.update(enabled=0,hurtboxes={},hitboxTimeline={'multiHit':False,'keys':[]});m.pop('hitPose',None)
draft['schema']=draft['coreVersion']=18
t=draft['characters'][3];moves=t['moves']
t['movement'].update(forwardStyle=1,stepSpeed=900,stepFrames=16,backStyle=1,backSpeed=800,backFrames=14,walkSpeed=300,backWalkSpeed=250,airDashEnabled=1,airBackdashEnabled=1)
source=json.loads((R/'references/frame-data/leo-whitefang-2026-11-18.json').read_text())
byid={m['sourceMove']:m for m in source['moves']}
notes=draft.setdefault('_moveWorkshop',{'version':1,'notes':{}})['notes']
# Source input, slot, art index (one based), horizontal reach, bottom, height in game units.
entries=[('5P',0,1,6000,9000,3500),('5K',1,2,8000,5000,3500),('c.S',32,3,7000,4000,10000),('f.S',2,4,14000,7500,3500),('5H',3,5,15000,5000,7000),('2P',4,6,5500,5000,3000),('2K',5,7,8500,0,3200),('2S',6,8,12000,0,4000),('2H',7,9,10000,1500,14000),('2D',22,10,10500,0,3500),('6P',8,11,6500,7000,8000),('6K',9,12,8500,5000,4500),('6H',11,13,15000,5000,6000),('j.P',17,14,6000,3000,4500),('j.K',18,15,8500,2000,5000),('j.S',19,16,10000,3500,6500),('j.H',20,18,13000,3500,5000),('j.D',21,19,9000,-1000,7000)]
for m in moves:
    m.update(enabled=0,stanceRequired=1,mechanic=0,artPose=0,finishArtPose=0,finishArtFrame=0,holdFollow=-1,holdFrame=0,proximityMove=-1,
             advance=0,travelSpeed=0,guardBreak=0,followFrom=-1,followFrom2=-1,followHit=0,hurtboxes={},hitboxTimeline={'multiHit':False,'keys':[]},projectileKind=0)
for src,slot,art,reach,bottom,height in entries:
    m=moves[slot];r=byid[src];f=r['frames'][0];detail=r['details'][0]
    startup=int(f['Startup']);active=9 if src=='j.S' else 1 if src=='j.D' else int(f['Active']);recovery=int(f['Recovery'])
    level=int(detail['Level']);block=f.get('Derived stationary blockstun',[9,11,13,16,18][level]);hit=block+3
    if src=='6P':hit=28
    damage=int(f['Damage'].split()[0]) if src!='j.S' else 24
    m.update(enabled=1,startup=startup,active=active,recovery=recovery,damage=damage*2,hitstun=hit,blockstun=block,hitstop=8 if level<3 else 10,
             reach=reach,bottom=bottom,height=height,hitboxBack=1000,artPose=art,normalRoutes=-1,commandRoutes=-1,
             normalCancelStart=1,normalCancelEnd=0,specialCancelStart=1,specialCancelEnd=0,jumpCancelStart=1,jumpCancelEnd=0,followCancelStart=1,followCancelEnd=0,cancelOn=3,
             attackLevel=level,counterTier={'Small':1,'Mid':2,'Large':3}[detail['CH Type']],starterProration=int(detail['Proration'].strip('%')),
             specialCancel=int(src!='2D'),jumpCancel=int(src in ['5K','2K','c.S','f.S','2S','j.P','j.K','j.S','j.H','j.D']),selfCancel=int(src in ['5P','2P','j.P']),whiffCancel=0,
             hitLevel=1 if f['Guard']=='Low' else 2 if f['Guard']=='High' else 0,knockdown=0,launch=0,airLaunch=700,knockdownFrames=6,wakeupFrames=8,
             counterFreezeFrames=-1,counterSlowFrames=0,counterHitstop=3,counterHitstun=4,smearMode=0,
             pushback=1000,airPushback=1800,blockPushback=1000)
    if src=='c.S':m.update(button=2,category=0,direction=5,air=0,simpleDirection=0,groundBounce=1100,blockPushback=450)
    notes['Tapper/'+m['id']]={'label':{'c.S':'Close Slash','f.S':'Far Slash'}.get(src,m['id']), 'intent':r['utility']+' Timing source: saved Leo revision581554. Damage is provisionally 2x the source, for Fight Guild’s1000HP; spatial values are adapted.', 'windup':'Generated Tapper normal-kit windup. Keep mature anatomy, burgundy/ochre brewer costume and double-hook staff fixed.', 'active':'Dedicated contact pose. Body hurtboxes exclude staff, hooks, tankard and cloth. No transition smear frames.'}
moves[2].update(proximityMove=32,proximityRange=9500,holdFollow=33,holdFrame=22)
moves[3].update(holdFollow=33,holdFrame=23,wallBounce=1000,hitboxTimeline={'multiHit':False,'keys':[{'frame':3,'hit':1,'boxes':[[1000,0,15000,10000]],'damage':-1,'hitstun':-1,'blockstun':-1,'hitstop':-1}]})
for slot,speed in [(1,160),(9,220),(11,230)]:moves[slot]['startupTravel']=speed
moves[7].update(launch=1500,airLaunch=1500,knockdown=1)
moves[8].update(hurtMaskWindup=15,hurtMaskActive=15,hurtMaskRecovery=15,hurtWindowStart=1,hurtWindowEnd=14,hurtWindowMask=1,crumpleFrames=28,airCounterKnockdown=2)
moves[11]['groundBounce']=1100
moves[22].update(knockdown=2,knockdownFrames=59,wakeupFrames=8,semiAirStart=5,semiAirEnd=18)
moves[19].update(finishArtPose=17,finishArtFrame=7,hitboxTimeline={'multiHit':True,'keys':[
 {'frame':1,'hit':1,'boxes':None,'damage':-1,'hitstun':-1,'blockstun':-1,'hitstop':-1},
 {'frame':4,'hit':1,'boxes':[],'damage':-1,'hitstun':-1,'blockstun':-1,'hitstop':-1},
 {'frame':7,'hit':2,'boxes':[[1000,5000,10000,14000]],'damage':-1,'hitstun':-1,'blockstun':-1,'hitstop':-1}]})
moves[21].update(actionType=3,diveSpeedX=650,diveSpeedY=-1100,landingRecovery=15,groundBounce=1000,wallBounce=900,airLaunch=-500)
def custom(slot,art,button,category,direction,startup,active,recovery,damage,block=16,**kw):
    id=moves[slot]['id'];m=copy.deepcopy(moves[0]);m.update(id=id,button=button,category=category,direction=direction,artPose=art,hitPose=1+button,
        startup=startup,active=active,recovery=recovery,damage=damage,blockstun=block,hitstun=block+4,selfCancel=0,jumpCancel=0,specialCancel=0,enabled=1,
        reach=7000,bottom=4000,height=8000,air=0,hitLevel=0,knockdown=0,counterTier=2,starterProration=100)
    m.update(kw);m.pop('hitPose',None);moves[slot]=m;return m
custom(33,20,2,0,5,5,1,16,0,actionType=1,guardFollow=34,holdButton=2,hitboxTimeline={'multiHit':False,'keys':[{'frame':1,'hit':1,'boxes':[],'damage':-1,'hitstun':-1,'blockstun':-1,'hitstop':-1}]})
custom(34,21,3,0,5,10,3,14,84,armorFrames=9,armorHits=1,knockdown=1,knockdownFrames=40,starterProration=60,reach=10000,specialCancel=1)
custom(13,22,4,3,5,18,3,22,65,actionType=4,grabFrames=20,finishArtPose=23,finishArtFrame=8,stanceChange=1,knockdown=1,knockdownFrames=32,throwRange=1600,reach=7000,blockPushback=1300)
for slot,dir in [(23,4),(24,6)]:custom(slot,22,0,4,dir,5,3,38,160,actionType=4,grabFrames=20,finishArtPose=23,finishArtFrame=8,stanceChange=1,knockdown=2,knockdownFrames=80,wakeupFrames=8,starterProration=50,throwRange=2000,pushback=500,blockPushback=0)
for slot,dir in [(41,4),(42,6)]:custom(slot,24,0,4,dir,5,3,38,160,air=1,knockdown=2,knockdownFrames=48,airLaunch=-900,starterProration=50,throwRange=2000,landingRecovery=10)
custom(35,25,0,0,5,7,4,12,48,block=13,stanceRequired=2,hurtWindowStart=1,hurtWindowEnd=10,hurtWindowMask=1)
custom(36,26,1,0,5,8,3,12,48,block=13,stanceRequired=2,hitLevel=1,bottom=0,height=3500,reach=8000)
custom(37,27,2,0,5,5,3,6,48,block=11,stanceRequired=2,selfCancel=1,blockPushback=350,reach=7000)
custom(38,28,3,0,5,18,4,21,85,stanceRequired=2,hitLevel=2,groundBounce=1100,startupTravel=80,reach=9000)
custom(39,29,4,1,2,5,1,6,0,stanceRequired=2,stanceChange=2,actionType=2,hitboxTimeline={'multiHit':False,'keys':[{'frame':1,'hit':1,'boxes':[],'damage':-1,'hitstun':-1,'blockstun':-1,'hitstop':-1}]})
custom(40,30,4,4,5,18,14,28,140,stanceRequired=2,stanceChange=1,motion=236,simpleDirection=6,simpleButton=4,actionType=4,grabFrames=24,finishArtPose=31,finishArtFrame=12,startupTravel=550,travelSpeed=650,throwRange=1600,knockdown=2,knockdownFrames=64,wakeupFrames=8,pushback=500,starterProration=50)
labels={13:('Collar Break','Blockable mid entry: collar grab, headbutt, then rolling stance on hit. Block leaves normal stance.'),23:('Back collar throw','Back throw, headbutt, hard knockdown, enter rolling stance.'),24:('Collar throw','Forward throw, headbutt, hard knockdown, enter rolling stance.'),33:('Held guard','Hold S after far Slash or Hs after Heavy Slash. Guards mids/highs; lows/throws win. Opposite S/Hs starts the guard attack.'),34:('Guard attack','Opposite-button attack from held guard: one-hit mid/high armor on frames1–9, 10f attack, even on block.'),35:('Rolling check','Stance punch; cross-cancel to other stance normals or2D. Provisional7/4/12.'),36:('Low kick','Stance low branch. Provisional8/3/12. Freely chains to other stance normals.'),37:('Hook','Fast stance MID. Provisional5/3/6,+3; can cancel into itself, tick throw or frame trap. Throw immunity still applies.'),38:('Overhand','Stance overhead. Provisional18/4/21; free cross-normal stance gatlings override Leo backturn routes.'),39:('Stance exit','2D exits rolling stance with11 total committed frames. Cancels from stance normals on contact. No attack hitbox.'),40:('Running tackle','Confirmed236D in rolling stance. Run→capture/tackle→one strong punch→rolling stance. Throw checks occur only when in range and after blockstun/throw immunity. Provisional tuning.'),41:('Air back throw','Airborne4P+K. Both-side catch, hard knockdown, back side switch.5f minimum adaptation.'),42:('Air throw','Airborne6P+K. Both-side catch, hard knockdown.5f minimum adaptation.')}
for slot,(label,intent) in labels.items(): notes['Tapper/'+moves[slot]['id']]={'label':label,'intent':intent,'windup':'Dedicated generated anticipation; same adult proportions, costume and hooked staff. Stance attacks use staff secured across back and free fists.','active':'Dedicated contact pose. Grab sequences use separate capture and finish drawings. No transition smear frames.'}
for m in moves:
 m['hitPose']=1+m['button'];m['geometry']=[m['hitboxBack'],m['bottom'],m['reach'],m['bottom']+m['height']]
# Keep baseline defaults of other characters; user draft separately preserves every uploaded edit.
base['characters'][3]=copy.deepcopy(t)
for m in t['moves']:m.pop('hitPose',None);m.pop('geometry',None)
(R/'godot/data/starter_moves.json').write_text(json.dumps(base,indent=2)+'\n')
out=R/'godot/data/workshop'/DEST;out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(draft,indent=2,ensure_ascii=False)+'\n')
manifest={'label':'Tapper kit + Batch3 ·18 November2026','status':'playable provisional tuning','file':DEST,'sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'sourceFile':SOURCE,'sourceSha256':hashlib.sha256(raw).hexdigest(),'baseCommit':'1627395','previousFile':SOURCE,'note':'Preserves all uploaded non-Tapper move values and art notes. Adds editable Tapper Leo normal baseline, custom rolling stance and confirmed236D tackle. Local browser drafts remain untouched.'}
(R/'godot/data/workshop/current.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
print('Authored',sum(m['enabled'] for m in moves),'Tapper moves; source batch retained; schema18 draft written.')
