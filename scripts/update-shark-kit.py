#!/usr/bin/env python3
"""Derive Shark's revision from the preserved user draft; keep other kits intact."""
import copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
PROD=ROOT/'art/characters/shark-kit-v2'
load=lambda p:json.loads(p.read_text())
def save(p,x):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(x,indent=2)+'\n')
DEFAULTS=dict(tetherDuration=180,tetherRange=45000,tetherGap=6000)
def main():
    previous=load(PROD/'baseline-workshop-manifest.json')
    draft=load(ROOT/'godot/data/workshop'/previous['file'])
    shark=copy.deepcopy(load(PROD/'baseline-moves.json'))
    for c in draft['characters']:
        for m in c['moves']:m.update(DEFAULTS)
    for m in shark['moves']:m.update(DEFAULTS)
    revised={
      13:dict(mechanic=3,startup=16,active=4,recovery=24,damage=36,hitstun=24,blockstun=16,hitstop=9,hitLevel=0,geometry=[2500,5500,19500,10500]),
      21:dict(mechanic=3,startup=17,active=4,recovery=22,damage=32,hitstun=25,blockstun=14,hitstop=9,hitLevel=2,geometry=[2000,-8000,15000,5000]),
      22:dict(mechanic=4,startup=12,active=1,recovery=20,damage=0,hitstun=0,blockstun=0,hitstop=0,hitLevel=0,tetherFrames=10,geometry=[0,0,100,100]),
      12:dict(mechanic=0,enabled=0,startup=8,active=10,recovery=10,damage=0,hitstun=0,blockstun=0,hitstop=0,hitLevel=0,tetherSpeed=1400,geometry=[0,0,100,100]),
    }
    for slot,values in revised.items():
        m=shark['moves'][slot]
        m.update(category=3,enabled=1,advance=0,startupTravel=0,travelSpeed=0,inertiaPercent=0,
            specialCancel=0,jumpCancel=0,whiffCancel=0,selfCancel=0,normalRoutes=0,commandRoutes=0,
            chipDamage=0,guardBreak=0,knockdown=0,launch=0,airLaunch=0,pullFrames=0,hitAngle=0,
            pushback=1200,airPushback=1200,blockPushback=1800,counterTier=1,counterFreezeFrames=-1,counterSlowFrames=0,
            counterHitstun=0,counterHitstop=0,comboScaling=8 if slot in (13,21) else 0,
            hitboxTimeline=dict(multiHit=False,keys=[]),hurtboxes={},artPose=0)
        m.update(values);l,b,r,t=m.pop('geometry');m.update(hitboxBack=l,bottom=b,reach=r,height=t-b)
        if slot in (12,22):m.update(pushback=0,airPushback=0,attackLevel=-1)
    draft['characters'][4]=shark;draft['schema']=draft['coreVersion']=25
    # Retain the user's original brief/photo records and explicitly annotate this revision.
    draft.setdefault('_moveWorkshop',{})['sharkRevision']=dict(name='Tag and actionable pull',source=previous['file'],
        originalDriveNotes={k:v for k,v in draft.get('_moveWorkshop',{}).get('notes',{}).items() if k.startswith('Shark/') and k.split('/')[1] in ['5D','j.D','2D','6D']},
        roles={'5D':'Set the Line','j.D':'Cast Down','2D':'Reel In'})
    names={13:('Set the Line','Grounded mid tag. A successful hit attaches a visible line for 180 unfrozen ticks. Blocking prevents the tag.'),21:('Cast Down','Airborne downward tag. Use it to establish a line from a jump; blocking prevents the tag.'),22:('Reel In','Spend a line to pull the opponent toward Shark horizontally. Unblockable; a free target can attack, jump, dash or guard throughout. Existing hitstun or blockstun pauses until the pull ends; no new stun, damage or hitstop is applied.'),12:('Retired Chase','Disabled. Reel In on 2D is the only line follow-up.')}
    for slot,(label,intent) in names.items():
        note=draft.setdefault('_moveWorkshop',{}).setdefault('notes',{}).setdefault('Shark/'+shark['moves'][slot]['id'],{})
        note.update(label=label,intent=intent+' Line breaks on expiry, range escape, or Shark taking an unblocked hit. Use 2S for the hard-knockdown sweep.')
    path=ROOT/'godot/data/workshop/2026-11-19-shark-v2/FightGuild-Shark-v2.json';save(path,draft)
    save(ROOT/'godot/data/workshop/current.json',dict(label='Shark v2 · Actionable pull',file=str(path.relative_to(ROOT/'godot/data/workshop')),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),sourceFile=previous['file'],sourceSha256=previous['sha256']))
    starter=load(ROOT/'godot/data/starter_moves.json')
    for c in starter['characters']:
        for m in c['moves']:m.update(DEFAULTS)
    compiled=copy.deepcopy(shark)
    for m in compiled['moves']:
        m['hitPose']=m['button']+1
        m['geometry']=[m.pop('hitboxBack'),m['bottom'],m.pop('reach'),m['bottom']+m.pop('height')];m.pop('bottom')
        if m['hitAngle']:m['path']=m['geometry'][:]
    starter['characters'][4]=compiled;save(ROOT/'godot/data/starter_moves.json',starter)
    save(PROD/'moves.json',shark)
    print('Shark:26 enabled moves; saved tuning preserved outside four revised Drive actions; schema25.')
if __name__=='__main__':main()
