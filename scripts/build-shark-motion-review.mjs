import {readFile} from 'node:fs/promises';
import {inputName} from '../web/workbench/model.mjs';
import {INPUT} from '../web/engine.mjs';
const json=async p=>JSON.parse(await readFile(new URL('../'+p,import.meta.url),'utf8'));
const phases=['active','windup','block','signature_windup','signature_active','ready','walk','run','stance','knockdown','knockdown_back','idle','crouch_idle','back_walk','attack_animation','backdash'];
export async function buildSharkMotionReview({art,roster,images,engine}){
 const baseline=await json('art/characters/shark-kit-v2/baseline-art.json'),beforeMoves=await json('art/characters/shark-kit-v2/baseline-moves.json');
 const saved=engine.data(),moves=[],files=new Set();
 function tile(fighter,phase,index){const sheet=fighter[phase],f=sheet.frames[index];const t={...f,file:f.file??sheet.file,body_height:f.body_height??sheet.body_height};files.add(t.file);if(t.effect)files.add(art[t.effect.sheet].file);return t;}
 const actual=f=>tile(roster[f.character],phases[f.posePhase],f.poseIndex);
 try{
  engine.api.fg_defaults();const data=engine.data();
  for(const [slot,m]of data.characters[4].moves.entries()){
   if(!m.enabled)continue;
   const {startup,active,recovery,hitstop}=m,total=startup+active+recovery-1;
   const before=[],prior=beforeMoves.moves[slot],old=baseline.attack_animations[String(slot)];
   for(let tick=1;tick<=total;tick++){
    const stage=tick<startup?'windup':tick<startup+active?'active':'recovery',start=stage==='windup'?1:stage==='active'?startup:startup+active,duration=stage==='windup'?startup-1:stage==='active'?active:recovery;
    const key=old?.[stage]?.findLast(k=>k.start<=Math.floor((tick-start)*100/Math.max(1,duration)));
    const selected=key?tile(baseline,key.phase,key.pose):prior.artPose?tile(baseline,stage==='windup'?'signature_windup':'signature_active',prior.artPose-1):tile(baseline,stage==='windup'?'windup':'active',stage==='windup'?prior.button+1:prior.button+1);
    if(!before.length||selected.file!==before.at(-1).file||String(selected.region)!==String(before.at(-1).region))before.push({...selected,action_frame:tick,motion_cue:'Previous drawings on the current action clock'});
   }
   const record=contact=>{
    const air=!!m.air,hook=m.hitAngle!==0,throwing=m.category===4,utility=m.mechanic>=4;
    let gap=contact?(throwing?4000:utility?22000:slot===13?13000:slot===2?10000:6500):45000;
    engine.reset([4,5]);engine.api.fg_preview_place(0,40000,0,10000);engine.api.fg_preview_place(1,40000+gap,0,10000);engine.step(0,0);
    if(air){engine.step(INPUT.up,contact&&!hook?INPUT.up:0);for(let i=0;i<6;i++)engine.step(0,0);}
    if(hook&&contact){if(!air)engine.api.fg_preview_place(1,40000+gap,14500,10000);else engine.api.fg_preview_place(0,40000,17000,10000);}
    if(utility&&contact)engine.api.fg_preview_status(1,2,14);
    engine.api.fg_preview_begin(0,slot);let lastAge=1,finished=0;const result=[];
    for(let tick=1;tick<=total+180;tick++){
     const stopped=engine.state().hitstop>0;engine.step(0,0);const state=engine.state(),f=state.players[0],b=state.players[1],paired=state.pairKind&&state.pairOwner===0;
     const actor=actual(f),target={...actual(b),x:(b.x-40000)/100,y:b.y/100,facing:b.facing};
     if(f.move===slot)lastAge=Math.max(1,f.age);
     const ended=f.move<0&&!paired;
     result.push({tick,frame:paired?startup:lastAge,actor,x:(f.x-40000)/100,y:f.y/100,facing:f.facing,target:contact?target:null,
      hits:engine.boxes(0,2).map(b=>[(b[0]-40000)/100,b[1]/100,(b[2]-40000)/100,b[3]/100]),hitstop:state.hitstop,stopped,
      pairKind:paired?state.pairKind:0,pairClock:paired?state.pairClock:0,damage:1000-b.health,stage:paired?'Capture':ended?'Reset':null,
      line:contact&&(b.tetherSource||b.pullTime&&slot===22||f.tetherChase&&slot===12)?{x:target.x,y:target.y+70,marked:!!b.tetherSource,time:b.tetherTime}:null,
      weapon:f.weaponVisible?{back:[(f.weaponBackX-40000)/100,f.weaponBackY/100],tip:[(f.weaponTipX-40000)/100,f.weaponTipY/100]}:null});
     if(ended){if(++finished>=12)break;}else finished=0;
    }
    return result;
   };
   const timeline=record(false),contactTimeline=record(true),after=art.attack_animation.frames.filter(f=>f.action_id===m.id&&!f.paired),paired=art.attack_animation.frames.filter(f=>f.action_id===m.id&&f.paired);
   const count=a=>new Set(a.map(f=>f.file+String(f.region))).size;
   moves.push({id:m.id==='5S'?'f.S':m.id,input:inputName(m),slot,label:({12:'Chase Line',13:'Set the Line',21:'Cast Down',22:'Reel In',28:'High Hook',29:'Dive Hook',30:'Knife follow-up',31:'Air knife follow-up',7:'Low Scoop'})[slot]??m.id,startup,active,recovery,hitstop,total,before,after,timeline,contactTimeline,beforeDrawings:count(before),afterDrawings:count([...after,...paired]),afterCues:after.length+paired.length,setup:utilityText(m),retimed:true});
  }
 }finally{engine.loadData(saved);}
 const previousCapture=tile(baseline,'active',9);files.add(art.line_fx.file);files.add(art.hook_weapon.file);
 for(const f of files)if(!images[f])throw Error('Missing Shark review image '+f);
 const pack={fps:60,moves,previousCapture,effects:{line_fx:art.line_fx},hookWeapon:art.hook_weapon,images:Object.fromEntries([...files].map(f=>[f,images[f]]))};
 return (await readFile(new URL('../web/workbench/shark-motion-review.html',import.meta.url),'utf8')).replace('__SHARK_REVIEW_PACK__',()=>JSON.stringify(pack).replace(/<\/script/gi,'<\\/script'));
}
function utilityText(m){return m.mechanic>=4?'Target starts with line attached':m.hitAngle?'Target placed on the diagonal hook path':m.air?'Both fighters airborne':'Standing target';}
