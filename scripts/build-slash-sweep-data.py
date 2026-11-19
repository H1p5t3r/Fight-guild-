#!/usr/bin/env python3
"""Apply the confirmed close/far Slash and universal 2S rules to the latest draft."""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = '2026-11-19-user/FightGuild-moves-2026-11-19.json'
DEST = '2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json'
PREVIOUS = '2026-11-18-shark/FightGuild-Shark-Normals.json'

def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')

def main():
    folder = ROOT / 'godot/data/workshop'
    raw = (folder / SOURCE).read_bytes()
    draft = json.loads(raw)
    defaults = json.loads((ROOT / 'godot/data/starter_moves.json').read_text())
    for data in [draft, defaults]:
        for c, character in enumerate(data['characters']):
            far, sweep, close = (character['moves'][i] for i in [2, 6, 32])
            if not close['enabled']:
                # Existing authored c.S attacks (Smoke, Tapper, Shark) are retained.
                close = copy.deepcopy(far)
                close.update(id='c.S', enabled=1, button=2, category=0, direction=5,
                    startup=[8, 7, 8, 7, 7, 6][c], active=3, recovery=12,
                    damage=min(1000, far['damage']+8), selfCancel=0, jumpCancel=1,
                    proximityMove=-1, normalRoutes=-1, hitboxTimeline={'multiHit':False,'keys':[]})
                geo = [1200, 4000, [8500, 7500, 8500, 8500, 8500, 8000][c], 11500]
                if data is defaults:
                    close['hitPose']=3
                    close['geometry']=geo
                else:
                    close.update(hitboxBack=geo[0],bottom=geo[1],reach=geo[2],height=geo[3]-geo[1])
                character['moves'][32] = close
            if far['proximityMove'] != 32:
                far['proximityRange'] = [9500,8500,11000,9500,8500,8000][c]
            far['proximityMove'] = 32
            # A dedicated low sweep, with finite single-hit geometry and a clear
            # punish window even if the last active frame is the blocked frame.
            sweep.update(enabled=1,button=2,category=0,direction=2,motion=0,air=0,
                hitLevel=1,knockdown=2,knockdownFrames=36,launch=0,airLaunch=0,
                jumpCancel=0,selfCancel=0,whiffCancel=0,specialCancel=1,
                blockPushback=600,guardBreak=0,airCounterKnockdown=0,
                groundBounce=0,wallBounce=0,crumpleFrames=0)
            sweep['recovery'] = max(sweep['recovery'],sweep['blockstun']+12-(sweep['active']-1),sweep['blockstun']+7)
            old = draft['characters'][c]['moves'][6]
            back = max(-1000, old['hitboxBack'])
            geo = [back, 0, old['reach'], 3500]
            if data is defaults:
                sweep['hitPose']=3
                sweep['geometry']=geo
            else:
                sweep.update(hitboxBack=back,bottom=0,height=3500)
            track=sweep.setdefault('hitboxTimeline',{'multiHit':False,'keys':[]})
            track['multiHit']=False
            for key in track['keys']:
                key['hit']=1
                key['blockstun']=-1
                if key['boxes'] is not None:
                    key['boxes']=[[max(-1000,b[0]),0,b[2],3500] for b in key['boxes']]
    notes=draft.setdefault('_moveWorkshop',{'version':1,'notes':{}})['notes']
    for character in draft['characters']:
        name=character['name']
        for slot,addition in [
            (2,'Standing S selects c.S inside the editable root-distance threshold, otherwise f.S. After c.S contact, standing S gatlings into f.S even at close range.'),
            (32,'Close Slash: selected by standing S at close range. Unified cancels add f.S and 2S on contact, alongside Hs, command normals, specials and jump. Current artwork is reused until a dedicated pose pass.'),
            (6,'Universal 2S sweep: low, single hit, hard knockdown with 36f down time; no jump cancel. Uncancelled recovery is at least −12 on first-active block and −7 on last-active block. Special cancels remain available. Future artwork should sweep the lower legs; keep weapons outside hurtboxes.')]:
            move=character['moves'][slot]
            note=notes.setdefault(name+'/'+move['id'],{})
            note['intent']=note.get('intent','')+('\n\n' if note.get('intent') else '')+addition
            if slot==32:note.setdefault('label','Close Slash')
    save(ROOT/'godot/data/starter_moves.json',defaults)
    save(folder/DEST,draft)
    save(folder/'current.json',dict(label='Close/far Slash + universal 2S sweeps · 19 November 2026',status='playable tuning iteration',file=DEST,
        sha256=hashlib.sha256((folder/DEST).read_bytes()).hexdigest(),sourceFile=SOURCE,sourceSha256=hashlib.sha256(raw).hexdigest(),previousFile=PREVIOUS,baseCommit='a9b3bad',
        note='Latest user export preserved unchanged. Only standing Slash proximity, previously disabled c.S slots and 2S sweep tuning change; art briefs are appended. Existing c.S tuning, other moves, movement, rules and all pose references are preserved.'))
    print('Applied close/far Slash and hard-knockdown 2S sweeps to six fighters.')

if __name__=='__main__':main()
