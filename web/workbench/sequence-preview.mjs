import {Engine,INPUT} from '../engine.mjs';
import {createCombatCore} from '../generated/fight-core.mjs';
import {validateSequence} from './sequences.mjs';
import {moveName} from './model.mjs';

const MAX_FRAMES=1800,MAX_WAIT=360;
export function recordSequence(preview,data,character,slot,queue,options,directionBits){
 validateSequence(queue,data.characters[character].moves.length);
 const e=preview.engine,probe=preview.sequenceProbe??=new Engine({exports:createCombatCore()}),moves=data.characters[character].moves;
 const target=Number(options.target??(character===5?4:5)),facing=options.facing===-1?-1:1,simple=!!options.simple;
 const behavior=options.behavior||'hit',entry=options.entry||'standing',gap=Math.max(0,Math.min(450,Number(options.gap??24)));
 e.loadData(data);probe.loadData(data);e.reset([character,target],[simple,false]);
 const separation=preview.pack.collisions[character].push.halfWidth+preview.pack.collisions[target].push.halfWidth+Math.round(gap*100),origin=facing===1?45000:55000;
 e.api.fg_preview_place(0,origin,0,10000);e.api.fg_preview_place(1,origin+facing*separation,behavior==='air'?12000:0,10000);
 const result={sequence:true,character,target,slot,moves:structuredClone(moves),steps:queue.map(s=>({...s})),frames:[],contacts:[],warnings:[],executed:false,maxCombo:0,totalDamage:0,displacement:0};
 let elapsed=0,lastContacts=0,currentStep=-1,lastSlot=slot;
 const defend=engine=>{const p=engine.state().players[1],back=directionBits(4,p.facing);return behavior==='block'?back:behavior==='crouch'?back|INPUT.down:behavior==='fd'?back|INPUT.faultless:0;};
 const capture=(input,stage)=>{
  const state=e.state(),a=state.players[0],b=state.players[1];if(a.move>=0)lastSlot=a.move;
  const frame={state,input,stage,sequenceStep:currentStep,moveSlot:lastSlot,selectedFrame:a.move>=0?a.age:0,boxes:[0,1].map(p=>({hurt:e.boxes(p,0),push:e.boxes(p,1),hit:e.boxes(p,2),projectiles:e.boxes(p,4)})),contact:null};
  if(a.contactCount!==lastContacts){frame.contact={tick:elapsed,event:a.event,damage:a.lastDamage,combo:a.combo,x:b.x,y:b.y+7500};result.contacts.push(frame.contact);}
  frame.cues=e.feedbackEvents();lastContacts=a.contactCount;result.maxCombo=Math.max(result.maxCombo,a.combo);result.frames.push(frame);return state;
 };
 const step=(input,stage)=>{e.step(input,defend(e));elapsed++;return capture(input,stage);};
 capture(0,'Ready');
 if(entry==='walk'||entry==='run')for(let i=0;i<12;++i)step(directionBits(6,facing)|(entry==='run'&&i===0?INPUT.dash:0),'Approach');
 if(entry==='jump'||entry==='forwardJump'){
  step(INPUT.up|(entry==='forwardJump'?directionBits(6,facing):0),'Jump approach');
  for(let i=0;i<11;++i)step(entry==='forwardJump'?directionBits(6,facing):0,'Jump approach');
 }
 // Probe a copy of the actual state. Failed commands never alter the visible
 // simulation, consume its buffer, force a move, or manufacture a cancel.
 function candidate(wanted){
  const m=wanted===32?moves[2]:moves[wanted];probe.restore(e.snapshot());const serial=probe.attackSerial(),inputs=[];let unexpected=-1;
  const advance=input=>{
   probe.step(input,defend(probe));inputs.push(input);const state=probe.state(),p=state.players[0];
   if(probe.attackSerial()!==serial){if(p.move===wanted)return {inputs:[...inputs],success:true};return {success:false,unexpected:p.move};}
   return null;
  };
  if(m.air&&probe.state().players[0].y<=0){
   const jumped=advance(INPUT.up);if(jumped)return jumped;
   for(let n=0;n<40&&probe.state().players[0].y<=0;++n){const started=advance(0);if(started)return started;}
   if(probe.state().players[0].y<=0)return {success:false,unexpected};
  }
  const p=probe.state().players[0],dir=p.facing;
  const commands=m.category===4&&!m.motion?[directionBits(m.direction===4?4:6,dir)|INPUT.P|INPUT.K]:simple&&m.simpleDirection?[directionBits(m.simpleDirection,dir)|INPUT.simple|(INPUT.P<<m.simpleButton)]:m.motion?String(m.motion).split('').map((d,i,a)=>directionBits(Number(d),dir)|(i===a.length-1?INPUT.P<<m.button:0)):[directionBits(m.direction,dir)|(INPUT.P<<m.button)];
  if(commands.length===1&&(p.raw&commands[0]&(INPUT.P|INPUT.K|INPUT.S|INPUT.Hs|INPUT.D))){const started=advance(0);if(started)return started;}
  for(const input of commands){const started=advance(input);if(started)return started;}
  // Respect the real button buffer, including inputs entered just before the
  // first cancel/recovery frame. No attacks are started through preview_begin.
  for(let n=0;n<=data.inputRules.buttonBuffer;++n){const started=advance(0);if(started)return started;}
  return {success:false,unexpected};
 }
 for(let i=0;i<queue.length&&elapsed<MAX_FRAMES;++i){
  const row=result.steps[i],m=moves[row.move];let remaining=null,wait=0,started=false,unexpected=-1;
  if(!m.enabled)row.error='Move is disabled.';
  else if(simple&&m.motion&&!m.simpleDirection)row.error='No simple-input mapping.';
  if(row.error){result.warnings.push(`Step ${i+1} (${moveName(m)}): ${row.error}`);break;}
  while(wait<MAX_WAIT&&elapsed<MAX_FRAMES&&e.state().winner===-1){
   const state=e.state();
   if(state.hitstop||state.wallBreakTime){step(0,'Freeze / transition');continue;}
   const attempt=candidate(row.move);if(attempt.unexpected>=0)unexpected=attempt.unexpected;
   if(attempt.success&&remaining===null){remaining=row.delay;row.opportunity=elapsed;}
   if(remaining!==null&&remaining>0){step(0,`Step ${i+1} delay`);remaining--;wait++;continue;}
   if(remaining===0&&attempt.success){
    const previousMove=state.players[0].move,serial=e.attackSerial();currentStep=i;row.input=elapsed+1;
    for(const input of attempt.inputs){const after=step(input,`Step ${i+1} · ${moveName(m)}`);if(e.attackSerial()!==serial&&after.players[0].move===row.move){row.start=elapsed;break;}}
    if(row.start!==undefined){row.route=i===0?'opener':m.air&&state.players[0].y<=0?'jump input':previousMove>=0?'cancel / buffered link':'after recovery';started=true;result.executed=true;break;}
   }
   // Once fully free, a conflicting or unavailable contextual mapping cannot
   // improve by waiting in place. Report it instead of silently using another move.
   if(!attempt.success&&state.players[0].move<0&&!state.players[0].stun&&!state.players[0].reaction&&!state.players[0].landingTime&&state.players[0].y===0&&!state.players[0].prejumpTime){
    row.error=m.mechanic===5&&state.players[0].driveUsed?'Break Step is spent. Return to neutral before another use.':unexpected>=0?`Input starts ${moveName(moves[unexpected])} at this spacing or stance.`:'Input unavailable in this state. Check its mapping and prerequisites.';break;
   }
   step(0,`Waiting for ${moveName(m)}`);wait++;
  }
  if(!started){row.error??=e.state().winner!==-1?'The target was defeated.':'No legal input within the preview limit.';result.warnings.push(`Step ${i+1} (${moveName(m)}): ${row.error}`);break;}
 }
 let quiet=0;
 while(elapsed<MAX_FRAMES&&e.state().winner===-1){
  const s=step(0,'Sequence recovery');
  const free=s.hitstop===0&&!s.wallBreakTime&&s.players.every(p=>p.move<0&&!p.stun&&!p.linePullTime&&!p.reaction&&!p.landingTime&&p.y===0)&&!s.projectiles.length;
  quiet=free?quiet+1:0;if(quiet>=24)break;
 }
 if(elapsed>=MAX_FRAMES)result.warnings.push('Preview stopped at 1,800 frames.');
 result.totalDamage=1000-e.state().players[1].health;result.displacement=(e.state().players[0].x-origin)/100;
 return result;
}
