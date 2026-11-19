import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
const root=new URL('../',import.meta.url),path=p=>fileURLToPath(new URL(p,root));

// Render the actual atlas selection from the simulation, with the previous
// eight-key clips alongside it. This never creates or alters character art.
export async function buildFilletMotionReview({art,roster,images,engine}){
 const baseline=JSON.parse(await readFile(path('art/characters/fillet-v1/production/ground-twos/baseline.json'),'utf8'));
 baseline.actions['2S']=JSON.parse(await readFile(path('art/characters/fillet-v1/production/sweep-timing/baseline.json'),'utf8'));
 const source=JSON.parse(await readFile(path('art/characters/fillet-v1/FILLET_SPEC.json'),'utf8'));
 const moves=[],files=new Set(),saved=engine.data();
 try{
  engine.api.fg_defaults();
  for(const [id,old] of Object.entries(baseline.actions)){
   const action=source.actions.find(a=>a.id===id),after=art.attack_animation.frames.filter(f=>f.action_id===id);
   const move=engine.data().characters[5].moves[old.slot];
   const {startup,active,recovery,hitstop}=move,total=startup+active+recovery-1;
   engine.reset([5,4]);engine.api.fg_preview_place(0,40000,0,0);engine.api.fg_preview_place(1,85000,0,0);engine.step(0,0);
   if(!engine.api.fg_preview_begin(0,old.slot))throw Error('Could not preview '+id);
   const timeline=[];
   for(let frame=1;frame<=total;frame++){
    engine.step(0,0);const f=engine.state().players[0],tile=art.attack_animation.frames[f.poseIndex];
    if(f.posePhase!==14||tile?.action_id!==id||tile.action_frame!==after.findLast(k=>k.action_frame<=frame)?.action_frame)throw Error('Review differs from simulation at '+id+'/'+frame);
    timeline.push({frame,drawing:tile.action_frame,x:(f.x-40000)/100,y:f.y/100,
                   hits:engine.boxes(0,2).map(b=>[(b[0]-40000)/100,b[1]/100,(b[2]-40000)/100,b[3]/100])});
   }
   const phases=['active','windup','block','signature_windup','signature_active','ready','walk','run','stance','knockdown','knockdown_back','idle','crouch_idle','back_walk','attack_animation','backdash'];
   engine.reset([5,4]);engine.api.fg_preview_place(0,40000,0,0);engine.api.fg_preview_place(1,50000,0,0);engine.step(0,0);engine.api.fg_preview_begin(0,old.slot);
   const contactTimeline=[];
   for(let tick=1;tick<=total+120;tick++){
    const stopped=engine.state().hitstop>0;engine.step(0,0);const state=engine.state(),f=state.players[0],defender=state.players[1];
    if(f.posePhase!==14)break;
    const tile=art.attack_animation.frames[f.poseIndex],phase=roster[4][phases[defender.posePhase]],body=phase.frames[defender.poseIndex];
    const target={...body,file:body.file??phase.file,body_height:body.body_height??phase.body_height,x:(defender.x-40000)/100,y:defender.y/100,facing:defender.facing};
    files.add(target.file);
    contactTimeline.push({tick,frame:Math.max(1,f.move<0?f.displayAge:f.age),drawing:tile.action_frame,x:(f.x-40000)/100,y:f.y/100,
      hits:engine.boxes(0,2).map(b=>[(b[0]-40000)/100,b[1]/100,(b[2]-40000)/100,b[3]/100]),hitstop:state.hitstop,stopped,target});
    if(f.move<0)break;
   }
   for(const f of [...after,...old.frames]){files.add(f.file);if(f.effect)files.add(art[f.effect.sheet].file);}
   const count=frames=>new Set(frames.map(f=>f.file+JSON.stringify(f.region))).size;
   moves.push({id,label:action.name,startup,active,recovery,hitstop,total,before:old.frames,after,timeline,contactTimeline,
     beforeDrawings:count(old.frames),afterDrawings:count(after),retimed:id==='2S'});
  }
 }finally{engine.loadData(saved);}
 for(const file of files)if(!images[file])throw Error('Missing comparison image: '+file);
 const pack={fps:60,moves,effects:Object.fromEntries(Object.entries(art).filter(([name])=>name.endsWith('_fx'))),images:Object.fromEntries([...files].map(file=>[file,images[file]]))};
 const template=await readFile(path('web/workbench/fillet-motion-review.html'),'utf8');
 return template.replace('__FILLET_REVIEW_PACK__',()=>JSON.stringify(pack).replace(/<\/script/gi,'<\\/script'));
}
