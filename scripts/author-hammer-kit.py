#!/usr/bin/env python3
"""Author Hammer's provisional kit without changing another fighter's tuning/art."""
import copy
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
FIELDS=dict(driveDistance=0,drivePlus=4,driveNeutralFrames=12)
# slot: nickname, startup/active/recovery, damage, hit/blockstun, reach/bottom/height px
KIT={
 0:('Knuckle Check',5,3,9,28,17,11,76,84,32),
 1:('Work Boot',7,3,15,32,20,14,110,48,35),
 2:('Measuring Blow',12,4,23,52,26,19,240,65,48),
 3:('Crossbeam',15,4,27,68,29,21,215,54,80),
 4:('Low Check',5,3,10,24,16,10,72,44,30),
 5:('Toe Tap',6,3,14,28,18,12,98,5,25),
 6:('Foundation Sweep',10,4,26,48,25,18,178,2,30),
 7:('Rising Brace',14,5,27,58,29,20,132,32,150),
 8:('High Brace',10,4,21,36,24,16,102,83,60),
 11:('Keystone',22,5,29,82,32,22,222,8,172),
 13:('Break Step',5,12,6,0,0,0,1,0,1),
 14:('Stonecut',16,4,25,64,30,21,238,48,70),
 15:('Crown Breaker',26,4,30,76,32,23,155,5,170),
 16:('Quarry Lift',13,5,31,62,33,22,122,24,190),
 17:('Air Check',6,3,8,22,16,10,70,15,36),
 18:('Air Boot',8,4,12,30,20,13,103,-25,45),
 19:('Hanging Beam',10,5,18,44,24,17,172,-18,62),
 20:('Falling Stone',13,6,22,60,28,20,120,-58,118),
 23:('Back Cast',2,2,27,80,27,0,1,0,1),
 24:('Mason Toss',2,2,27,80,27,0,1,0,1),
 32:('Hammer Check',8,4,16,46,25,18,112,50,94),
 41:('Air Back Cast',2,2,25,72,26,0,1,0,1),
 42:('Air Mason Toss',2,2,25,72,26,0,1,0,1),
}
INTENT={
 0:'Fast standing check. Short reach; +4 on block when enhanced by Break Step.',
 1:'Forward boot for space control and sweep confirms.',
 2:'Longest grounded normal. Its 240 px tip plus 38 px block pushback calibrate Break Step.',
 3:'Heavy horizontal confirm; unsafe if left uncanceled.',
 4:'Compact crouching check for pressure gaps.',
 5:'Fast low into Foundation Sweep.',
 6:'Dedicated low sweep and hard knockdown. -11 on first-active block.',
 7:'Rising hammer launcher for grounded confirms and juggle routes.',
 8:'Universal 6P anti-air. Only legs remain vulnerable on frames 1–13; weapon has no hurtbox.',
 11:'Slow committed hammer slam. Large counter hit, no armor or free guard break.',
 13:'One Break Step per pressure string/combo. Any special cancels into it after first active; burst cancels into any grounded normal. +4f blockstun and 100% dash velocity on that normal. Reset after 12 uninterrupted neutral frames. Auto distance uses the longest grounded normal, normal block pushback and standing body spacing.',
 14:'Horizontal special for poke confirms. Drive cancel closes the gap; unsafe without it.',
 15:'Slow overhead hammer special. Reactable 26f startup; Drive can rescue recovery once.',
 16:'Anti-air lift and juggle ender. No invulnerability; -13 on block without Drive.',
 17:'Quick airborne challenge.',18:'Air-to-air boot with modest downward coverage.',
 19:'Broad jumping approach and air-to-air swing.',20:'Slow descending hammer hit; commits to landing recovery.',
 23:'2f universal back throw into hard knockdown.',24:'2f universal forward throw into hard knockdown.',
 32:'Close pressure starter. -1 normally, +3 after Break Step. Chains to f.S.',
 41:'2f universal air back throw.',42:'2f universal air forward throw.',
}

def configure(character,starter):
    for slot,m in enumerate(character['moves']):
        m.update(FIELDS)
        if character['name']!='Hammer':continue
        m['enabled']=int(slot in KIT)
        if slot not in KIT:continue
        name,start,active,recovery,damage,hit,block,reach,bottom,height=KIT[slot]
        m.update(startup=start,active=active,recovery=recovery,damage=damage,hitstun=hit,blockstun=block,
            hitstop=7 if damage<40 else 11 if damage<65 else 14, advance=0,travelSpeed=0,startupTravel=0,
            mechanic=0,air=int(slot in (17,18,19,20,41,42)),artPose=0,hitAngle=0,projectileKind=0,
            followFrom=-1,followFrom2=-1,followHit=0,actionType=0,stanceRequired=0,stanceChange=0,
            holdFollow=-1,guardFollow=-1,finishArtPose=0,finishArtFrame=0,grabFrames=0,
            normalRoutes=-1,commandRoutes=-1,specialCancel=int(slot not in (13,23,24,41,42)),
            jumpCancel=int(slot in (1,2,17,18,19,32)),selfCancel=int(slot in (0,4,17)),whiffCancel=0,cancelOn=7,
            normalCancelStart=1,normalCancelEnd=0,specialCancelStart=1,specialCancelEnd=0,
            jumpCancelStart=1,jumpCancelEnd=0,followCancelStart=1,followCancelEnd=0,
            hurtMaskWindup=15,hurtMaskActive=15,hurtMaskRecovery=15,hurtWindowStart=0,hurtWindowEnd=0,hurtWindowMask=15,
            armorFrames=0,armorHits=0,semiAirStart=0,semiAirEnd=0,groundBounce=0,wallBounce=0,crumpleFrames=0,
            knockdown=0,knockdownFrames=24,wakeupFrames=8,launch=0,airLaunch=1050,
            groundHitSpeed=240 if damage<40 else 400,airHitSpeed=330 if damage<40 else 500,
            pushback=1500,airPushback=2400,blockPushback=1500 if damage<40 else 2800,
            hitLevel=2 if slot in (17,18,19,20) else int(slot in (5,6)),chipDamage=0,guardBreak=0,counterHitstun=4,counterHitstop=3,
            counterVulnerable=3,counterFreezeFrames=-1,counterSlowFrames=0,counterTier=1 if damage<40 else 2 if damage<65 else 3,
            attackLevel=0 if damage<30 else 1 if damage<40 else 2 if damage<60 else 3,
            starterProration=80 if damage<40 else 100,comboScaling=5,minimumDamage=10,comboDecay=5,starterDecay=0,
            inertiaPercent=65,landingRecovery=6 if slot in (17,18,19,20) else 0,reversalEligible=0,
            proximityMove=32 if slot==2 else -1,proximityRange=12000,
            hurtboxes={},hitboxTimeline={'multiHit':False,'keys':[]})
        if slot in (14,15,16):
            m.update(category=2,button={14:2,15:3,16:3}[slot],motion={14:236,15:214,16:623}[slot],direction=5,
                simpleDirection={14:6,15:4,16:2}[slot],simpleButton=3 if slot!=14 else 2,chipDamage=6,inertiaPercent=80)
        elif slot==13:
            m.update(category=3,button=4,direction=5,motion=0,mechanic=5,hitstop=0,whiffCancel=1,normalRoutes=31,commandRoutes=31,
                normalCancelStart=start-1,normalCancelEnd=start-2+active,specialCancel=0,hitLevel=0,chipDamage=0,advance=0,
                counterVulnerable=3,proximityMove=-1,simpleDirection=5,simpleButton=4)
        if slot==2:m['blockPushback']=3800
        if slot==6:m.update(knockdown=2,knockdownFrames=60,wakeupFrames=10,airLaunch=-300)
        if slot==7:m.update(launch=1450,airLaunch=1250,knockdown=1)
        if slot==8:m.update(hurtWindowStart=1,hurtWindowEnd=13,hurtWindowMask=1,launch=800,airLaunch=1100)
        if slot==11:m.update(groundHitSpeed=650,airLaunch=-500)
        if slot==14:m.update(groundHitSpeed=650,airHitSpeed=700)
        if slot==15:m.update(hitLevel=2,knockdown=1,airLaunch=-500)
        if slot==16:m.update(launch=1650,airLaunch=1500,knockdown=1)
        if slot==20:m.update(airLaunch=-400,landingRecovery=10)
        if slot in (23,24,41,42):m.update(category=4,motion=0,direction=4 if slot in (23,41) else 6,knockdown=2,knockdownFrames=60,wakeupFrames=10,throwRange=2000,pushback=5500,airPushback=5500)
        rect=[1200,bottom*100,reach*100,(bottom+height)*100]
        if starter:
            m['hitPose']=m['button']+1;m['geometry']=rect
            for key in ['hitboxBack','reach','bottom','height']:m.pop(key,None)
        else:m.update(hitboxBack=rect[0],bottom=rect[1],reach=rect[2],height=rect[3]-rect[1])
        # Utility and throws have nonzero harmless fallback geometry for data validation.
        if reach==1:
            if starter:m['geometry']=[0,0,100,100]
            else:m.update(hitboxBack=0,bottom=0,reach=100,height=100)
    if character['name']=='Hammer':character['movement'].update(walkSpeed=320,backWalkSpeed=250,runSpeed=1000,runAcceleration=100,attackFriction=90,airDashEnabled=0,airBackdashEnabled=0)

def main():
    starter=ROOT/'godot/data/starter_moves.json'
    data=json.loads(starter.read_text())
    for c in data['characters']:configure(c,True)
    starter.write_text(json.dumps(data,indent=2)+'\n')
    base=ROOT/'godot/data/workshop'
    source=base/'2026-11-20-combo-decay/FightGuild-Combo-Decay.json'
    data=json.loads(source.read_text())
    for c in data['characters']:configure(c,False)
    data['schema']=data['coreVersion']=27
    notes=data.setdefault('_moveWorkshop',{}).setdefault('notes',{})
    for slot,row in KIT.items():
        m=data['characters'][1]['moves'][slot];key='Hammer/'+m['id']
        notes.setdefault(key,{}).update(label=row[0],intent=INTENT[slot])
    data['_moveWorkshop']['hammerRevision']='2026-11-23-break-step-v1'
    target=base/'2026-11-23-hammer/FightGuild-Hammer.json';target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(data,indent=2)+'\n')
    manifest=dict(label='Hammer · Break Step kit',file=str(target.relative_to(base)),sha256=hashlib.sha256(target.read_bytes()).hexdigest(),sourceFile=str(source.relative_to(base)),sourceSha256=hashlib.sha256(source.read_bytes()).hexdigest())
    (base/'current.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('Authored Hammer: %d enabled actions; other fighters retain their data.'%len(KIT))

if __name__=='__main__':main()
