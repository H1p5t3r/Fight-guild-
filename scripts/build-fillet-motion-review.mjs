import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {INPUT} from '../web/engine.mjs';
const root=new URL('../',import.meta.url),path=p=>fileURLToPath(new URL(p,root));
const phases=['active','windup','block','signature_windup','signature_active','ready','walk','run','stance','knockdown','knockdown_back','idle','crouch_idle','back_walk','attack_animation','backdash'];

// Real poses, roots, landing interrupts and capture clocks. The before column
// substitutes old drawings only; it never invents movement or collision events.
export async function buildFilletMotionReview({art,roster,images,engine}){
 const baseline=JSON.parse(await readFile(path('art/characters/fillet-v1/production/kit-timing/baseline.json'),'utf8'));
 const source=JSON.parse(await readFile(path('art/characters/fillet-v1/FILLET_SPEC.json'),'utf8'));
 const moves=[],files=new Set(),saved=engine.data();
 const tileFor=f=>{
  const sheet=roster[f.character][phases[f.posePhase]],body=sheet?.frames[f.poseIndex];
  if(!body)throw Error(`Missing body ${f.character}/${f.posePhase}/${f.poseIndex}`);
  const tile={...body,file:body.file??sheet.file,body_height:body.body_height??sheet.body_height??150};
  files.add(tile.file);if(tile.effect)files.add(art[tile.effect.sheet].file);return tile;
 };
 try{
  engine.api.fg_defaults();
  for(const [id,old] of Object.entries(baseline.actions)){
   const action=source.actions.find(a=>a.id===id),after=art.attack_animation.frames.filter(f=>f.action_id===id&&!f.paired);
   const move=engine.data().characters[5].moves[old.slot];
   const {startup,active,recovery,hitstop}=move,total=startup+active+recovery-1;
   const record=contact=>{
    const air=id.startsWith('j.'),command=['236D','214D'].includes(id),normalThrow=id.includes('P+K');
    const gap=contact?(id==='236K'?11000:command?17000:normalThrow?3500:id==='5D'?5000:air?5500:6200):45000;
    engine.reset([5,4]);engine.api.fg_preview_place(0,40000,0,0);engine.api.fg_preview_place(1,40000+gap,0,0);engine.step(0,0);
    if(air){engine.step(INPUT.up,contact&&id!=='j.K'?INPUT.up:0);for(let i=0;i<5;i++)engine.step(0,0);}
    if(command)engine.api.fg_preview_status(1,1,20);
    if(id==='5D'&&contact)engine.api.fg_preview_status(1,0,180);
    if(!engine.api.fg_preview_begin(0,old.slot))throw Error('Could not preview '+id);
    const result=[];let lastAge=1,finished=0;
    for(let tick=1;tick<=total+160;tick++){
     const stopped=engine.state().hitstop>0;engine.step(0,0);
     const state=engine.state(),f=state.players[0],defender=state.players[1],paired=!!state.pairKind&&state.pairOwner===0;
     const actor=tileFor(f),target={...tileFor(defender),x:(defender.x-40000)/100,y:defender.y/100,facing:defender.facing};
     if(f.move===old.slot)lastAge=Math.max(1,f.age);else if(f.displayMove===old.slot)lastAge=f.displayAge;
     const ended=f.move<0&&f.displayMove!==old.slot&&!paired;
     const stage=paired?'Capture':ended?(air&&f.y===0?'Landing / reset':'Release / reset'):null;
     result.push({tick,frame:paired?startup:lastAge,drawing:actor.action_frame??null,actor,
       x:(f.x-40000)/100,y:f.y/100,facing:f.facing,
       hits:engine.boxes(0,2).map(b=>[(b[0]-40000)/100,b[1]/100,(b[2]-40000)/100,b[3]/100]),
       hitstop:state.hitstop,stopped,target:contact?target:null,pairKind:paired?state.pairKind:0,pairClock:paired?state.pairClock:0,stage,
       damage:1000-defender.health,landingTime:f.landingTime});
     if(ended){if(++finished>=12)break;}else finished=0;
    }
    return result;
   };
   const timeline=record(false),contactTimeline=record(true);
   for(const f of [...after,...old.frames]){files.add(f.file);if(f.effect)files.add(art[f.effect.sheet].file);}
   const count=frames=>new Set(frames.map(f=>f.file+JSON.stringify(f.region))).size;
   moves.push({id,label:action.name,startup,active,recovery,hitstop,total,before:old.frames,after,timeline,contactTimeline,
     beforeDrawings:count(old.frames),afterDrawings:count(after),retimed:true,
     setup:id==='5D'?'Downed target':id.endsWith('D')&&id!=='5D'?'Target with owned bleed':id==='j.K'?'Jumping kick / grounded target':id.startsWith('j.')?'Both fighters jump':'Standing target'});
  }
 }finally{engine.loadData(saved);}
 const previousCapture=tileFor({character:5,posePhase:0,poseIndex:9});
 for(const file of files)if(!images[file])throw Error('Missing comparison image: '+file);
 const pack={fps:60,moves,previousCapture,effects:Object.fromEntries(Object.entries(art).filter(([name])=>name.endsWith('_fx'))),images:Object.fromEntries([...files].map(file=>[file,images[file]]))};
 const template=await readFile(path('web/workbench/fillet-motion-review.html'),'utf8');
 return template.replace('__FILLET_REVIEW_PACK__',()=>JSON.stringify(pack).replace(/<\/script/gi,'<\\/script'));
}
