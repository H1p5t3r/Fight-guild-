import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {INPUT} from '../web/engine.mjs';
const root=new URL('../',import.meta.url),path=p=>fileURLToPath(new URL(p,root));
const phases=['active','windup','block','signature_windup','signature_active','ready','walk','run','stance','knockdown','knockdown_back','idle','crouch_idle','back_walk','attack_animation','backdash'];
const changed=new Set(['c.S','j.K','623Hs']);

// Isolate the action, then let the simulation own movement, contact, landing,
// hitstop and paired clocks. No generated-core import during a clean build.
export async function recordFilletMotionReview({art,roster,engine}){
 const source=JSON.parse(await readFile(path('art/characters/fillet-v1/FILLET_SPEC.json'),'utf8'));
 const moves=[],saved=engine.data();
 const tileFor=f=>{
  const sheet=roster[f.character][phases[f.posePhase]],body=sheet?.frames[f.poseIndex];
  if(!body)throw Error(`Missing body ${f.character}/${f.posePhase}/${f.poseIndex}`);
  return {...body,file:body.file??sheet.file,body_height:body.body_height??sheet.body_height??150};
 };
 try{
  for(const action of source.actions.filter(a=>art.attack_animations[a.slot])){
   const {id,slot}=action,frames=art.attack_animation.frames.filter(f=>f.action_id===id&&!f.paired);
   const captureFrames=art.attack_animation.frames.filter(f=>f.action_id===id&&f.paired);
   const move=saved.characters[5].moves[slot];
   const {startup,active,recovery,hitstop}=move,total=startup+active+recovery-1;
   const record=scenario=>{
    const contact=scenario!=='whiff',air=id.startsWith('j.'),command=['236D','214D'].includes(id),normalThrow=id.includes('P+K');
    const gap=contact?(id==='236K'?11000:command?17000:normalThrow?3500:id==='5D'?5000:air?5500:6200):45000;
    const guard=scenario==='block'?INPUT.right|(move.hitLevel===1?INPUT.down:0):0;
    engine.reset([5,4]);engine.api.fg_preview_place(0,40000,0,0);engine.api.fg_preview_place(1,40000+gap,0,0);engine.step(0,0);
    if(air){engine.step(INPUT.up,contact&&id!=='j.K'?INPUT.up:0);for(let i=0;i<5;i++)engine.step(0,0);}
    if(command)engine.api.fg_preview_status(1,1,20);
    if(id==='5D'&&contact)engine.api.fg_preview_status(1,0,180);
    if(!engine.api.fg_preview_begin(0,slot))throw Error('Could not preview '+id);
    const result=[];let lastAge=1,finished=0;
    for(let tick=1;tick<=total+160;tick++){
     const stopped=engine.state().hitstop>0;engine.step(0,guard);
     const state=engine.state(),f=state.players[0],defender=state.players[1],paired=!!state.pairKind&&state.pairOwner===0;
     const actor=tileFor(f),target={...tileFor(defender),x:(defender.x-40000)/100,y:defender.y/100,facing:defender.facing};
     if(f.move===slot)lastAge=Math.max(1,f.age);else if(f.displayMove===slot)lastAge=f.displayAge;
     const ended=f.move<0&&f.displayMove!==slot&&!paired;
     const stage=paired?'Capture':ended?(air&&f.y===0?'Landing / reset':'Release / reset'):null;
     const boxes=kind=>engine.boxes(0,kind).map(b=>[(b[0]-40000)/100,b[1]/100,(b[2]-40000)/100,b[3]/100]);
     result.push({tick,frame:paired?startup:lastAge,drawing:actor.action_frame??null,actor,
       x:(f.x-40000)/100,y:f.y/100,facing:f.facing,hits:boxes(2),hurt:boxes(0),
       hitstop:state.hitstop,stopped,target:contact?target:null,pairKind:paired?state.pairKind:0,pairClock:paired?state.pairClock:0,stage,
       damage:1000-defender.health,landingTime:f.landingTime,guarding:!!defender.guarding,contact:f.contact});
     if(ended){if(++finished>=12)break;}else finished=0;
    }
    return result;
   };
   moves.push({id,slot,label:action.name,startup,active,recovery,hitstop,total,frames,captureFrames,
     timeline:record('whiff'),contactTimeline:record('hit'),blockTimeline:record('block'),
     setup:id==='5D'?'Downed target':id.endsWith('D')&&id!=='5D'?'Target with owned bleed':id==='j.K'?'Jumping kick / grounded target':id.startsWith('j.')?'Both fighters jump':'Standing target'});
  }
 }finally{engine.loadData(saved);}
 return {fps:60,moves,effects:Object.fromEntries(Object.entries(art).filter(([name])=>name.endsWith('_fx')))};
}

export async function buildFilletMotionReview({art,roster,images,engine}){
 const before=JSON.parse(await readFile(path('art/characters/fillet-v1/production/guide-audit-v1/before.json'),'utf8'));
 const current=await recordFilletMotionReview({art,roster,engine}),files=new Set();
 const count=frames=>new Set(frames.map(f=>f.file+JSON.stringify(f.region))).size;
 const moves=current.moves.map(m=>{
  const old=before.moves.find(b=>b.id===m.id);if(!old)throw Error('Missing Fillet baseline '+m.id);
  for(const frames of [m.frames,old.frames,...['timeline','contactTimeline','blockTimeline'].flatMap(key=>[m[key],old[key]].filter(Boolean).map(track=>track.flatMap(k=>[k.actor,k.target].filter(Boolean))))])for(const f of frames)files.add(f.file);
  return {...m,after:m.frames,before:old.frames,beforeTimeline:old.timeline,beforeContactTimeline:old.contactTimeline,beforeBlockTimeline:old.blockTimeline,
   beforeDrawings:count([...old.frames,...(old.captureFrames??[])]),afterDrawings:count([...m.frames,...m.captureFrames]),afterCues:m.frames.length+m.captureFrames.length,changed:changed.has(m.id)};
 });
 for(const effects of [current.effects,before.effects])for(const sheet of Object.values(effects)){files.add(sheet.file);for(const f of sheet.frames)if(f.file)files.add(f.file);}
 for(const file of files)if(!images[file])throw Error('Missing Fillet comparison image: '+file);
 const pack={fps:60,moves,effects:current.effects,beforeEffects:before.effects,images:Object.fromEntries([...files].map(file=>[file,images[file]]))};
 const template=await readFile(path('web/workbench/fillet-motion-review.html'),'utf8');
 return template.replace('__FILLET_REVIEW_PACK__',()=>JSON.stringify(pack).replace(/<\/script/gi,'<\\/script'));
}
