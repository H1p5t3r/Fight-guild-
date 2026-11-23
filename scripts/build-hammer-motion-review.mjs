import {readFile} from 'node:fs/promises';
import {inputName} from '../web/workbench/model.mjs';
const phases=['active','windup','block','signature_windup','signature_active','ready','walk','run','stance','knockdown','knockdown_back','idle','crouch_idle','back_walk','attack_animation','backdash'];
export async function buildHammerMotionReview({pack,images,engine}){
 const {CombatPreview}=await import('../web/workbench/simulation.mjs');
 const preview=new CombatPreview(pack),data=pack.draft?.data??pack.defaults,saved=engine.data();preview.engine=engine;
 const files=new Set();
 const tile=f=>{
  const sheet=pack.art[f.character][phases[f.posePhase]],key=sheet.frames[f.poseIndex];
  const t={file:key.file??sheet.file,region:key.render_region??key.region,pivot:key.pivot,body_height:key.body_height??sheet.body_height,x:f.x/100,y:f.y/100,facing:f.facing};files.add(t.file);
  if(key.effect){const fx=pack.art[f.character][key.effect.sheet],image=fx.frames[key.effect.pose];t.effect={...key.effect,file:image.file??fx.file,region:image.region};files.add(t.effect.file);}
  return t;
 };
 const frames=record=>record.frames.map((frame,tick)=>{
  const s=frame.state,a=s.players[0],b=s.players[1];
  return {tick,age:a.age,move:a.move,hitstop:s.hitstop,actor:tile(a),target:tile(b),damage:1000-b.health,combo:a.combo,contact:frame.contact,stage:frame.stage,driveUsed:a.driveUsed,driveBonus:a.driveBonus,driveDistance:a.driveAutoDistance/100,vx:a.vx/100,boxes:frame.boxes.map(p=>({hurt:p.hurt.map(b=>b.map(v=>v/100)),hit:p.hit.map(b=>b.map(v=>v/100)),push:p.push.map(b=>b.map(v=>v/100))}))};
 });
 const moves=[];
 try{
  for(const [slot,m]of data.characters[1].moves.entries()){
   if(!m.enabled)continue;
   const scenarios={},notes={};const gap=slot===2?180:slot===13?230:slot===14?160:slot===6?55:slot===32||m.category===4?0:15;
   for(const scenario of ['hit','block','whiff']){
    const record=preview.record(data,1,slot,{targetEntry:m.air&&scenario!=='whiff'?'jump':'standing',isolated:slot===32&&scenario==='whiff',gap:scenario==='whiff'?450:gap,behavior:scenario==='block'?(m.hitLevel===1?'crouch':'block'):'hit',mechanic:m.mechanic===5?'followup':'single'});
    if(!record.executed)throw Error('Hammer review failed to execute '+slot);
    scenarios[scenario]=frames(record);notes[scenario]=record.warnings;
   }
   moves.push({slot,id:inputName(m),name:data._moveWorkshop?.notes?.['Hammer/'+m.id]?.label??inputName(m),timing:[m.startup,m.active,m.recovery],scenarios,notes});
  }
  for(const route of [{name:'f.S pressure → Break Step',gap:110,queue:[2,14,13,32],behavior:'block'},{name:'Close confirm → Drive → launcher',gap:0,queue:[32,2,14,13,32,3,16],behavior:'hit'}]){
   const record=preview.recordSequence(data,1,13,route.queue.map(move=>({move,delay:0})),{gap:route.gap,behavior:route.behavior});
   moves.push({slot:-1,id:'ROUTE',name:route.name,timing:[],behavior:route.behavior,steps:record.steps,warnings:record.warnings,scenarios:{hit:frames(record),block:frames(record),whiff:frames(record)}});
  }
 }finally{engine.loadData(saved);}
 const review={fps:60,moves,images:Object.fromEntries([...files].map(f=>[f,images[f]]))};
 const html=await readFile(new URL('../web/workbench/hammer-motion-review.html',import.meta.url),'utf8');
 return html.replace('__HAMMER_REVIEW_PACK__',()=>JSON.stringify(review).replace(/<\/script/gi,'<\\/script'));
}
