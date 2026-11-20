import {readFile} from 'node:fs/promises';
import {inputName,phaseAt} from '../web/workbench/model.mjs';

const phases=['active','windup','block','signature_windup','signature_active','ready','walk','run','stance','knockdown','knockdown_back','idle','crouch_idle','back_walk','attack_animation','backdash'];
export const smokeReviewActions=[
 {character:2,slot:15,gap:145,label:'Venom Sabre',changed:true},
 {character:2,slot:16,gap:230,label:'Furnace Cleaver',changed:true},
 {character:2,slot:14,gap:96,label:'Smoked Obsidian · close',changed:true},
 {character:2,slot:25,gap:246,label:'Smoked Obsidian · far',changed:true},
 {character:5,slot:6,gap:80,label:'Fillet · sweep benchmark'},
 {character:4,slot:7,gap:40,label:'Shark · Low Scoop benchmark'},
 {character:2,slot:7,gap:45,label:'Smoke · Backdraft audit'},
 {character:2,slot:2,gap:130,label:'Smoke · f.S audit'},
];
// Capture real input, contact and saved pose clocks, including hitstop. The
// baseline is recorded before changing registration, never guessed afterward.
export async function recordSmokeReview(pack,engine=null){
 // build-workbench creates fight-core.mjs before calling this function. Do not
 // import simulation at module startup: a clean checkout has no generated core.
 const {CombatPreview}=await import('../web/workbench/simulation.mjs');
 const preview=new CombatPreview(pack),data=pack.draft?.data??pack.defaults;
 if(engine)preview.engine=engine;
 const resolveTile=(c,phase,index)=>{
  const art=pack.art[c],sheet=art[phase],f=sheet.frames[index];
  const tile={...f,file:f.file??sheet.file,body_height:f.body_height??sheet.body_height,phase,index};
  if(f.effect){const fx=art[f.effect.sheet],key=fx.frames[f.effect.pose];tile.effect={...f.effect,file:key.file??fx.file,region:key.region};}
  return tile;
 };
 return smokeReviewActions.map(action=>{
  const {character,slot}=action,m=data.characters[character].moves[slot],scenarios={};
  for(const behavior of ['whiff','hit','block']){
   const record=preview.record(data,character,slot,{gap:behavior==='whiff'?450:action.gap,behavior:behavior==='whiff'?'hit':behavior});
   if(!record.executed)throw Error(`Review input did not execute ${character}/${slot}`);
   const origin=record.frames[0].state.players[0].x/100;
   scenarios[behavior]=record.frames.map((frame,tick)=>{
    const {state}=frame,actor=state.players[0];
    const body=(f)=>({...resolveTile(f.character,phases[f.posePhase],f.poseIndex),x:f.x/100-origin,y:f.y/100,facing:f.facing});
    return {tick,frame:frame.selectedFrame,phase:frame.selectedFrame?phaseAt(m,frame.selectedFrame):'neutral',
     actor:body(actor),target:behavior==='whiff'?null:body(state.players[1]),hitstop:state.hitstop,
     damage:1000-state.players[1].health,contact:frame.contact,event:actor.event,
     hits:frame.boxes[0].hit.map(([l,b,r,t])=>[l/100-origin,b/100,r/100-origin,t/100]),
     hurt:frame.boxes[0].hurt.map(([l,b,r,t])=>[l/100-origin,b/100,r/100-origin,t/100]),
     projectiles:state.projectiles.filter(q=>q.owner===0).map(q=>{
      const sheet=pack.art[character].projectile_variants?.[q.move]??pack.art[character].projectile;
      const index=q.life<=6?3:Math.floor(q.age/6)%3;
      return {file:sheet.file,region:sheet.frames?.[index].region??sheet.region,x:q.x/100-origin,y:q.y/100,width:q.width/100,height:q.height/100,facing:q.facing,age:q.age,life:q.life};
     })};
   });
  }
  return {...action,id:inputName(m),startup:m.startup,active:m.active,recovery:m.recovery,hitstop:m.hitstop,scenarios};
 });
}

export async function buildSmokeMotionReview({pack,images,engine=null}){
 const before=JSON.parse(await readFile(new URL('../art/characters/smoke-specials-v3/before.json',import.meta.url),'utf8'));
 const saved=engine?.data();let recorded;
 try{recorded=await recordSmokeReview(pack,engine);}finally{if(engine)engine.loadData(saved);}
 const moves=recorded.map((move,i)=>({...move,before:before[i].scenarios}));
 const files=new Set();
 for(const m of moves)for(const scenarios of [m.scenarios,m.before])for(const entries of Object.values(scenarios))for(const f of entries){
  for(const t of [f.actor,f.target].filter(Boolean)){files.add(t.file);if(t.effect)files.add(t.effect.file);}
  for(const q of f.projectiles)files.add(q.file);
 }
 for(const file of files)if(!images[file])throw Error('Missing Smoke review image '+file);
 const data={fps:60,moves,images:Object.fromEntries([...files].map(file=>[file,images[file]]))};
 const template=await readFile(new URL('../web/workbench/smoke-motion-review.html',import.meta.url),'utf8');
 return template.replace('__SMOKE_REVIEW_PACK__',()=>JSON.stringify(data).replace(/<\/script/gi,'<\\/script'));
}
