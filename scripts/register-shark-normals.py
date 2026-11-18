#!/usr/bin/env python3
"""Register generated pixels unchanged; author roots, anatomy fits and action clocks."""
import copy
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'godot/assets/fighters'
DEST=ART/'shark-normals-v1'
load=lambda p:json.loads(p.read_text())
save=lambda p,d:p.write_text(json.dumps(d,indent=2)+'\n')
# Each pose: legs, torso/arms, head, optional extended arm. Local coordinates
# use the nominal 768x512 cell (768x1024 for Scoop); metadata adjusts trims.
# No cloth, hair, knife, hook or trail belongs to the vulnerable body.
FITS={
 'normals_0_fluid':[
  [[195,250,555,492],[258,94,506,257],[394,30,450,109],[467,122,529,185]],
  [[126,255,521,493],[225,100,466,271],[375,47,433,124],[450,116,582,168]],
  [[265,181,539,495],[256,83,442,261],[351,15,412,91],[248,185,305,263]],
  [[198,224,639,495],[262,101,464,266],[363,52,427,126],[201,192,294,268]],
 ],
 'normals_1_fluid':[
  [[174,277,567,480],[266,132,508,340],[464,100,529,177],[244,125,349,198]],
  [[174,263,533,480],[274,108,522,287],[408,51,469,122],[485,167,525,224]],
  [[138,266,552,480],[246,114,501,290],[414,54,476,127],[217,157,297,245]],
  [[43,272,510,481],[236,147,520,303],[386,80,451,151],[462,165,569,204]],
 ],
 'normals_2_fluid':[
  [[147,259,561,506],[247,89,547,293],[409,30,479,110],[523,242,587,301]],
  [[66,283,585,506],[265,133,536,316],[398,83,465,158],[487,175,587,249]],
  [[129,298,519,454],[222,127,529,311],[445,103,508,174],[497,192,549,241]],
  [[85,300,529,454],[199,126,512,316],[448,119,514,194],[495,171,638,230]],
 ],
 'normals_3_fluid':[
  [[139,299,523,492],[249,161,553,331],[469,134,535,212],[535,309,608,379]],
  [[136,335,657,492],[180,168,428,352],[405,179,468,253],[123,209,261,277]],
  [[127,273,536,473],[248,188,474,344],[448,154,515,227],[226,120,348,181]],
  [[11,277,411,473],[244,190,489,320],[398,160,461,234],[461,271,567,349]],
 ],
 'normals_4_fluid':[
  [[328,227,537,468],[252,94,527,246],[397,32,457,106],[470,125,527,178]],
  [[239,277,529,505],[252,122,540,291],[438,71,501,146],[531,192,609,254]],
  [[331,143,546,483],[201,91,452,265],[305,36,370,101],[147,179,241,285]],
  [[288,179,680,439],[180,93,413,250],[281,47,345,114],[98,193,211,278]],
 ],
 'normals_5_fluid':[
  [[360,185,535,408],[262,81,547,218],[410,30,472,95],[538,184,598,247]],
  [[76,201,443,461],[256,97,522,225],[397,48,457,115],[492,125,555,168]],
  [[400,199,591,474],[260,132,476,279],[336,70,398,132],[301,11,436,134]],
  [[236,245,514,489],[240,142,484,280],[420,134,479,201],[427,241,507,333]],
 ],
 'normals_6_fluid':[
  [[123,271,530,485],[239,136,546,282],[454,103,514,178],[509,146,555,198]],
  [[92,274,526,485],[223,147,465,291],[407,120,470,196],[460,59,595,154]],
  [[260,120,541,490],[183,93,454,247],[335,24,399,95],[514,199,585,258]],
  [[254,152,672,489],[147,100,403,269],[257,43,322,112],[100,191,216,285]],
 ],
 'normals_7_fluid':[
  [[174,282,599,485],[302,149,607,300],[395,74,450,143],[266,39,403,195]],
  [[105,277,502,486],[235,163,529,300],[460,119,518,191],[503,234,615,302]],
  [[181,282,541,489],[264,105,547,301],[394,43,456,118],[510,231,564,288]],
  [[164,286,557,488],[284,105,556,307],[426,50,489,125],[528,238,579,301]],
 ],
 'scoop_0':[
  [[90,480,667,856],[199,246,656,559],[408,136,500,246],[609,490,720,604]],
  [[25,470,648,853],[206,360,583,663],[510,310,610,417],[131,280,330,391]],
 ],
 'scoop_1':[
  [[55,575,636,920],[240,429,583,642],[485,372,593,483],[145,416,300,500]],
  [[32,550,674,920],[177,370,479,628],[328,282,409,380],[417,265,606,401]],
 ],
 'scoop_2':[
  [[24,580,680,952],[140,357,505,616],[310,275,405,384],[400,206,603,400]],
  [[40,566,653,950],[242,407,532,614],[465,389,559,487],[354,244,536,458]],
 ],
 'scoop_3':[
  [[85,533,680,935],[217,267,680,577],[500,165,596,284],[641,541,719,620]],
  [[69,513,664,935],[233,245,630,525],[441,123,549,242],[579,470,680,591]],
 ],
 'entries_0':[
  [[242,245,552,497],[267,96,535,260],[393,35,450,107],[510,194,578,262]],
  [[239,245,520,496],[228,93,531,261],[333,33,398,109],[489,211,553,274]],
  [[176,280,588,489],[287,132,500,301],[450,92,515,159],[206,121,327,202]],
  [[169,278,520,489],[284,94,531,297],[403,49,468,122],[505,238,547,292]],
 ],
 'entries_1':[
  [[171,258,573,495],[211,91,540,284],[381,27,439,102],[510,228,580,295]],
  [[148,286,517,493],[204,139,510,308],[414,107,479,182],[407,243,477,298]],
  [[194,303,656,476],[243,169,554,320],[457,137,521,215],[519,255,566,302]],
  [[99,277,523,474],[251,167,489,326],[435,132,501,203],[183,132,299,189]],
 ],
 'entries_2':[
  [[276,195,530,498],[263,91,564,218],[415,30,476,106],[474,134,534,180]],
  [[268,150,553,483],[195,99,428,216],[315,29,378,100],[199,164,264,265]],
  [[262,230,584,479],[288,95,595,240],[401,28,467,97],[200,129,326,205]],
  [[355,175,552,456],[267,73,519,199],[475,85,536,157],[301,27,433,151]],
 ],
 'entries_3':[
  [[177,286,545,490],[267,147,564,296],[451,106,512,180],[518,124,567,199]],
  [[247,179,538,496],[232,91,513,226],[309,30,371,108],[487,131,575,186]],
  [[234,193,586,372],[287,107,479,250],[426,91,494,165],[208,65,343,111]],
  [[143,290,540,489],[306,105,561,305],[462,92,530,166],[530,220,594,307]],
 ],
}

def main():
    manifest=load(ART/'manifest.json');collision=load(ROOT/'godot/data/fighter_collision.json')
    fighter,body=manifest['fighters'][4],collision['fighters'][4]
    assert fighter['name']==body['name']=='Shark'
    generations={r['id']:r for r in load(DEST/'generation.json')['generations']}
    catalog={}
    for name,poses in FITS.items():
        path=DEST/(name+'.png');im=Image.open(path)
        assert im.mode=='RGBA' and im.size==(1536,1024)
        records=[]
        for i,rectangles in enumerate(poses):
            scoop=name.startswith('scoop');row=0 if scoop else i//2
            cut=550 if name=='normals_2_fluid' else 512
            x,y=i%2*768,row*cut
            width,height=768,1024 if scoop else cut if row==0 else 1024-cut
            # Nonuniform generated gutters are metadata, never destructive crops.
            if name=='normals_6_fluid' and row:
                if i%2==0:width=700
                else:x,width=750,786
            if name in ['scoop_2','scoop_3']:
                x,width=(0,790) if i==0 else (798,738)
            shift=i%2*768-x
            alpha=im.getchannel('A').crop((x,y,x+width,y+height))
            bounds=alpha.point(lambda a:255 if a>32 else 0).getbbox()
            assert bounds and bounds[2]>bounds[0] and bounds[3]>bounds[1]
            # Manual sole levels; air art keeps a common virtual root below feet.
            ground=max(r[3] for r in rectangles[:1])
            if name in ['normals_4_fluid','normals_5_fluid','entries_2'] or name=='entries_3' and i==2:ground=490
            root=350 if not scoop else 390
            frame=dict(name=name+' '+str(i+1),file='shark-normals-v1/'+path.name,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),generation_file=Path(generations[name]['source']).name,region=[x,y,width,height],pivot=[root+shift,ground],bounds=list(bounds),body_height=850 if scoop else 540)
            boxes=[[l+shift,t,r+shift,b] for l,t,r,b in rectangles]
            hurt=dict(hurt=dict(zip(['legs','torsoArms','head','extension'],boxes)),extensionFor='Extended arm/hand only. Hook, knife, hair, cloth and weapon effects excluded.')
            records.append((frame,hurt))
        catalog[name]=records
    def sheet(records):
        return dict(file=records[0][0]['file'],sha256=records[0][0]['sha256'],size=[1536,1024],columns=2,rows=2,body_height=540,transparent_samples=[[0,0],[1535,0],[0,1023],[1535,1023]],frames=[copy.deepcopy(r[0]) for r in records])
    animation=sum([catalog['scoop_'+str(i)] for i in range(4)],[])
    for r,n in zip(animation,['Coil','Load','Scoop / hit1','Rise / hit2','Crest / hit2','Release','Recover','Reset']):r[0]['name']='2Hs / '+n
    # Preserve all four preexisting hook-pull and follow-up selectors.
    pairs=[('normals_0_fluid',0),('normals_0_fluid',2),('normals_1_fluid',0),('normals_1_fluid',2),('normals_2_fluid',0),('normals_2_fluid',2),('normals_3_fluid',0),('normals_3_fluid',2),('scoop_0',1),('normals_4_fluid',0),('normals_4_fluid',2),('normals_5_fluid',0),('normals_5_fluid',2),('normals_6_fluid',0),('normals_6_fluid',2),('normals_7_fluid',0)]
    slots=[0,1,32,2,3,4,5,6,7,17,18,19,20,8,9,11]
    moves=load(ROOT/'godot/data/starter_moves.json')['characters'][4]['moves']
    for phase in ['signature_windup','signature_active']:
        fighter[phase]['frames']=fighter[phase]['frames'][:4]
        body['poses'][phase]=body['poses'][phase][:4]
        for index,((name,i),slot) in enumerate(zip(pairs,slots)):
            rec=catalog[name][i+(phase=='signature_active')] if slot!=7 else animation[1 if phase=='signature_windup' else 2]
            frame,fit=copy.deepcopy(rec)
            frame['name']=moves[slot]['id']+' / '+('Windup' if phase=='signature_windup' else 'Active')
            if phase=='signature_active':fit['strike']=fit['hurt']['extension']
            fighter[phase]['frames'].append(frame);body['poses'][phase].append(fit)
    entry_slots=[0,1,32,2,3,4,5,6,17,18,19,20,8,9]
    entries=sum([catalog['entries_'+str(i)] for i in range(4)],[])
    for i,slot in enumerate(entry_slots):entries[i][0]['name']=moves[slot]['id']+' / Entry'
    animation.extend(entries[:14])
    animation.extend(catalog['normals_7_fluid'][2:])
    animation.extend(entries[14:])
    def key(start,phase,pose):return dict(start=start,phase=phase,pose=pose)
    clips={}
    for slot,index in list(zip(entry_slots,range(8,22)))+[(11,22)]:
        m=moves[slot];selector=slots.index(slot)+5
        initial=key(0,'active',8 if m['air'] else 6) if m['air'] or m['direction']==2 else key(0,'ready',0)
        clips[str(slot)]=dict(artPose=selector,windup=[initial,key(20,'attack_animation',index),key(60,'signature_windup',selector-1)],
            recovery=[key(0,'signature_active',selector-1),key(25,'signature_windup',selector-1),key(65,'attack_animation',index)])
    clips['7']=dict(artPose=13,windup=[key(0,'attack_animation',0),key(40,'attack_animation',1)],
        active=[key(0,'attack_animation',2),key(20,'attack_animation',3),key(60,'attack_animation',4)],
        recovery=[key(0,'attack_animation',5),key(30,'attack_animation',6),key(70,'attack_animation',7)])
    clips['20']['active']=[key(0,'signature_active',16),key(50,'attack_animation',24)]
    clips['11']['recovery']=[key(0,'signature_active',19),key(25,'attack_animation',23)]
    clips['3']['recovery']=[key(0,'signature_active',8),key(25,'attack_animation',25),key(70,'attack_animation',12)]
    assert len(animation)==26
    fighter['attack_animation']=sheet(animation)
    fighter['attack_animations']=clips
    fighter['normal_selection']=dict(direction='A / Shoulder Snap',launcher='2 / Low Scoop',motion='Approved fluidity study',source='references/frame-data/ky-kiske-2026-11-18')
    body['poses']['attack_animation']=[copy.deepcopy(r[1]) for r in animation]
    save(ART/'manifest.json',manifest);save(ROOT/'godot/data/fighter_collision.json',collision)
    save(DEST/'registration.json',dict(fits=FITS,bodyScale=dict(normal=540,scoop=850),notes='Scale is calibrated from anatomy, never whole weapon/effect bounds. Atlas pixels remain untouched. Source-image body fits are provisional and editable.'))
    print('Shark:20 signature pairs including4 preserved specials;26 animation keys; max4 body-only hurtboxes.')

if __name__=='__main__':main()
