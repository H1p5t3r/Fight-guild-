import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Engine,FIELDS} from '../web/engine.mjs';
import {poseAt} from '../web/workbench/model.mjs';

const spec=JSON.parse(readFileSync('art/characters/fillet-v1/FILLET_SPEC.json'));
const art=JSON.parse(readFileSync('godot/assets/fighters/manifest.json')).fighters[5];
const actions=spec.actions.filter(a=>art.attack_animations[String(a.slot)]);
const wasm=await WebAssembly.compile(readFileSync('web/generated/fight.wasm'));
const engine=async()=>new Engine(await WebAssembly.instantiate(wasm));
const place=(e,facing,gap=40000)=>{e.reset([5,4]);e.api.fg_preview_place(0,50000,0,0);e.api.fg_preview_place(1,50000+facing*gap,0,0);e.step(0,0);};

test('All 92 Fillet ground-normal keys appear on their exact authored ticks in both facings',async()=>{
 const e=await engine();
 assert.equal(actions.length,11);assert.equal(art.attack_animation.frames.length,92);
 for(const a of actions)for(const facing of [-1,1]){
  place(e,facing);assert.equal(e.api.fg_preview_begin(0,a.slot),1);
  const seen=new Set();
  for(let step=0;step<500&&(e.state().players[0].move===a.slot||e.state().players[0].displayMove===a.slot);step++){
   const f=e.state().players[0],tick=Math.max(1,f.age);
   const expected=a.animation.keys.findLast(k=>k.frame<=tick);
   const actual=art.attack_animation.frames[f.poseIndex];
   assert.equal(f.posePhase,14,a.id+'/'+tick);assert.equal(actual.action_id,a.id);
   assert.equal(actual.action_frame,expected.frame,a.id+'/'+tick+'/'+facing);
   assert.equal(f.facing,facing);seen.add(actual.action_frame);e.step(0,0);
  }
  assert.deepEqual([...seen],a.animation.keys.map(k=>k.frame),a.id);
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
