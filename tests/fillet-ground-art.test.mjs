import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Engine,FIELDS} from '../web/engine.mjs';
import {poseAt} from '../web/workbench/model.mjs';

const spec=JSON.parse(readFileSync('art/characters/fillet-v1/FILLET_SPEC.json'));
const art=JSON.parse(readFileSync('godot/assets/fighters/manifest.json')).fighters[5];
const actions=spec.actions.filter(a=>art.attack_animations[String(a.slot)]);
const refined=new Set(['5P','5K','2S']);
const expectedTicks=a=>{
 const ticks=new Set(a.animation.keys.map(k=>k.frame));
 if(refined.has(a.id)){
  const {startup:s,active:h,recovery:r}=a.schema22Scalars;
  for(const [from,to] of [[1,s],[s,s+h],[s+h,s+h+r]])for(let t=from;t<to;t+=2)ticks.add(t);
 }
 return [...ticks].sort((a,b)=>a-b);
};
const wasm=await WebAssembly.compile(readFileSync('web/generated/fight.wasm'));
const engine=async()=>new Engine(await WebAssembly.instantiate(wasm));
const place=(e,facing,gap=40000)=>{e.reset([5,4]);e.api.fg_preview_place(0,50000,0,0);e.api.fg_preview_place(1,50000+facing*gap,0,0);e.step(0,0);};

test('All 116 Fillet ground-normal keys appear on their exact authored ticks in both facings',async()=>{
 const e=await engine();
 assert.equal(actions.length,11);assert.equal(art.attack_animation.frames.length,116);
 for(const a of actions)for(const facing of [-1,1]){
  place(e,facing);assert.equal(e.api.fg_preview_begin(0,a.slot),1);
  const seen=new Set();
  for(let step=0;step<500&&(e.state().players[0].move===a.slot||e.state().players[0].displayMove===a.slot);step++){
   const f=e.state().players[0],tick=Math.max(1,f.age);
   const expected=expectedTicks(a).findLast(t=>t<=tick);
   const actual=art.attack_animation.frames[f.poseIndex];
   assert.equal(f.posePhase,14,a.id+'/'+tick);assert.equal(actual.action_id,a.id);
   assert.equal(actual.action_frame,expected,a.id+'/'+tick+'/'+facing);
   assert.equal(f.facing,facing);seen.add(actual.action_frame);e.step(0,0);
  }
  assert.deepEqual([...seen],expectedTicks(a),a.id);
 }
});

test('5P, 5K and 2S change drawing on every phase entry and never hold longer than two action frames',async()=>{
 const e=await engine();
 for(const a of actions.filter(a=>refined.has(a.id))){
  place(e,1);e.api.fg_preview_begin(0,a.slot);
  e.step(0,0);
  const {startup:s,active:h,recovery:r}=a.schema22Scalars,entries=new Set([1,s,s+h]);
  let previous=-1,held=0;
  for(let tick=1;tick<s+h+r;tick++){
   if(tick>1)e.step(0,0);
   const f=e.state().players[0];
   if(entries.has(tick))assert.notEqual(f.poseIndex,previous,a.id+' phase entry '+tick);
   held=f.poseIndex===previous?held+1:1;
   assert.ok(held<=2,a.id+' holds too long at '+tick);previous=f.poseIndex;
  }
 }
});

test('2S generated cutting arc reaches the live hitbox in both facings and fades only after contact ends',async()=>{
 const e=await engine();
 for(const facing of [-1,1]){
  place(e,facing);e.api.fg_preview_begin(0,6);
  for(let tick=1;tick<=38;tick++){
   e.step(0,0);const f=e.state().players[0],tile=art.attack_animation.frames[f.poseIndex],effect=tile.effect,hits=e.boxes(0,2);
   if(tick>=12&&tick<=15){
    assert.equal(effect.sheet,'sweep_fx');assert.equal(effect.opacity,1);assert.equal(hits.length,1);
    const [l,b,r,t]=effect.box;
    assert.deepEqual(hits[0],[f.x+(facing===1?l:-r)*100,f.y+b*100,f.x+(facing===1?r:-l)*100,f.y+t*100]);
    assert.equal(r,tick===15?108:116);
   }else{
    assert.equal(hits.length,0);
    if(tick>=16&&tick<20)assert.ok(effect.opacity<1,'Recovery retains only a fading trail');
    else assert.equal(effect,undefined,'No arc before contact or after its recovery trail');
   }
  }
 }
});

test('Edited timings and disabled-move geometry preview use the same phase keys as the simulation',async()=>{
 const e=await engine(),defaults=e.data();
 for(const a of actions){
  e.loadData(defaults);
  for(const [field,extra] of [['startup',7],['active',6],['recovery',9]])assert.equal(e.api.fg_move_set(5,a.slot,FIELDS.indexOf(field),defaults.characters[5].moves[a.slot][field]+extra),1);
  const m=e.data().characters[5].moves[a.slot],clip=art.attack_animations[String(a.slot)];
  place(e,1);e.api.fg_preview_begin(0,a.slot);
  for(let step=0;step<500&&(e.state().players[0].move===a.slot||e.state().players[0].displayMove===a.slot);step++){
   const f=e.state().players[0],draw=poseAt({...m,enabled:0},Math.max(1,f.age),true,clip);
   assert.deepEqual(draw,{phase:'attack_animation',index:f.poseIndex},a.id+'/'+f.age);e.step(0,0);
  }
 }
});

test('Contact freeze holds the registered pose and snapshot replay restores the same sequence',async()=>{
 const e=await engine();place(e,1,6200);e.api.fg_preview_begin(0,3);
 for(let i=0;i<45&&!e.state().hitstop;i++)e.step(0,0);
 assert.ok(e.state().hitstop>0,'Crosscut actually connects');
 const saved=e.snapshot(),pose=e.state().players[0].poseIndex;
 while(e.state().hitstop>1){e.step(0,0);assert.equal(e.state().players[0].poseIndex,pose);}
 e.restore(saved);const frames=[];
 for(let i=0;i<65;i++){e.step(0,0);frames.push([e.hash,e.state().players[0].poseIndex]);}
 e.restore(saved);
 for(const expected of frames){e.step(0,0);assert.deepEqual([e.hash,e.state().players[0].poseIndex],expected);}
});

test('Legacy Fillet imports opt out of the v1 ground-normal clips',async()=>{
 const e=await engine();e.loadData(JSON.parse(readFileSync('godot/data/workshop/2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json')));
 place(e,1);e.api.fg_preview_begin(0,0);
 while(e.state().players[0].move===0){assert.notEqual(e.state().players[0].posePhase,14);e.step(0,0);}
});
