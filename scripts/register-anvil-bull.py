#!/usr/bin/env python3
"""Register immutable Bull drawings on native action/capture clocks."""
import copy
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'godot/assets/fighters'
PROD = ROOT / 'art/characters/anvil-bull-v2'
load = lambda p: json.loads(p.read_text())
def save(p, value): p.write_text(json.dumps(value, indent=2) + '\n')

# Measured anatomy: head center X / head top Y, belt Y, floor Y, root X.
# X is relative to the nominal column; Y is absolute in the immutable atlas.
# Beard, fur, shield and cloth never determine anatomical scale or hurt regions.
LANDMARKS = {
 'base': [(262,20,236,474,235),(262,20,236,474,235),(270,64,282,474,235),(260,526,734,968,235),(270,561,760,986,235),(266,551,766,986,235)],
 'walk': [(252,21,238,485,235),(252,22,238,485,235),(252,22,238,481,235),(252,532,749,996,235),(252,538,749,996,235),(252,532,749,996,235)],
 'drive': [(255,21,239,475,235),(255,21,239,480,235),(256,38,259,475,235),(249,536,727,964,235),(287,599,766,961,235),(273,640,821,996,235)],
 'dash': [(267,44,264,475,235),(281,34,240,480,235),(278,67,278,475,235),(259,540,749,990,235),(269,568,762,990,235),(262,550,767,989,235)],
 'checks': [(325,16,181,331,245),(365,77,236,330,265),(408,357,518,665,245),(465,435,581,665,260),(366,696,852,1008,245),(365,750,914,1008,265)],
 'kicks': [(335,0,163,337,270),(345,60,232,336,280),(316,350,505,672,265),(337,398,564,672,280),(326,690,854,1012,270),(334,723,900,1012,280)],
 'slashes': [(322,12,182,317,245),(300,22,185,317,245),(372,361,524,659,245),(341,379,530,659,245),(312,705,870,1010,245),(302,704,870,1010,245)],
 'heavy_sweep': [(376,18,183,348,260),(353,93,245,348,260),(408,379,534,676,235),(393,461,589,676,235),(361,699,858,1009,250),(356,744,910,1009,250)],
 'lift_anti': [(333,43,196,315,245),(324,78,207,315,245),(296,367,520,675,245),(395,402,547,675,245),(296,720,869,1006,245),(328,738,872,1006,245)],
 'rush': [(269,51,204,349,245),(330,75,226,349,245),(420,418,550,672,245),(460,413,540,672,245),(321,722,875,1009,245),(302,718,880,1009,245)],
 'air_checks': [(400,14,186,350,335),(335,9,171,335,290),(420,357,519,687,335),(293,360,501,669,290),(391,696,872,1038,335),(313,693,863,1025,290)],
 'air_swings': [(355,18,190,345,300),(299,39,211,366,290),(406,359,526,681,300),(410,406,558,713,290),(351,699,884,1039,300),(328,697,869,1024,290)],
 'grabs': [(430,43,207,320,335),(373,21,197,320,330),(394,400,544,696,350),(359,389,538,696,330),(410,765,911,1006,350),(401,739,884,1006,330)],
 'reactions_high': [(365,12,176,327,345),(386,31,188,327,345),(338,346,510,669,345),(390,405,552,669,345),(369,691,858,1008,345),(388,765,909,1008,345)],
 'reactions_low': [(414,31,190,339,370),(263,20,158,340,310),(410,390,537,672,370),(294,373,523,703,310),(414,760,903,1009,370),(321,745,907,1087,310)],
 'down_back': [(229,170,265,326,385),(272,103,251,326,385),(421,394,542,650,385),(430,386,530,650,385),(456,735,883,1001,385),(375,686,857,1001,345)],
 'down_prone': [(522,146,232,268,385),(518,78,222,268,385),(509,339,485,578,385),(463,313,476,580,385),(431,655,819,987,370),(386,610,786,987,345)],
 'iron_turn': [(265,375,551,770,240),(148,405,565,770,240),(130,446,590,770,240)],
}
HEIGHTS = {name: 300 for name in LANDMARKS}
# Anatomical calibration, independent of an attack's reach or the alpha bounds.
# The initial 300px attack-sheet default enlarged shoulders/heads relative to
# the approved idle. Keep one scale throughout each source's motion, including
# horizontal knockdown and airborne drawings; never fit a pose to its cell.
HEIGHTS.update(base=425, walk=435, drive=435, dash=435, checks=325,
 kicks=325, slashes=335, heavy_sweep=335, lift_anti=325, rush=330,
 air_checks=330, air_swings=335, grabs=330, reactions_high=330,
 reactions_low=330, down_back=350, down_prone=345, iron_turn=400)
# Individual source poses with a strongly extended anatomical limb. Never shield.
EXTENSIONS = {
 ('checks',2):[365,410,590,470],('checks',3):[430,490,615,550],
 ('kicks',2):[360,468,615,550],('kicks',3):[360,591,605,667],
 ('slashes',3):[380,423,586,480],('heavy_sweep',2):[430,427,567,496],
 ('heavy_sweep',3):[424,533,610,626],('lift_anti',2):[335,366,432,444],
 ('lift_anti',3):[385,355,565,485],('rush',2):[440,482,571,568],
 ('air_checks',2):[400,411,640,471],('air_checks',3):[350,509,610,607],
 ('air_swings',2):[443,415,545,479],('air_swings',3):[445,477,553,568],
 ('grabs',2):[276,335,352,462],('grabs',3):[197,347,282,474],
}
# Shield silhouettes, nominal-column X / absolute Y. Masks are render-only;
# their inner grip cutout leaves the holding hand in the fighter's guild color.
SHIELDS = {
 'base':[(342,96,488,316),(342,96,488,316),(356,147,490,345),(337,588,480,805),(289,580,446,843),(345,614,492,832)],
 'walk':[(321,99,470,327),(321,99,470,327),(321,99,470,327),(321,611,470,839),(321,611,470,839),(321,611,470,839)],
 'drive':[(262,82,418,313),(262,82,418,313),(262,82,418,313),(277,560,427,760),(230,755,445,971),(280,757,480,996)],
 'dash':[(340,126,482,335),(345,115,476,310),(350,152,482,351),(340,617,482,826),(278,599,441,846),(350,620,490,842)],
 'checks':[(383,30,492,211),(423,63,504,253),(179,372,274,541),(188,396,301,552),(165,731,245,902),(406,761,503,943)],
 'kicks':[(385,29,500,190),(375,95,487,266),(354,344,449,476),(375,419,486,571),(381,722,488,867),(355,758,471,918)],
 'slashes':[(374,31,466,209),(32,115,160,280),(430,348,580,554),(554,361,697,542),(368,731,476,902),(365,753,490,928)],
 'heavy_sweep':[(113,14,258,177),(329,184,467,352),(562,390,703,540),(538,589,750,676),(421,730,549,911),(377,832,529,1001)],
 'lift_anti':[(357,110,466,291),(336,63,437,237),(414,310,552,483),(96,415,205,569),(374,704,514,873),(93,773,181,934)],
 'rush':[(292,0,464,160),(331,114,447,322),(523,435,714,662),(498,394,632,619),(418,764,543,964),(335,757,443,949)],
 'air_checks':[(443,26,595,217),(366,26,516,211),(440,374,566,564),(376,390,506,518),(443,708,587,915),(356,711,486,890)],
 'air_swings':[(397,46,498,223),(317,12,478,143),(538,367,675,530),(454,533,650,678),(420,735,525,930),(388,756,515,947)],
 'grabs':[(462,76,546,253),(415,57,501,237),(443,455,537,632),(378,441,476,581),(452,794,539,966),(416,753,472,885)],
 'reactions_high':[(446,50,600,231),(450,82,588,269),(473,395,635,571),(468,416,626,607),(468,746,632,940),(468,782,626,986)],
 'reactions_low':[(451,38,589,218),(372,10,535,185),(450,383,593,557),(400,352,514,527),(450,738,600,922),(317,696,476,857)],
 'down_back':[(302,89,447,219),(338,74,453,232),(451,390,590,566),(454,399,574,593),(478,753,585,943),(416,735,555,931)],
 'down_prone':[(554,220,727,265),(578,220,727,265),(550,531,709,575),(486,429,620,574),(507,726,625,925),(462,674,596,900)],
 'iron_turn':[(299,417,427,590),(295,373,443,558),(310,383,437,566)],
}

# Palm support / collar anchors in original source pixels, not guessed from the
# whole sprite's bounds (which include weapons and loose clothing).
GRIPS = {'grabs':[(412,210),(363,166),(312,368),(245,394),(403,985),(479,925)],
         'iron_turn':[(335,493),(267,459),(49,652)]}

PLAN = {0:('checks',[0,2,4]),4:('checks',[1,3,5]),1:('kicks',[4,2,4]),5:('kicks',[1,3,5]),32:('slashes',[0,2,4]),2:('slashes',[0,3,5]),3:('heavy_sweep',[0,2,4]),6:('heavy_sweep',[1,3,5]),7:('lift_anti',[0,2,4]),8:('lift_anti',[1,3,5]),11:('rush',[0,2,4]),28:('rush',[1,3,5]),30:('rush',[5,5,5]),17:('air_checks',[0,2,4]),18:('air_checks',[1,3,5]),19:('air_swings',[0,2,4]),20:('air_swings',[1,3,5]),13:('drive',[0,0,0]),21:('drive',[3,4,5]),14:('grabs',[0,0,0]),15:('grabs',[1,1,1]),16:('grabs',[3,2,3]),23:('grabs',[0,0,0]),24:('grabs',[0,0,0]),41:('air_checks',[0,0,4]),42:('air_checks',[0,0,4])}

def main():
    manifest=load(ART/'manifest.json'); collision=load(ROOT/'godot/data/fighter_collision.json')
    fighter=manifest['fighters'][0]; body=collision['fighters'][0]
    current=load(ROOT/'godot/data/workshop/current.json')
    moves=load(ROOT/'godot/data/workshop'/current['file'])['characters'][0]['moves']
    masks=load(ART/'pause-weapon-regions.json'); bank={}
    for source in load(PROD/'sources.json'):
        if source['id']=='shield_effects': continue
        name=source['id']; path=ART/'anvil-bull-v2'/source['file']; image=Image.open(path)
        assert hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256']
        alpha=image.getchannel('A'); pix=alpha.load(); cols=3 if name in ('base','walk','drive','dash','iron_turn') else 2
        rows=1 if name=='iron_turn' else 6//cols; width=1536//cols; items=[]
        xcuts=[0]+[min(range(k*width-45,k*width+46),key=lambda x:(sum(pix[x,y]>32 for y in range(1024)),abs(x-k*width))) for k in range(1,cols)]+[1536]
        for i,(cx,head_top,hip,floor,root_x) in enumerate(LANDMARKS[name]):
            row,col=divmod(i,cols);left,right=xcuts[col:col+2];dx=col*width-left
            ycuts=[0]+[min(range(k*1024//rows-120,k*1024//rows+121),key=lambda y:(sum(pix[x,y]>32 for x in range(left,right)),abs(y-k*1024//rows))) for k in range(1,rows)]+[1024]
            top,bottom=ycuts[row:row+2];w,h=right-left,bottom-top
            bounds=alpha.crop((left,top,right,bottom)).point(lambda a:255 if a>32 else 0).getbbox(); assert bounds
            large=cols==3; hh=65 if large else 50; hw=56 if large else 49
            head=[cx-hw//2,head_top,cx+hw//2,head_top+hh]
            center=(cx+root_x)//2
            torso=[center-(150 if large else 112),head_top+hh-12,center+(105 if large else 80),hip+20]
            leg_top=hip;leg_floor=min(floor,bottom-1)
            legs=[root_x-(140 if large else 125),leg_top,root_x+(190 if large else 190),max(leg_top+20,leg_floor)]
            if name=='down_prone' and i<2:
                legs=[45,head_top+35,350,floor];torso=[330,head_top+20,590,floor]
            elif name=='down_back' and i<2:
                legs=[390,175,660,floor];torso=[185,head_top+30,430,floor]
            boxes={'legs':legs,'torsoArms':torso,'head':head}
            if (name,i) in EXTENSIONS:boxes['extension']=EXTENSIONS[name,i]
            fit={'hurt':{k:[int(v[0]+dx),int(v[1]-top),int(v[2]+dx),int(v[3]-top)] for k,v in boxes.items()}}
            if len(boxes)==4:fit['extensionFor']='Actual extended forearm, hand or boot only; shield, beard, fur and cloth excluded.'
            air=name.startswith('air_') or name=='base' and i==3 or name=='drive' and i in (3,4) or name=='reactions_low' and i%2==1
            pivot_y=hip+(200 if large else 125) if air else floor
            frame=dict(file='anvil-bull-v2/'+source['file'],sha256=source['sha256'],source_size=[1536,1024],generation_file=Path(source['source']).name,region=[left,top,w,h],bounds=list(bounds),pivot=[root_x+dx,pivot_y-top],body_height=HEIGHTS[name],source_pose=i)
            frame['scale_group']=name
            if name in GRIPS:
                gx,gy=GRIPS[name][i];frame['grip']=[gx+dx,gy-top]
            items.append((frame,fit))
            # Preserve guild fill on the hand: an interior rectangular grip hole
            # splits the render-only shield mask into four polygons.
            l,t,r,b=SHIELDS[name][i];l+=dx;r+=dx;t-=top;b-=top
            grip=(l+(r-l)*.30,t+(b-t)*.40,l+(r-l)*.65,t+(b-t)*.70)
            a,c,d,e=[round(v) for v in grip]
            rectangles=[(l,t,r,c),(l,e,r,b),(l,c,a,e),(d,c,r,e)]
            masks[frame['file']+':'+','.join(map(str,frame['region']))]=[[[x1,y1],[x2,y1],[x2,y2],[x1,y2]] for x1,y1,x2,y2 in rectangles]
        bank[name]=items
    def sheet(items):
        frames=[copy.deepcopy(p[0]) for p in items]
        return dict(file=frames[0]['file'],sha256=frames[0]['sha256'],size=[1536,1024],body_height=frames[0]['body_height'],frames=frames,transparent_samples=[[0,0],[1535,0],[0,1023],[1535,1023]])
    # Original generated pixels, atlas regions only. Their world-space envelope
    # is the authored strike box, never part of Anvil's hurt silhouette.
    fxsource=next(s for s in load(PROD/'sources.json') if s['id']=='shield_effects')
    fxpath=ART/'anvil-bull-v2'/fxsource['file']
    assert hashlib.sha256(fxpath.read_bytes()).hexdigest()==fxsource['sha256']
    alpha=Image.open(fxpath).getchannel('A');fxframes=[]
    for i in range(4):
        x,y=(i%2)*768,(i//2)*512
        l,t,r,b=alpha.crop((x,y,x+768,y+512)).point(lambda a:255 if a>64 else 0).getbbox()
        fxframes.append(dict(region=[x+l,y+t,r-l,b-t],pivot=[0,b-t],bounds=[0,0,r-l,b-t]))
    fighter['shield_fx']=dict(file='anvil-bull-v2/'+fxsource['file'],sha256=fxsource['sha256'],size=[1536,1024],frames=fxframes)
    def register(phase,items):
        fighter[phase]=sheet(items)
        for index,frame in enumerate(fighter[phase]['frames']):
            frame.setdefault('name','Anvil / '+phase.replace('_',' ')+' / '+str(index+1))
        body['poses'][phase]=[copy.deepcopy(p[1]) for p in items]
    ready=bank['base'][0];crouch=bank['base'][2];jump=bank['base'][3]
    register('ready',[ready]);register('idle',[bank['base'][i] for i in (0,1,0,1)])
    fighter['idle']['frame_ticks']=[22,14,22,14]
    register('crouch_idle',[crouch]*4)
    register('walk',[bank['walk'][i] for i in (0,0,1,2,3,3,4,5)])
    register('back_walk',[bank['walk'][i] for i in (5,4,3,3,2,1,0,0)])
    register('run',[bank['dash'][i] for i in (0,0,1,1,1,2,2,2)])
    register('backdash',[bank['dash'][i] for i in (3,3,4,4,5,5)])
    register('stance',[bank['drive'][i] for i in (0,1,0,2)])
    register('knockdown',bank['down_prone']);register('knockdown_back',bank['down_back'])
    register('block',[bank['base'][4],bank['drive'][0],bank['drive'][1],bank['drive'][2],bank['base'][5],bank['reactions_high'][2]])
    contacts=[bank['checks'][2],bank['kicks'][2],bank['slashes'][3],bank['heavy_sweep'][2],bank['drive'][0]]
    register('active',[ready]+contacts+[bank['walk'][0],bank['walk'][3],jump,bank['reactions_high'][0],bank['down_prone'][0],crouch])
    register('windup',[ready,bank['checks'][0],bank['kicks'][4],bank['slashes'][0],bank['heavy_sweep'][0],bank['drive'][0]])
    # Preserve authored gameplay strike geometry, including disabled fallbacks.
    starter=load(ROOT/'godot/data/starter_moves.json')['characters'][0]['moves']
    for button in range(5):
        source=next(m for m in starter if m['button']==button and not m['air'] and 'geometry' in m)
        rect=source['geometry'];frame=fighter['active']['frames'][button+1];px,py=frame['pivot'];scale=frame['body_height']/15000
        body['poses']['active'][button+1]['strike']=[round(px+rect[0]*scale),round(py-rect[3]*scale),round(px+rect[2]*scale),round(py-rect[1]*scale)]
    frames=[];fits=[];clips={};paired={}
    def add(pair,slot,tick,role):
        f,h=copy.deepcopy(pair);f.update(action_id=moves[slot]['id'],action_frame=tick,motion_cue=role,name=moves[slot]['id']+' / '+role)
        index=len(frames);frames.append(f);fits.append(h);return index
    for slot,(name,keys) in PLAN.items():
        m=moves[slot];s,a,r=[m[k] for k in ('startup','active','recovery')]
        load_pose,contact,withdraw=[copy.deepcopy(bank[name][i]) for i in keys]
        if slot==15: load_pose=contact=withdraw=copy.deepcopy(bank['iron_turn'][0])
        release=copy.deepcopy(contact)
        if slot in (2,3,6,7,11,19,20,21,28,32):
            fx=1 if slot in (7,32) else 2 if slot in (11,20) else 3 if slot==21 else 0
            contact[0]['effect']=dict(sheet='shield_fx',pose=fx,box=[m['hitboxBack']/100,m['bottom']/100,m['reach']/100,(m['bottom']+m['height'])/100],opacity=.92,behind=False)
        neutral=jump if m['air'] else crouch if m['direction']==2 else ready
        # For grabs, contact means reaching, never the successful lift/slam.
        cues=[]
        if s>3:cues.append((1,neutral,'Entry'))
        cues.extend([(max(2 if s>3 else 1,(s-1)//3),load_pose,'Load / held through last startup'),(s,contact,'First-active snap'),(s+a,withdraw if slot==21 else release,'Contact ends / effect off'),(s+a+max(1,r//3),withdraw,'Withdraw'),(s+a+max(2,4*r//5),neutral,'Settle / lock persists')])
        clip=dict(artPose=m['artPose'],moveId=m['id'],windup=[],active=[],recovery=[],exposureTiming=dict(authoredTiming=[s,a,r],largestMotionBoundary=[s-1,s],source='anvil-bull-v2',fixedAnatomicalScale=True))
        for tick,pair,role in cues:
            phase='windup' if tick<s else 'active' if tick<s+a else 'recovery'
            start,duration=(1,s-1) if phase=='windup' else (s,a) if phase=='active' else (s+a,r)
            clip[phase].append(dict(start=(tick-start)*100//max(1,duration),phase='attack_animation',pose=add(pair,slot,tick,role)))
        clips[str(slot)]=clip
        if slot in (14,15,16,23,24,41,42):
            # Air/ordinary throws retain shorter catches. The large finishes are
            # reachable only while captured, then in connected recovery.
            indices=[0,2,4] if slot in (14,16) else [1,3,5] if slot==15 else [0,1,5]
            total={14:88,15:92,16:112}.get(slot,40)
            lift,slam={14:(26,82),15:(32,76),16:(12,100)}.get(slot,(total//3,total-7))
            timeline=[(0,indices[0]),(lift,indices[1]),(slam,indices[2])]
            pair_items=[bank['iron_turn'][i] for i in range(3)] if slot==15 else [bank['grabs'][i] for _,i in timeline]
            paired[str(slot)]=dict(moveId=m['id'],keys=[dict(tick=t,phase='attack_animation',pose=add(item,slot,t,'Captured / '+str(i))) for (t,i),item in zip(timeline,pair_items)])
    register('attack_animation',list(zip(frames,fits)))
    fighter['attack_animations']=clips;fighter['paired_animations']=paired
    fighter['attack_connected']={}
    for slot in (14,15,16):
        connected=copy.deepcopy(clips[str(slot)])
        connected['recovery'][0]['pose']=paired[str(slot)]['keys'][-1]['pose']
        fighter['attack_connected'][str(slot)]=connected
    fighter['reference']='art/characters/anvil-grappler-v1/high-clamp-hand-corrected.png'
    fighter['anatomical_scales']=HEIGHTS
    fighter['hud_portrait']=dict(file=ready[0]['file'],sha256=ready[0]['sha256'],region=[215,13,129,182])
    save(ART/'manifest.json',manifest);save(ROOT/'godot/data/fighter_collision.json',collision)
    (ART/'pause-weapon-regions.json').write_text('{\n'+',\n'.join('  '+json.dumps(k)+': [\n'+',\n'.join('    '+json.dumps(p,separators=(',',':')) for p in v)+'\n  ]' for k,v in masks.items())+'\n}\n')
    reactions=load(ART/'reactions-v1/manifest.json')
    reactions['fighters']['0']={}
    for family,name,indices in [('head','reactions_high',[0,2,4]),('chest','reactions_high',[1,3,5]),('legs','reactions_low',[0,2,4]),('air','reactions_low',[1,3,5])]:
        clip=sheet([bank[name][i] for i in indices]);clip['file']='../'+clip['file']
        for frame in clip['frames']:frame['file']='../'+frame['file']
        reactions['fighters']['0'][family]=clip
    save(ART/'reactions-v1/manifest.json',reactions)
    grabs=load(ART/'grabs-v1/manifest.json');items=[bank['grabs'][i] for i in (0,1,5)]+[bank['reactions_high'][i] for i in (1,3,5)]
    clip=sheet(items);clip['file']='../'+clip['file']
    for i,frame in enumerate(clip['frames']):
        frame['file']='../'+frame['file'];frame['name']=['Grip catch','Grip load','Grip turn','Caught','Collar fold','Turned fold'][i]
        frame['contact']=[frame['pivot'][0]+70,frame['pivot'][1]-210]
    grabs['fighters']['0']=clip;save(ART/'grabs-v1/manifest.json',grabs)
    save(PROD/'registration.json',dict(actions=len(clips),actionKeys=len(frames),pairedActions=len(paired),sourceAtlases=len(bank),poseCounts={p:len(fighter[p]['frames']) for p in body['poses'] if p in fighter},pixelEdits=False))
    print(f'Anvil Bull: {len(clips)} action clips, {len(frames)} action keys, {len(paired)} paired tracks; {len(bank)} body atlases + magma effects.')

if __name__=='__main__': main()
