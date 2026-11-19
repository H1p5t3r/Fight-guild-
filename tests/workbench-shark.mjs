import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Workshop,blockAdvantage} from '../web/workbench/model.mjs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
import {Engine} from '../web/engine.mjs';
const json=async p=>JSON.parse(await readFile(p,'utf8'));
const pack=await json('build/workbench-pack.json');
const sharkBatch=await json('godot/data/workshop/2026-11-18-shark/FightGuild-Shark-Normals.json');
const slots=[0,1,32,2,3,4,5,6,7,17,18,19,20,8,9,11];

test('Shark selected movement uses both gait halves, dedicated retreat/dash, and weighted idle without editing a draft',()=>{
 const data=structuredClone(pack.draft.data),before=structuredClone(data),preview=new CombatPreview(pack),art=pack.art[4];
 assert.deepEqual(art.idle.frame_ticks,[72,12,6,18]);
 for(const phase of ['walk','back_walk','run']){
  const frames=art[phase].frames;
  assert.equal(frames.length,8);
  assert.equal(new Set(frames.map(f=>`${f.file}:${f.region.join(',')}`)).size,8);
  assert.equal(frames[0].support_leg,'right');assert.equal(frames[4].support_leg,'left');
  assert.ok(frames.slice(0,4).every(f=>f.gait_half==='right'));
  assert.ok(frames.slice(4).every(f=>f.gait_half==='left'));
 }
 for(const facing of [-1,1])for(const [action,phase,count] of [['idle',11,4],['walk',6,8],['backWalk',13,8],['back',15,6],['forward',7,8]]){
  const record=preview.recordMovement(data,4,0,action,{facing});
  const moving=record.frames.filter(f=>f.state.players[0].posePhase===phase);
  assert.equal(new Set(moving.map(f=>f.state.players[0].poseIndex)).size,count,action+'/'+facing);
  assert.ok(moving.every(f=>f.state.players[0].y===0&&f.state.players[0].facing===facing&&f.boxes[0].hurt.length===4));
  if(action==='backWalk'){
   const keys=moving.map(f=>f.state.players[0].poseIndex).filter((v,i,a)=>!i||v!==a[i-1]);
   keys.slice(1).forEach((v,i)=>assert.equal(v,(keys[i]+1)%8));
  }
  if(action==='idle')for(const f of moving){
   const tick=f.state.players[0].idleTime%108;
   assert.equal(f.state.players[0].poseIndex,tick<72?0:tick<84?1:tick<90?2:3);
  }
 }
 assert.deepEqual(data,before);
});

test('Shark movement clocks, anatomical poses and rollback agree in WASM and plain JS',async()=>{
 const wasm=new Engine((await WebAssembly.instantiate(await readFile('web/generated/fight.wasm'))).instance),plain=new CombatPreview(pack).engine;
 for(const facing of [-1,1]){
  for(const e of [wasm,plain]){e.loadData(pack.draft.data);e.reset([4,5]);e.api.fg_preview_place(0,50000,0,0);e.api.fg_preview_place(1,50000+facing*40000,0,0);}
  const forward=facing===1?2:1,back=facing===1?1:2;
  let snapshot;
  const inputs=Array.from({length:180},(_,i)=>i<110?0:i<125?forward:i===125?back|512:i<140?0:i===140?forward|512:i<170?forward:0);
  for(let i=0;i<inputs.length;++i){
   wasm.step(inputs[i],0);plain.step(inputs[i],0);
   assert.equal(wasm.hash,plain.hash);assert.deepEqual(wasm.state(),plain.state());
   if(i===128)snapshot=plain.snapshot();
  }
  const hash=plain.hash;plain.restore(snapshot);
  inputs.slice(129).forEach(input=>plain.step(input,0));assert.equal(plain.hash,hash);
 }
});

test('Shark batch changes only the16 selected normals and appends briefs without losing uploaded data',async()=>{
 const before=await json('godot/data/workshop/2026-11-18-user-smoke/FightGuild-Smoke-Animations.json');
 const data=sharkBatch;
 for(let c=0;c<6;++c){
  if(c!==4){assert.deepEqual(data.characters[c],before.characters[c]);continue;}
  assert.deepEqual(data.characters[c].movement,before.characters[c].movement);
  for(let m=0;m<45;++m)if(!slots.includes(m))assert.deepEqual(data.characters[c].moves[m],before.characters[c].moves[m],String(m));
 }
 for(const [k,v] of Object.entries(before).filter(([k])=>!['characters','_moveWorkshop'].includes(k)))assert.deepEqual(data[k],v);
 for(const [name,note] of Object.entries(before._moveWorkshop.notes)){
  const now=data._moveWorkshop.notes[name];
  for(const [key,value] of Object.entries(note)){
   if(name.startsWith('Shark/')&&key==='intent'&&now[key]!==value)assert.ok(now[key].startsWith(value));
   else assert.deepEqual(now[key],value,name+'/'+key);
  }
 }
 const w=new Workshop(pack,data);assert.deepEqual(new Workshop(pack,JSON.parse(w.export())).data,w.data);
});

test('Ky timing and scaled traces survive editor import/export; multi-hit is2Hs only',async()=>{
 const w=new Workshop(pack,sharkBatch),source=await json('references/frame-data/ky-kiske-2026-11-18/source.json');
 const traces=await json('references/frame-data/ky-kiske-2026-11-18/traces.json');
 source.moves.forEach((r,i)=>{
  const m=w.move(4,slots[i]);assert.equal(m.startup,Number(r.Startup));assert.equal(m.recovery,Number(r.Recovery));
  assert.equal(m.active,r.Input==='2H'?5:Number(r.Active));assert.equal(m.artPose,i+5);
  assert.equal(m.hitLevel,{All:0,Low:1,High:2}[r.Guard]);assert.equal(m.specialCancel,1);
  assert.deepEqual(m.hitboxTimeline.keys.map(k=>k.boxes),traces.moves[r.Input].map(t=>t.boxes));
  assert.equal(m.hitboxTimeline.multiHit,r.Input==='2H');
  assert.equal(m.counterFreezeFrames,r['Counter Type'].startsWith('Large')?31:r['Counter Type']==='Mid'?21:-1);
  assert.equal(m.counterSlowFrames,r['Counter Type'].startsWith('Large')?35:r['Counter Type']==='Mid'?25:0);
  if(!r.Input.startsWith('j.'))assert.equal(blockAdvantage(m),Number(r['On-Block']));
 });
 assert.deepEqual(w.move(4,7).hitboxTimeline.keys.map(k=>[k.frame,k.hit,k.damage]),[[1,1,14],[2,2,40]]);
 assert.equal(w.move(4,8).hurtMaskWindup,3);assert.equal(w.move(4,8).hurtWindowStart,4);
 assert.equal(w.move(4,8).hurtWindowEnd,13);assert.equal(w.move(4,8).hurtWindowMask,1);
 const art=pack.art[4];assert.equal(art.signature_active.frames.length,20);assert.equal(art.attack_animation.frames.length,26);
});

test('Low Scoop follows8 saved-clock keys, hits twice and supports the one-hit toggle in both facings',()=>{
 const p=new CombatPreview(pack),data=pack.draft.data;
 for(const facing of [1,-1]){
  const clip=p.record(data,4,7,{gap:70,facing});
  assert.ok(clip.executed);assert.equal(clip.contacts.length,2);
  const keys=[...new Set(clip.frames.filter(f=>f.state.players[0].posePhase===14).map(f=>f.state.players[0].poseIndex))].sort((a,b)=>a-b);
  assert.deepEqual(keys,[0,1,2,3,4,5,6,7]);
  assert.deepEqual(p.record(data,4,7,{gap:70,facing}),clip,'Deterministic saved frames');
  const once=structuredClone(data);once.characters[4].moves[7].hitboxTimeline.multiHit=false;
  assert.equal(p.record(once,4,7,{gap:70,facing}).contacts.length,1);
  const air=p.record(data,4,20,{gap:70,facing});
  assert.ok(air.frames.some(f=>f.state.players[0].posePhase===14&&f.state.players[0].poseIndex===24));
 }
});
