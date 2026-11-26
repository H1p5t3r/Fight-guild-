#!/usr/bin/env python3
"""Author the approved two-super roster without changing the frozen website."""
import copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'godot/data/workshop/2026-11-25-anvil/FightGuild-Anvil.json'
OUT=ROOT/'godot/data/workshop/2026-11-25-supers/FightGuild-Supers.json'
load=lambda p:json.loads(p.read_text())
def save(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,indent=2)+'\n')
# Character, stable slot, name, startup/active/recovery, full hit damage,
# blockstun, reach/bottom/height, capture ticks, native action type.
SPECS=[
 (0,16,'Sky Foundry',5,6,34,333,0,26000,6500,25000,112,8),
 (0,31,'Iron Dominion',18,5,18,280,36,26000,0,17000,90,13),
 (1,12,'Freemason',12,4,34,360,20,29000,0,16500,90,13),
 (1,31,'Grand Design',16,1,18,120,36,12000,0,16000,0,15),
 (2,12,'Flashpoint',8,5,35,300,20,17500,0,19000,84,13),
 (2,31,'The Air Is Mine',24,1,18,50,20,20000,0,16000,0,14),
 (3,12,'Last Orders',7,4,38,340,18,15000,0,19000,96,13),
 (3,31,'Whiskey Chaser',10,9,12,260,30,15000,1500,14000,96,13),
 (4,12,'No Safe Harbour',12,4,30,310,20,40000,5000,7500,96,13),
 (4,14,'Undertow',7,5,32,220,18,14500,0,15000,80,13),
 (5,12,'Bloodletting',10,4,24,250,20,20000,2000,10000,76,13),
 (5,31,'Exsanguinate',8,3,32,300,18,13000,0,17000,108,13),
]
ROLES=[
 'Airborne-only invincible command grab; existing approved lift and slam.',
 'Upper-body armored advance. +14 on first-active block, close hard knockdown on hit. Lows and throws bypass armor.',
 'Heavy damage and wall carry. The committed horizontal hammer finisher.',
 'Delayed moving stone wave. Return control after the cast; a hit launches for a follow-up. Does not refresh Drive.',
 'Invincible short-range backhand flame strike. Punishable on block.',
 'Stationary gas field, three blockable pulses. Hold back/neutral/forward during the cast for near/middle/far placement. Disappears if Smoke is hit.',
 'Regular-stance invincible uppercut into headbutt. Hit enters Dempsey stance.',
 'Dempsey-only hook barrage. Plus on block; hit finishes in stance. No invulnerability.',
 'Long narrow hook thrust, reel and corner carry. Jumping over the horizontal lane beats it.',
 'Invincible close hook sweep. Confirmed hit switches sides and restores spear spacing.',
 'Advancing crosscut. Confirmed hit applies or refreshes owned bleed and hard knockdown.',
 'Close crossing-knife finish. Consumes owned bleed and pays at most 150 stored grey life once, in addition to scaled base damage.',
]

def main():
 data=load(BASE);starter_path=ROOT/'godot/data/starter_moves.json';starter=load(starter_path)
 ext_template=data['characters'][5]['moves'][0]['extensions']
 roster=[]
 for role,spec in enumerate(SPECS):
  c,slot,name,st,ac,re,damage,bs,reach,bottom,height,ticks,kind=spec
  character=data['characters'][c];old=character['moves'][slot]
  first=role%2==0
  if role==0:
   # Preserve Sky Foundry's gameplay/art table. Shared cost is upgraded in core.
   move=copy.deepcopy(old)
  else:
   move=copy.deepcopy(data['characters'][1]['moves'][0]);move['id']=old['id']
   move.update(button=2 if first else 3,category=2,direction=5,motion=236236 if first else 214214,
    air=0,enabled=1,startup=st,active=ac,recovery=re,damage=damage,hitstun=45,blockstun=bs,hitstop=12,
    specialCancel=0,jumpCancel=0,whiffCancel=0,selfCancel=0,normalRoutes=0,commandRoutes=0,cancelOn=7,
    advance=0,travelSpeed=0,startupTravel=0,inertiaPercent=0,hitboxBack=0,reach=reach,bottom=bottom,height=height,
    simpleDirection=0,simpleButton=0,
    hitLevel=0,chipDamage=8,guardBreak=0,counterHitstun=0,counterHitstop=0,counterTier=0,attackLevel=4,
    counterVulnerable=7,counterFreezeFrames=-1,counterSlowFrames=0,reversalEligible=0,
    pushback=0,airPushback=0,blockPushback=1800,groundHitSpeed=0,airHitSpeed=0,launch=0,airLaunch=0,
    knockdown=2,knockdownFrames=65,wakeupFrames=10,wallDamage=0,throwRange=0,
    artPose=0,followFrom=-1,followFrom2=-1,followHit=0,pullFrames=0,pullGap=0,hitAngle=0,
    normalCancelStart=1,normalCancelEnd=0,specialCancelStart=1,specialCancelEnd=0,jumpCancelStart=1,jumpCancelEnd=0,followCancelStart=1,followCancelEnd=0,
    starterProration=100,comboScaling=10,minimumDamage=30,landingRecovery=0,
    projectileKind=0,projectileSpawnFrame=0,projectileSpeedX=0,projectileSpeedY=0,projectileGravity=0,
    projectileLife=90,projectileOffsetX=0,projectileOffsetY=0,projectileWidth=10000,projectileHeight=15000,
    projectileHits=1,projectileRehit=36,projectileDurability=8,projectilePersist=0,projectileMelee=0,
    smearMode=0,hurtMaskWindup=15,hurtMaskActive=15,hurtMaskRecovery=15,mechanic=0,
    stanceRequired=0,stanceChange=0,actionType=kind,holdFollow=-1,guardFollow=-1,holdFrame=0,
    proximityMove=-1,proximityRange=0,diveSpeedX=0,diveSpeedY=0,groundBounce=0,wallBounce=0,crumpleFrames=0,
    airCounterKnockdown=0,hurtWindowStart=0,hurtWindowEnd=0,hurtWindowMask=15,semiAirStart=0,semiAirEnd=0,
    armorFrames=0,armorHits=0,grabFrames=ticks,finishArtPose=0,finishArtFrame=0,
    comboDecay=10,starterDecay=0,driveDistance=0,drivePlus=0,driveNeutralFrames=12,
    hurtboxes={},hitboxTimeline={'multiHit':False,'keys':[]})
   move.pop('extensions',None)
   if 'extensions' in character:
    extra=copy.deepcopy(ext_template)
    extra['params'].update(contactKind=0,lowCrushStart=0,lowCrushEnd=0,passStart=0,passEnd=0,
     refaceFrame=0,stopAtBody=0,groundedLift=0,bleedDelay=0,bleedWindowStart=0,bleedWindowEnd=0,
     captureFreeze=0,pairTicks=0,releaseFreeze=0,ownerRecovery=0,victimRecovery=0,releaseGap=0,throwGrace=0,techTicks=0,pairTrack=0,friction=90)
    for key in ['hurtboxes','pushboxes','rootTrack','verticalRootKeys']:extra[key]=[]
    extra['routes']={key:[] for key in extra['routes']}
    extra['art']={'name':name,'role':ROLES[role],'productionStatus':'Approved super concept, generated supers-v1 production art.'}
    move['extensions']=extra
  if role==1:move.update(motion=63214,button=2,armorHits=1,armorFrames=22,startupTravel=700,travelSpeed=1400,blockPushback=500)
  if role in [2,8]:move.update(travelSpeed=700)
  if role in [4,6,9]:move.update(hurtWindowStart=1,hurtWindowEnd=st+ac-1,hurtWindowMask=0,semiAirStart=1,semiAirEnd=st+ac-1,reversalEligible=1)
  if role==6:move.update(stanceRequired=1)
  if role==7:
   move.update(stanceRequired=2,blockPushback=400,chipDamage=5)
   move['hitboxTimeline']={'multiHit':True,'keys':[dict(frame=1+i*4,hit=i+1,boxes=None,damage=65,hitstun=-1,blockstun=-1,hitstop=5) for i in range(3)]}
  if role==10:move.update(travelSpeed=1200)
  if role==3:move.update(projectileKind=1,projectileSpawnFrame=22,projectileOffsetX=10000,projectileOffsetY=8000,
    projectileWidth=9000,projectileHeight=16000,projectileSpeedX=250,projectileLife=100,
    launch=1400,airLaunch=1100,knockdown=1,hitstun=40,groundHitSpeed=180,airHitSpeed=240,chipDamage=12)
  if role==5:move.update(projectileKind=2,projectileSpawnFrame=24,projectileOffsetX=25000,projectileOffsetY=8000,
    projectileWidth=20000,projectileHeight=16000,projectileLife=180,projectileHits=3,projectileRehit=36,
    knockdown=0,hitstun=22,launch=0,airLaunch=350,groundHitSpeed=100,airHitSpeed=130,blockPushback=600,chipDamage=5)
  character['moves'][slot]=move
  compiled=copy.deepcopy(move);compiled['hitPose']=move['button']+1
  compiled['geometry']=[move['hitboxBack'],move['bottom'],move['reach'],move['bottom']+move['height']]
  for key in ['hitboxBack','bottom','reach','height']:compiled.pop(key)
  starter['characters'][c]['moves'][slot]=compiled
  roster.append(dict(character=c,slot=slot,role=role,name=name,input=('63214Hs' if role==0 else '63214S' if role==1 else ('236236S' if first else '214214Hs')),
    cost=6667,freeze=54,cinematic=kind not in (14,15),description=ROLES[role]))
 for catalog in (starter,data):
  for character in catalog['characters']:
   for move in character['moves']:move['simpleDirection']=move['simpleButton']=0
 save(starter_path,starter);save(OUT,data)
 digest=hashlib.sha256(OUT.read_bytes()).hexdigest()
 save(ROOT/'godot/data/workshop/current.json',dict(label='Two-segment supers / full roster',file=str(OUT.relative_to(OUT.parent.parent)),sha256=digest,
  sourceFile=str(BASE.relative_to(BASE.parent.parent)),sourceSha256=hashlib.sha256(BASE.read_bytes()).hexdigest()))
 save(ROOT/'godot/data/supers.json',dict(version=1,roster=roster))
 print('Authored twelve supers; native game only.')
if __name__=='__main__':main()
