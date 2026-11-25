#!/usr/bin/env python3
"""Anvil's grappler rules/data. Preserve every other fighter and the frozen website."""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# slot: name, startup/active/recovery, damage, hit/block stun, front/bottom/height px
KIT = {
    0: ('Iron Knuckle',7,3,15,35,16,11,90,78,35),
    1: ('Steel Toe',10,4,19,45,20,14,125,35,45),
    2: ('Shield Reach',16,5,26,65,28,21,215,55,65),
    3: ('Foundry Gate',19,5,32,85,31,22,245,50,85),
    4: ('Low Knuckle',7,3,16,30,16,11,85,37,35),
    5: ('Heel Check',9,3,18,35,18,12,115,2,30),
    6: ('Iron Sweep',13,4,29,60,26,17,180,0,32),
    7: ('Rising Plate',16,5,30,70,28,20,135,15,170),
    8: ('High Palm',12,5,25,45,25,17,120,80,80),
    11: ('Gate Crash',24,5,34,90,33,23,235,10,170),
    13: ('Bulwark',5,2,14,0,0,0,1,0,1),
    14: ('Foundry Drop',5,3,42,333,30,0,1,0,1),
    15: ('Iron Turn',6,3,40,333,30,0,1,0,1),
    16: ('Sky Foundry',5,6,45,333,35,0,310,35,300),
    17: ('Air Knuckle',8,4,14,30,17,12,95,15,40),
    18: ('Air Boot',10,4,18,40,20,14,120,-35,55),
    19: ('Hanging Plate',13,5,23,55,25,18,180,-15,75),
    20: ('Falling Gate',16,5,28,70,27,20,155,-55,125),
    21: ('Falling Bulwark',9,90,22,22,18,12,140,-70,145),
    23: ('Back Cast',2,2,27,80,27,0,1,0,1),
    24: ('Foundry Toss',2,2,27,80,27,0,1,0,1),
    28: ('Iron Advance',23,24,28,72,30,22,140,25,110),
    30: ('Plant',5,1,12,0,0,0,1,0,1),
    32: ('Chest Check',10,4,22,50,24,17,105,45,100),
    41: ('Air Back Cast',2,2,25,72,26,0,1,0,1),
    42: ('Air Foundry Toss',2,2,25,72,26,0,1,0,1),
}
INTENT = {
    2: 'Long disjointed shield poke. No normal chains; confirm into a special.',
    3: 'Furthest normal: heavy shield extension. Slow and punishable alone.',
    6: 'Dedicated low sweep, hard knockdown; -15 on first-active block.',
    7: 'Rising shield launcher. Confirm into the anti-air super with 50% Momentum.',
    8: '6P anti-air; upper-body hurtboxes disabled through frame 16.',
    13: 'Hold D. Advance with forward while holding. Two upper-body armor hits; legs and throws remain vulnerable. Cancel into a special or command grab, transferring at most one unspent armor hit. Release D for 14f recovery. No meter farming on stance entry.',
    14: '63214P: A / Foundry Drop. Catch, overhead lift, seated powerbomb. 333 damage, untechable, 5f startup. Jump, throw immunity and hit/blockstun defeat the catch.',
    15: '63214K: B / Iron Turn. Catch, hip turn, sweeping side-switch throw. 333 damage, untechable, 6f startup.',
    16: '63214Hs: anti-air command-grab super. 50% Momentum, 54f deterministic screen freeze, 5f startup, airborne targets only. Can catch a juggle with ordinary combo scaling. Ground targets are safe. No Momentum refund on hit.',
    21: 'j.D: stop horizontal and vertical momentum, 9f hover startup, then vertical shield descent. Five separate hit groups every 3 active frames, wide hitbox. Landing ends the attack into 22f recovery. No armor.',
    28: '[4]6Hs: charge back for 30f, release forward + Hs. One intrinsic armor hit (including lows), advancing shield special, P brake during active approach. Bulwark can add only one upper-body armor hit.',
    30: 'P during Iron Advance: stop and plant. No hitbox or armor; 17 total locked frames.',
}


def track(keys):
    return [dict(tick=t, owner=[ax, ay], victim=[bx, by]) for t, ax, ay, bx, by in keys]


def configure(character, starter, template):
    ext = copy.deepcopy(template['extensions'])
    ext['params'].update(policy=2, groundSpeedPercent=100, airSpeedPercent=100)
    # Policy 2 uses normal sprite collision, not Fillet's authored profile table.
    ext['profiles'] = {name: {} for name in ext['profiles']}
    ext['pairTracks'] = [
        track([(0,0,0,0,0),(12,0,0,5500,0),(26,0,0,2500,19000),
               (56,0,0,2500,22000),(70,0,900,3500,20000),(82,0,0,6000,0),(88,0,0,7000,0)]),
        track([(0,0,0,0,0),(14,0,0,5000,0),(32,1000,0,2500,8000),
               (52,2000,0,-3000,10000),(76,2000,0,-6500,0),(92,2000,0,-7500,0)]),
        track([(0,0,0,0,0),(12,5000,10000,7500,19000),(30,7000,24000,9000,33000),
               (65,7000,24000,9000,33000),(88,7000,14000,9500,23000),
               (100,7000,0,12500,0),(112,7000,0,14000,0)]),
        track([(0,0,0,0,0),(20,0,0,7000,0)]),
    ]
    ext['art'] = {'name':'Anvil / Bull grappler', 'status':'Refined C / Bull body approved; shield selection pending; grab choreographies A + B approved.'}
    character['extensions'] = ext
    for slot, move in enumerate(character['moves']):
        move['enabled'] = int(slot in KIT)
        move.pop('extensions', None)
        if slot not in KIT:
            continue
        name, startup, active, recovery, damage, hitstun, blockstun, reach, bottom, height = KIT[slot]
        move.update(startup=startup, active=active, recovery=recovery, damage=damage,
            hitstun=hitstun, blockstun=blockstun, hitstop=8 if damage<50 else 12,
            advance=0, travelSpeed=0, startupTravel=0, mechanic=0, actionType=0,
            artPose=0, hitAngle=0, projectileKind=0, followFrom=-1, followFrom2=-1, followHit=0,
            stanceRequired=0, stanceChange=0, holdFollow=-1, guardFollow=-1, holdFrame=0,
            finishArtPose=0, finishArtFrame=0, grabFrames=0, motion=0,
            normalRoutes=0, commandRoutes=0, selfCancel=0, jumpCancel=0,
            specialCancel=int(slot in (0,1,2,3,4,5,6,7,8,11,17,18,19,20,32)), whiffCancel=0, cancelOn=7,
            normalCancelStart=1, normalCancelEnd=0, specialCancelStart=1, specialCancelEnd=0,
            jumpCancelStart=1, jumpCancelEnd=0, followCancelStart=1, followCancelEnd=0,
            hurtMaskWindup=15, hurtMaskActive=15, hurtMaskRecovery=15,
            hurtWindowStart=0, hurtWindowEnd=0, hurtWindowMask=15,
            armorFrames=0, armorHits=0, semiAirStart=0, semiAirEnd=0,
            groundBounce=0, wallBounce=0, crumpleFrames=0,
            knockdown=0, knockdownFrames=24, wakeupFrames=8, launch=0, airLaunch=900,
            groundHitSpeed=260, airHitSpeed=420, pushback=1500, airPushback=2400,
            blockPushback=1800 if damage<50 else 3200,
            air=int(slot in (17,18,19,20,21,41,42)),
            hitLevel=2 if slot in (17,18,19,20,21) else int(slot in (5,6)),
            chipDamage=0, guardBreak=0, counterHitstun=4, counterHitstop=3,
            counterVulnerable=3, counterFreezeFrames=-1, counterSlowFrames=0,
            counterTier=1 if damage<50 else 2 if damage<70 else 3,
            attackLevel=1 if damage<50 else 2 if damage<70 else 3,
            starterProration=80 if damage<50 else 100, comboScaling=5, minimumDamage=10,
            comboDecay=5, starterDecay=0, inertiaPercent=50,
            landingRecovery=8 if slot in (17,18,19,20) else 0, reversalEligible=0,
            proximityMove=32 if slot==2 else -1, proximityRange=12000,
            hurtboxes={}, hitboxTimeline={'multiHit':False,'keys':[]})
        if slot in (14,15,16):
            move.update(category=4,button={14:0,15:1,16:3}[slot],direction=5,motion=63214,
                simpleDirection=4,simpleButton={14:0,15:1,16:3}[slot],actionType=8 if slot==16 else 7,
                knockdown=2,knockdownFrames=60,wakeupFrames=10,throwRange=6500 if slot==14 else 7200,
                pushback=0,airPushback=0,blockPushback=0,launch=0,airLaunch=0,inertiaPercent=0,
                counterTier=0,counterVulnerable=3,starterProration=100,minimumDamage=30)
        if slot==16:
            move.update(hurtWindowStart=1,hurtWindowEnd=10,hurtWindowMask=0,
                semiAirStart=1,semiAirEnd=10,reversalEligible=1,throwRange=0)
        if slot==13:
            move.update(category=3,button=4,direction=5,actionType=11,armorHits=2,armorFrames=120,
                travelSpeed=220,inertiaPercent=0,hitstop=0,whiffCancel=1,specialCancel=1,
                simpleDirection=5,simpleButton=4)
        if slot==21:
            move.update(category=3,button=4,direction=5,actionType=12,diveSpeedX=0,diveSpeedY=-900,
                inertiaPercent=0,hitstop=5,groundHitSpeed=40,airHitSpeed=40,airLaunch=-150,
                blockPushback=500,landingRecovery=22,counterTier=2,comboDecay=2)
            move['hitboxTimeline'] = {'multiHit':True,'keys':[
                dict(frame=1+i*3,hit=i+1,boxes=None,damage=-1,hitstun=-1,blockstun=-1,hitstop=-1) for i in range(5)]}
        if slot==28:
            move.update(category=2,button=3,direction=5,motion=46,air=0,actionType=9,
                simpleDirection=6,simpleButton=3,travelSpeed=1400,inertiaPercent=0,
                armorHits=1,armorFrames=46,knockdown=1,chipDamage=7,groundHitSpeed=800,
                whiffCancel=1,followCancelStart=22,followCancelEnd=45)
        if slot==30:
            move.update(category=2,button=0,direction=5,actionType=10,followFrom=28,
                simpleDirection=0,inertiaPercent=0,hitstop=0)
        if slot in (13,30):
            move['hitboxTimeline']={'multiHit':False,'keys':[dict(frame=1,hit=1,boxes=[],damage=-1,hitstun=-1,blockstun=-1,hitstop=-1)]}
        if slot==6: move.update(knockdown=2,knockdownFrames=60,wakeupFrames=10,airLaunch=-300)
        if slot==7: move.update(launch=1550,airLaunch=1300,knockdown=1)
        if slot==8: move.update(hurtWindowStart=1,hurtWindowEnd=16,hurtWindowMask=1,airLaunch=1000)
        if slot in (23,24,41,42):
            move.update(category=4,direction=4 if slot in (23,41) else 6,throwRange=2000,
                knockdown=2,knockdownFrames=60,wakeupFrames=10,grabFrames=40,pushback=5500,airPushback=5500)
        rect=[-11000 if slot==21 else 6000 if slot in (2,3,11) else 1200,bottom*100,reach*100,(bottom+height)*100]
        if reach==1: rect=[0,0,100,100]
        if starter:
            move['geometry']=rect;move['hitPose']=move['button']+1
            for key in ('hitboxBack','reach','bottom','height'):move.pop(key,None)
        else: move.update(hitboxBack=rect[0],bottom=rect[1],reach=rect[2],height=rect[3]-rect[1])
        extra=copy.deepcopy(template['moves'][0]['extensions'])
        extra['params'].update(contactKind=0,bleedDelay=0,bleedWindowStart=0,bleedWindowEnd=0)
        extra['routes']={key:[] for key in extra['routes']}
        for key in ('hurtboxes','pushboxes','rootTrack','verticalRootKeys'):extra[key]=[]
        if slot in (14,15,16):
            extra['params'].update(captureFreeze=10,pairTicks={14:88,15:92,16:112}[slot],
                releaseFreeze=24 if slot==16 else 18,ownerRecovery=24,victimRecovery=0,
                releaseGap=8500,throwGrace=5,techTicks=0,pairTrack={14:0,15:1,16:2}[slot])
        extra['art']={'name':name,'role':INTENT.get(slot,'Committed normal. No normal-to-normal or jump cancel; special cancel on hit/block.'),
            'productionStatus':'Refined Bull body approved; shield selection pending; no new runtime artwork applied.'}
        move['extensions']=extra
    character['movement'].update(walkSpeed=250,backWalkSpeed=200,forwardStyle=1,stepSpeed=850,stepFrames=10,
        runSpeed=850,runAcceleration=80,airDashEnabled=0,airBackdashEnabled=0)


def main():
    starter_path=ROOT/'godot/data/starter_moves.json'
    data=json.loads(starter_path.read_text())
    template=copy.deepcopy(data['characters'][5])
    configure(data['characters'][0],True,template)
    starter_path.write_text(json.dumps(data,indent=2)+'\n')
    base=ROOT/'godot/data/workshop'
    source=base/'2026-11-24-hammer-movement/FightGuild-Hammer-Movement.json'
    data=json.loads(source.read_text())
    configure(data['characters'][0],False,template)
    notes=data.setdefault('_moveWorkshop',{}).setdefault('notes',{})
    for slot,row in KIT.items():
        move=data['characters'][0]['moves'][slot]
        notes.setdefault('Anvil/'+move['id'],{}).update(label=row[0],intent=move['extensions']['art']['role'])
    data['_moveWorkshop']['anvilRevision']='2026-11-25-bulwark-grappler-v1'
    target=base/'2026-11-25-anvil/FightGuild-Anvil.json'
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(data,indent=2)+'\n')
    current=dict(label='Anvil · Bulwark grappler',file=str(target.relative_to(base)),sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
        sourceFile=str(source.relative_to(base)),sourceSha256=hashlib.sha256(source.read_bytes()).hexdigest())
    (base/'current.json').write_text(json.dumps(current,indent=2)+'\n')
    print(f'Authored {len(KIT)} Anvil actions; preserved other fighters. Website not rebuilt.')


if __name__=='__main__': main()
