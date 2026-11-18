#!/usr/bin/env python3
"""Apply only Shark's16 Ky-referenced non-D normals to the current tuning lineage."""
import copy
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SOURCE='2026-11-18-user-smoke/FightGuild-Smoke-Animations.json'
DEST='2026-11-18-shark/FightGuild-Shark-Normals.json'
ENTRIES=[('5P',0,'Shoulder Check'),('5K',1,'Shin Snap'),('c.S',32,'Close Hook'),('f.S',2,'Shoulder Snap'),
 ('5H',3,'Tide Cut'),('2P',4,'Low Check'),('2K',5,'Ankle Snap'),('2S',6,'Low Tide'),('2H',7,'Low Scoop'),
 ('j.P',17,'Air Check'),('j.K',18,'Air Kick'),('j.S',19,'Air Cut'),('j.H',20,'Falling Hook'),('6P',8,'Breakwater'),('6K',9,'Front Boot'),('6H',11,'Anchor Chop')]

def load(p): return json.loads((ROOT/p).read_text())
def save(p,data):
    path=ROOT/p;path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')

def main():
    raw=(ROOT/'godot/data/workshop'/SOURCE).read_bytes();draft=json.loads(raw)
    defaults=load('godot/data/starter_moves.json')
    assert draft['characters'][4]['name']==defaults['characters'][4]['name']=='Shark'
    rows={m['Input']:m for m in load('references/frame-data/ky-kiske-2026-11-18/source.json')['moves']}
    traces=load('references/frame-data/ky-kiske-2026-11-18/traces.json')['moves']
    fields=load('godot/data/stance_fields.json')
    notes=draft.setdefault('_moveWorkshop',{'version':1,'notes':{}})['notes']
    for art,(src,slot,label) in enumerate(ENTRIES,5):
        r=rows[src];level=int(r['Level'].split(',')[-1]);active=5 if src=='2H' else int(r['Active'])
        recovery=int(r['Recovery']);last=4 if src=='2H' else active
        air=src.startswith('j.')
        block=[9,11,13,16,18][level] if air else int(r['On-Block'])+last-1+recovery
        hit=block+3 if air or src=='6H' else int(r['On-Hit'])+last-1+recovery
        for data in [defaults,draft]:
            m=data['characters'][4]['moves'][slot]
            m.update({f['key']:f['default'] for f in fields})
            m.update(enabled=1,artPose=art,startup=int(r['Startup']),active=active,recovery=recovery,
                damage=int(r['Damage'].split(',')[0]),hitstun=hit,blockstun=block,hitstop=8 if level<3 else 10,
                attackLevel=level,counterTier={'Small':1,'Mid':2,'Large':3,'Large×2':3}[r['Counter Type']],
                starterProration=int(r['Proration'].rstrip('%')),counterFreezeFrames=31 if r['Counter Type'].startswith('Large') else 21 if r['Counter Type']=='Mid' else -1,
                counterSlowFrames=35 if r['Counter Type'].startswith('Large') else 25 if r['Counter Type']=='Mid' else 0,
                counterHitstop=3 if r['Counter Type']=='Small' else 0,counterHitstun=4 if r['Counter Type']=='Small' else 0,
                category=1 if src in ['6P','6K','6H'] else 0,direction=6 if src in ['6P','6K','6H'] else 2 if src.startswith('2') else 5,
                motion=0,air=int(air),mechanic=0,projectileKind=0,followFrom=-1,followFrom2=-1,followHit=0,
                advance=0,travelSpeed=0,pullFrames=0,hitAngle=0,guardBreak=0,chipDamage=0,
                hitLevel={'All':0,'Low':1,'High':2}[r['Guard']],specialCancel=1,jumpCancel=int(m['button'] in [1,2]),
                selfCancel=int(m['button']==0),whiffCancel=0,normalRoutes=-1,commandRoutes=-1,
                normalCancelStart=1,normalCancelEnd=0,specialCancelStart=1,specialCancelEnd=0,jumpCancelStart=1,jumpCancelEnd=0,
                followCancelStart=1,followCancelEnd=0,cancelOn=3,reversalEligible=0,
                knockdown=0,knockdownFrames=6,wakeupFrames=8,launch=0,airLaunch=700,pushback=700,airPushback=1400,blockPushback=600,
                hurtMaskWindup=15,hurtMaskActive=15,hurtMaskRecovery=15,hurtboxes={},smearMode=0,
                simpleDirection=0,simpleButton=m['button'],landingRecovery=3 if air else 0)
            ts=traces[src];boxes=ts[0]['boxes'];geo=[min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes)]
            m.update(hitboxBack=geo[0],bottom=geo[1],reach=geo[2],height=geo[3]-geo[1])
            m['hitboxTimeline']=dict(multiHit=src=='2H',keys=[dict(frame=t['activeFrame'],hit=i+1 if src=='2H' else 1,boxes=copy.deepcopy(t['boxes']),damage=-1,hitstun=-1,blockstun=-1,hitstop=-1) for i,t in enumerate(ts)])
            if src=='c.S':m.update(button=2,category=0,proximityMove=-1,blockPushback=300,selfCancel=0,jumpCancel=1,simpleButton=2)
            if src=='f.S':m.update(proximityMove=32,proximityRange=8500)
            if src=='6P':m.update(hurtMaskWindup=3,hurtWindowStart=4,hurtWindowEnd=13,hurtWindowMask=1)
            if src=='2H':
                # Provisional ordinary float: preserves two contact timings and
                # source stun. This is explicitly not Strive's special crumple.
                m.update(damage=14,hitstun=19,hitstop=16,launch=150,airLaunch=350,airPushback=700)
                m['hitboxTimeline']['keys'][0].update(damage=14,hitstun=19,blockstun=19,hitstop=16)
                m['hitboxTimeline']['keys'][1].update(damage=40,hitstun=33,blockstun=18,hitstop=16)
            if src=='6H':m.update(knockdown=1,launch=650,airLaunch=650,wallBounce=900,knockdownFrames=6)
            if data is defaults:m['hitPose']=1+m['button'];m['geometry']=geo
        m=draft['characters'][4]['moves'][slot]
        note=notes.setdefault('Shark/'+m['id'],{})
        # Retain submitted prose, image references and any other user note keys.
        addition=f'Ky {src} reference: {r["Startup"]}/{r["Active"]}/{r["Recovery"]}; raw damage {r["Damage"]}; block {r["On-Block"] or "contextual"}. A / Shoulder Snap with approved fluid weight transfer; 2Hs uses Low Scoop. Image-traced attack geometry is scaled, not an exact engine dump. Fight Guild gatlings and body-only hurtboxes apply.'
        if src=='2H':addition+=' Two hits14/40 at active frames1/2. Provisional ordinary airborne float with33f final stun; source airborne1–19/standing20–27/guard-only28–33 crumple phases are NOT implemented by this pass.'
        if src=='6P':addition+=' Body masks adapt source windows: head/extension off1–3, legs only4–13, full recovery. Source Combo Decay has no direct equivalent.'
        if src=='j.H':addition+=' One hit; second geometry begins active frame3 provisionally because screenshot timing is unlabeled.'
        if src=='5H':addition+=' Upper solid red/green export artifacts are ambiguous; outlined strike traced conservatively.'
        if src=='6H':addition+=' Mid with soft knockdown; wall bounce applies only to an already airborne target. Knockdown advantage is provisional.'
        if air:addition+=' IAD advantage is contextual; ordinary air blockstun uses attack-level defaults.'
        note.setdefault('label',label)
        note['intent']=note.get('intent','')+('\n\n' if note.get('intent') else '')+addition
        note.setdefault('windup','Coil through the hips and ribs from Shoulder Rest; knee compression, uneven foot load and a natural heel pivot. No emitted smear.')
        note.setdefault('active','Release into the opponent through a clear body line; right-hand hook, left-hand short blade. Blue glasses, restrained white hair, fixed anatomy and weapon size. No body smears.')
    save('godot/data/starter_moves.json',defaults)
    save('godot/data/workshop/'+DEST,draft)
    out=ROOT/'godot/data/workshop'/DEST
    save('godot/data/workshop/current.json',dict(label='Shark normals + fluid Low Scoop ·18 November2026',status='playable source-based iteration',file=DEST,sha256=hashlib.sha256(out.read_bytes()).hexdigest(),sourceFile=SOURCE,sourceSha256=hashlib.sha256(raw).hexdigest(),previousFile=SOURCE,baseCommit='9aa0a4d',note='Only16 Shark P/K/S/Hs normals and their appended art briefs change. All D moves, throws, specials, movement, other fighters and submitted photo references are preserved.2Hs floating crumple and unlabeled spatial boundaries are documented approximations.'))
    print('Applied16 Shark normals; preserved every other slot and character.')

if __name__=='__main__':main()
