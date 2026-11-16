import {Engine,INPUT,BUTTONS,MOVE_IDS} from '../engine.mjs';
import {createCombatCore} from '../generated/fight-core.mjs';
import {inputName} from './model.mjs';

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
  record(data,character,slot,options={}){
    const m=data.characters[character].moves[slot],target=Number(options.target??(character===5?4:5));
    const entry=options.entry||'standing',behavior=options.behavior||'hit',simple=!!options.simple;
    const gap=Math.max(0,Math.min(450,Number(options.gap??24)));
    const facing=options.facing===-1?-1:1,e=this.engine;
    e.loadData(data);e.reset([character,target],[simple,false]);
    const separation=this.pack.collisions[character].push.halfWidth+this.pack.collisions[target].push.halfWidth+Math.round(gap*100);
    e.api.fg_preview_place(0,45000,0,10000);
    e.api.fg_preview_place(1,45000+facing*separation,behavior==='air'?12000:0,10000);
    const result={frames:[],contacts:[],warnings:[],executed:false,requested:inputName(m),slot,character,target};
    let elapsed=0,quiet=0,lastGroups=0;
    const capture=(input,stage)=>{
      const state=e.state(),players=state.players;
      const contact=players[0].hitGroups!==lastGroups;
      const frame={state,input,stage,selectedFrame:players[0].move===slot?players[0].age:0,
        boxes:[0,1].map(p=>({hurt:e.boxes(p,0),push:e.boxes(p,1),hit:e.boxes(p,2)})),contact:null};
      if(contact){frame.contact={tick:elapsed,event:players[0].event,damage:players[0].lastDamage,combo:players[0].combo,
        x:players[1].x,y:players[1].y+7500};result.contacts.push(frame.contact);}
      lastGroups=players[0].hitGroups;
      if(players[0].move===slot||players[0].lastMove===slot)result.executed=true;
      result.frames.push(frame);return state;
    };
    const defenderInput=()=>{
      const p=e.state().players[1],back=directionBits(4,p.facing);
      return behavior==='block'?back:behavior==='crouch'?back|INPUT.down:behavior==='fd'?back|INPUT.faultless:0;
    };
    const step=(input,stage)=>{e.step(input,defenderInput());elapsed++;return capture(input,stage);};
    capture(0,'Ready');
    if(!m.enabled){result.warnings.push('Attack disabled. Enable it to test execution.');return result;}
    const forward=directionBits(6,facing);
    if(entry==='walk'||entry==='run')for(let i=0;i<12;++i)step(forward|(entry==='run'&&i===0?INPUT.dash:0),entry==='run'?'Run / step approach':'Walk approach');
    if(m.air||entry==='jump'||entry==='forwardJump'){
      step(INPUT.up|(entry==='forwardJump'?forward:0),'Jump input');
      for(let i=0;i<11;++i)step(entry==='forwardJump'?forward:0,'Jump approach');
    }
    const contextual=m.followFrom>=0||m.followFrom2>=0;
    if(contextual){
      // A selected rekka ending can be studied on its own without changing any
      // routes. This explicit isolated mode is identified in the visible result.
      e.api.fg_preview_begin(0,slot);
      result.warnings.push('Isolated follow-up: starts directly after the approach. Source-route timing is not tested in this preview.');
    }else if(m.category===4){
      step(directionBits(slot===23?4:6,facing)|INPUT.P|INPUT.K,'Throw input');
    }else if(simple){
      if(!m.simpleDirection){result.warnings.push('This attack has no simple-input mapping.');return result;}
      step(directionBits(m.simpleDirection,facing)|INPUT.simple|(INPUT.P<<m.simpleButton),'Simple input');
    }else{
      const sequence=m.motion?String(m.motion).split('').map(Number):[m.direction];
      sequence.forEach((direction,index)=>step(directionBits(direction,facing)|(index===sequence.length-1?INPUT.P<<m.button:0),'Move input'));
    }
    let state=e.state();
    for(let i=0;i<2400;++i){
      state=step(0,result.executed?'Attack & reaction':'Waiting for input');
      if(state.winner!==-1)break;
      const free=state.players.every(p=>p.move<0&&p.stun===0&&p.reaction===0&&p.landingTime===0&&p.y===0)&&state.hitstop===0;
      quiet=free?quiet+1:0;if(quiet>=24)break;
    }
    if(!result.executed){
      const actual=state.players[0].lastMove;
      result.warnings.push(actual>=0?`Input selected ${MOVE_IDS[actual]}, not ${m.id}. Check mappings, airborne state and competing moves.`:'The selected input did not start this attack. Check its mapping and grounded/airborne requirement.');
    }
    if(result.frames.length>=2400)result.warnings.push('Preview stopped at the recording limit.');
    result.totalDamage=1000-state.players[1].health;
    result.displacement=(state.players[0].x-result.frames[0].state.players[0].x)/100;
    return result;
  }
}
