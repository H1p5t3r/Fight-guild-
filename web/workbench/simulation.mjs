import {Engine,INPUT,BUTTONS,MOVE_IDS} from '../engine.mjs';
import {createCombatCore} from '../generated/fight-core.mjs';
import {inputName,totalFrames} from './model.mjs';
import {recordSequence} from './sequence-preview.mjs';

export const directionBits=(n,facing=1)=>{
  const x=(n-1)%3-1,y=Math.floor((n-1)/3)-1;
  return (x?x*facing>0?INPUT.right:INPUT.left:0)|(y>0?INPUT.up:y<0?INPUT.down:0);
};
export function describeInput(bits,facing=1){
  const x=Number(!!(bits&INPUT.right))-Number(!!(bits&INPUT.left));
  const y=Number(!!(bits&INPUT.up))-Number(!!(bits&INPUT.down));
  const d=5+x*facing+y*3;
  const buttons=BUTTONS.filter((_,i)=>bits&(INPUT.P<<i));
  if(bits&INPUT.dash)buttons.push('Dash');if(bits&INPUT.simple)buttons.push('Modifier');
  return `${d}${buttons.length?' + '+buttons.join('+'):''}`;
}

// Each recording uses a separate copy of the actual C++ simulation translated
// to plain JS. Preview setup never writes into the user's Workshop draft.
export class CombatPreview {
  constructor(pack){this.pack=pack;this.engine=new Engine({exports:createCombatCore()});}
  recordSequence(data,character,slot,queue,options={}){return recordSequence(this,data,character,slot,queue,options,directionBits);}
  record(data,character,slot,options={}){
    const m=data.characters[character].moves[slot],target=Number(options.target??(character===5?4:5));
    const entry=options.entry||'standing',behavior=options.behavior||'hit',simple=!!options.simple;
    const gap=Math.max(0,Math.min(450,Number(options.gap??24)));
    const facing=options.facing===-1?-1:1,e=this.engine;
    e.loadData(data);e.reset([character,target],[simple,false]);
    const separation=this.pack.collisions[character].push.halfWidth+this.pack.collisions[target].push.halfWidth+Math.round(gap*100);
    // Keep both roots inside the stage at the full distance range in either facing.
    const origin=facing===1?45000:55000;
    e.api.fg_preview_place(0,origin,0,10000);
    e.api.fg_preview_place(1,origin+facing*separation,behavior==='air'?12000:0,10000);
    const result={frames:[],contacts:[],warnings:[],executed:false,requested:inputName(m),slot,character,target};
    let elapsed=0,quiet=0,lastGroups=0,followed=false;
    const mechanicTest=m.mechanic?(options.mechanic||'single'):'single';
    const capture=(input,stage)=>{
      const state=e.state(),players=state.players;
      const contact=players[0].contactCount!==lastGroups;
      const frame={state,input,stage,selectedFrame:players[0].move===slot?players[0].age:0,
        boxes:[0,1].map(p=>({hurt:e.boxes(p,0),push:e.boxes(p,1),hit:e.boxes(p,2),projectiles:e.boxes(p,4)})),contact:null};
      if(contact){frame.contact={tick:elapsed,event:players[0].event,damage:players[0].lastDamage,combo:players[0].combo,
        x:players[1].x,y:players[1].y+7500};result.contacts.push(frame.contact);}
      lastGroups=players[0].contactCount;
      if(players[0].move===slot||players[0].lastMove===slot)result.executed=true;
      result.frames.push(frame);return state;
    };
    const defenderInput=()=>{
      if(mechanicTest!=='single'&&!followed)return 0;
      const p=e.state().players[1],back=directionBits(4,p.facing);
      return behavior==='block'?back:behavior==='crouch'?back|INPUT.down:behavior==='fd'?back|INPUT.faultless:0;
    };
    const step=(input,stage)=>{e.step(input,defenderInput());elapsed++;return capture(input,stage);};
    capture(0,'Ready');
    if(mechanicTest!=='single')result.warnings.push('Status setup uses an unguarded hit. The selected guard behavior is used for the follow-up.');
    if(!m.enabled){result.warnings.push('Attack disabled: geometry only. You can edit its boxes here; enable it to test movement and contact.');return this.geometryRecord(result,m);}
    const forward=directionBits(6,facing);
    if(entry==='walk'||entry==='run')for(let i=0;i<12;++i)step(forward|(entry==='run'&&i===0?INPUT.dash:0),entry==='run'?'Run / step approach':'Walk approach');
    if(m.air||entry==='jump'||entry==='forwardJump'){
      step(INPUT.up|(entry==='forwardJump'?forward:0),'Jump input');
      for(let i=0;i<11;++i)step(entry==='forwardJump'?forward:0,'Jump approach');
    }
    const contextual=m.followFrom>=0||m.followFrom2>=0;
    if(contextual||m.stanceRequired===2||slot===32||slot===33||slot===34||slot===43||slot===44){
      // A selected rekka ending can be studied on its own without changing any
      // routes. This explicit isolated mode is identified in the visible result.
      e.api.fg_preview_begin(0,slot);
      result.warnings.push(m.stanceRequired===2?'Preview starts in rolling stance. Entry-route timing is tested separately.':'Isolated contextual action; input selection is not tested in this clip.');
    }else if(m.category===4&&!m.motion){
      step(directionBits(m.direction===4?4:6,facing)|INPUT.P|INPUT.K,'Throw input');
    }else if(simple){
      if(!m.simpleDirection){result.warnings.push('This attack has no simple-input mapping. Showing editable geometry only.');return this.geometryRecord(result,m);}
      step(directionBits(m.simpleDirection,facing)|INPUT.simple|(INPUT.P<<m.simpleButton),'Simple input');
    }else{
      const sequence=m.motion?String(m.motion).split('').map(Number):[m.direction];
      sequence.forEach((direction,index)=>step(directionBits(direction,facing)|(index===sequence.length-1?INPUT.P<<m.button:0),'Move input'));
    }
    let state=e.state();
    for(let i=0;i<4800;++i){
      state=step(m.actionType===1&&i<40?(INPUT.P<<m.holdButton):0,followed?'Drive follow-up':result.executed?'Attack & reaction':'Waiting for input');
      if(state.winner!==-1)break;
      const free=state.players.every(p=>p.move<0&&p.stun===0&&p.reaction===0&&p.landingTime===0&&p.y===0)&&state.hitstop===0&&!e.boxes(0,4).length&&!e.boxes(1,4).length;
      quiet=free?quiet+1:0;
      const status=state.players[1].tetherSource||state.players[1].bleedSource;
      if(mechanicTest==='followup'&&!followed&&status&&quiet>=6){
        followed=true;quiet=0;
        const dir=state.players[0].facing;
        if(simple)step(directionBits(m.simpleDirection,dir)|INPUT.simple|(INPUT.P<<m.simpleButton),'Follow-up input');
        else {const sequence=m.motion?String(m.motion).split('').map(Number):[m.direction];sequence.forEach((d,j)=>step(directionBits(d,dir)|(j===sequence.length-1?INPUT.P<<m.button:0),'Follow-up input'));}
      }else if(quiet>=24&&!(mechanicTest==='expire'&&state.players[1].bleedTime))break;
    }
    if(!result.executed){
      const actual=state.players[0].lastMove;
      result.warnings.push(actual>=0?`Input selected ${MOVE_IDS[actual]}, not ${m.id}. Check mappings, airborne state and competing moves.`:'The selected input did not start this attack. Check its mapping and grounded/airborne requirement.');
    }
    if(!result.executed){result.warnings.push('Showing the selected move’s geometry only; no contacts are simulated.');return this.geometryRecord(result,m);}
    if(result.frames.length>=4800)result.warnings.push('Preview stopped at the recording limit.');
    result.totalDamage=1000-state.players[1].health;
    result.displacement=(state.players[0].x-result.frames[0].state.players[0].x)/100;
    return result;
  }
  recordMovement(data,character,slot,action,options={}){
    const e=this.engine,target=Number(options.target??(character===5?4:5)),facing=options.facing===-1?-1:1;
    e.loadData(data);e.reset([character,target],[false,false]);
    e.api.fg_preview_place(0,50000,0,10000);
    e.api.fg_preview_place(1,50000+facing*(action==='fd'?10000:40000),0,10000);
    const result={frames:[],contacts:[],warnings:[],executed:true,requested:action,slot,character,target,movement:action,totalDamage:0,displacement:0};
    const forward=directionBits(6,facing),back=directionBits(4,facing),profile=data.characters[character].movement;
    if(action==='airForward'&&!profile.airDashEnabled||action==='airBack'&&!profile.airBackdashEnabled)result.warnings.push('This air dash direction is disabled for this character. Enable it to test the dash.');
    if(action==='airJump'&&!profile.airJumps)result.warnings.push('Additional air jumps are set to zero.');
    if(action==='rolling'&&character===3){e.api.fg_preview_begin(0,35);for(let n=0;n<60&&e.state().players[0].move>=0;++n)e.step(0,0);}
    if(action==='rolling'&&character!==3)result.warnings.push('Rolling stance is Tapper’s character mechanic.');
    let lastContact=0;
    for(let tick=0;tick<=150;++tick){
      let input=0,other=0;
      if(tick>0){
        if(action==='crouch')input=INPUT.down;
        if(action==='walk')input=tick<70?forward:0;
        if(action==='backWalk')input=tick<70?back:0;
        if(action==='forward'||action==='back')input=tick===1||tick>=3&&tick<65?(action==='forward'?forward:back):0;
        if(['jump','forwardJump','backJump','airForward','airBack','airJump'].includes(action)){
          input=tick===1?INPUT.up:0;
          if(action==='forwardJump'&&tick<50)input|=forward;
          if(action==='backJump'&&tick<50)input|=back;
          if(tick===14&&action==='airJump')input|=INPUT.up;
          if((tick===12||tick>=14&&tick<30)&&['airForward','airBack'].includes(action))input|=action==='airForward'?forward:back;
        }
        if(action==='fd'){
          input=back|INPUT.faultless;
          if(tick===12||tick===72)e.api.fg_preview_begin(1,2);
        }
        e.step(input,other);
      }
      const state=e.state(),frame={state,input,stage:state.players[0].dashTicks>0&&state.players[0].y>0&&state.players[0].dashAge===0?'Air dash pause':action==='fd'?'Faultless Defense':action.replace(/([A-Z])/g,' $1'),selectedFrame:0,boxes:[0,1].map(p=>({hurt:e.boxes(p,0),push:e.boxes(p,1),hit:e.boxes(p,2),projectiles:e.boxes(p,4)})),contact:null};
      if(state.players[1].contactCount!==lastContact){lastContact=state.players[1].contactCount;frame.contact={tick,event:state.players[1].event,damage:state.players[1].lastDamage,combo:state.players[1].combo,x:state.players[0].x,y:state.players[0].y+7500};result.contacts.push(frame.contact);}
      result.frames.push(frame);
    }
    result.displacement=(e.state().players[0].x-50000)/100;
    return result;
  }
  geometryRecord(result,move){
    // Disabled/unmapped attacks stay editable in the same scene. These frames
    // are explicitly labelled geometry-only and never claim a simulated hit.
    const ready=result.frames[0];
    result.frames=Array.from({length:totalFrames(move)+1},(_,i)=>({...structuredClone(ready),selectedFrame:i,stage:'Geometry only'}));
    result.contacts=[];result.executed=false;result.geometryOnly=true;result.totalDamage=0;result.displacement=0;
    return result;
  }
}
