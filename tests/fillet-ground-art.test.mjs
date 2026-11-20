import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Engine,FIELDS,INPUT} from '../web/engine.mjs';
import {poseAt} from '../web/workbench/model.mjs';

const spec=JSON.parse(readFileSync('art/characters/fillet-v1/FILLET_SPEC.json'));
const art=JSON.parse(readFileSync('godot/assets/fighters/manifest.json')).fighters[5];
const actions=spec.actions.filter(a=>art.attack_animations[String(a.slot)]);
const plans=JSON.parse(readFileSync('art/characters/fillet-v1/production/kit-timing/exposure-plans.json')).actions;
const audited=JSON.parse(readFileSync('art/characters/fillet-v1/production/guide-audit-v1/exposure-plans.json'));
const expectedTicks=a=>(audited[a.id]??plans[a.id].keys).map(k=>k.frame);
const wasm=await WebAssembly.compile(readFileSync('web/generated/fight.wasm'));
const engine=async()=>new Engine(await WebAssembly.instantiate(wasm));
const place=(e,facing,gap=40000)=>{e.reset([5,4]);e.api.fg_preview_place(0,50000,0,0);e.api.fg_preview_place(1,50000+facing*gap,0,0);e.step(0,0);};

const beginWhiff=(e,a,facing=1)=>{
 place(e,facing);
 if(a.id.startsWith('j.')){e.step(INPUT.up,0);while(e.state().players[0].y===0)e.step(0,0);}
 if(a.id==='236D'||a.id==='214D')e.api.fg_preview_status(1,1,20);
 assert.equal(e.api.fg_preview_begin(0,a.slot),1);
};

test('All 26 attacks use authored phase clocks in both facings; landing interrupts air recovery',async()=>{
 const e=await engine();assert.equal(actions.length,26);assert.equal(art.attack_animation.frames.length,271);
 for(const a of actions)for(const facing of [-1,1]){
  beginWhiff(e,a,facing);const seen=new Set();let landed=false;
  for(let step=0;step<160;step++){
   e.step(0,0);const f=e.state().players[0];
   if(f.move!==a.slot&&f.displayMove!==a.slot){landed=a.id.startsWith('j.')&&f.y===0;break;}
   const tick=Math.max(1,f.move>=0?f.age:f.displayAge),expected=expectedTicks(a).findLast(t=>t<=tick),actual=art.attack_animation.frames[f.poseIndex];
   assert.equal(f.posePhase,14,a.id+'/'+tick);assert.equal(actual.action_id,a.id);assert.equal(actual.action_frame,expected,a.id+'/'+tick+'/'+facing);
   seen.add(actual.action_frame);
  }
  if(!landed)assert.deepEqual([...seen],expectedTicks(a),a.id);
  else assert.ok([...seen].includes(a.schema22Scalars.startup),a.id+' reaches active before landing');
  // Geometry inspection must still expose every recovery key even when a
  // particular real jump lands earlier and correctly interrupts the move.
  const m=e.data().characters[5].moves[a.slot],clip=art.attack_animations[a.slot];
  for(const tick of expectedTicks(a))assert.equal(art.attack_animation.frames[poseAt(m,tick,true,clip).index].action_frame,tick);
 }
});

test('Every move holds its load to the final startup tick and changes drawing on first active',async()=>{
 const e=await engine(),identity=k=>k.file+JSON.stringify(k.region);
 for(const a of actions){
  const m=e.data().characters[5].moves[a.slot],clip=art.attack_animations[a.slot],s=m.startup;
  const body=t=>art.attack_animation.frames[poseAt(m,t,true,clip).index];
  const load=plans[a.id].keys.filter(k=>k.frame<s).at(-1).frame;
  for(let t=load;t<s;t++)assert.equal(identity(body(t)),identity(body(s-1)),a.id+' anticipated extension must stay held');
  assert.notEqual(identity(body(s-1)),identity(body(s)),a.id+' first active needs its attacking pose');
  assert.equal(body(s).action_frame,s);assert.equal(body(s-1).effect,undefined);
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

test('Sweep uses stable held poses, a one-frame release, and its real nine-frame contact freeze',async()=>{
 const frames=art.attack_animation.frames.filter(k=>k.action_id==='2S');
 assert.equal(new Set(frames.map(k=>k.file+JSON.stringify(k.region))).size,6);
 assert.ok(frames.every(k=>k.file==='fillet-ground-v1/2s.png'&&k.body_height===600));
 for(const k of frames)assert.ok(Math.abs((k.rear_foot_source_x-k.pivot[0])*150/k.body_height+35)<=.125);
 const entry=frames[0],settle=frames.at(-1);
 assert.deepEqual([entry.region,entry.pivot],[settle.region,settle.pivot]);
 const e=await engine();place(e,1);e.api.fg_preview_begin(0,6);
 const sources=[];
 for(let tick=1;tick<=38;tick++){e.step(0,0);sources.push(art.attack_animation.frames[e.state().players[0].poseIndex].source_action_frame);}
 assert.deepEqual(sources.slice(5,12),[6,6,6,6,6,6,12]);
 assert.deepEqual(sources.slice(11,14),[12,12,12]);
 place(e,1,10000);e.api.fg_preview_begin(0,6);
 for(let i=0;i<12;i++)e.step(0,0);
 assert.equal(e.state().hitstop,9);assert.equal(e.state().players[0].age,12);
 const pose=e.state().players[0].poseIndex,saved=e.snapshot();
 for(let i=0;i<9;i++){e.step(0,0);assert.equal(e.state().players[0].age,12);assert.equal(e.state().players[0].poseIndex,pose);}
 e.step(0,0);assert.equal(e.state().players[0].age,13);
 const hash=e.hash;e.restore(saved);for(let i=0;i<10;i++)e.step(0,0);assert.equal(e.hash,hash);
});

test('Edited timings and disabled-move geometry preview use the same phase keys as the simulation',async()=>{
 const e=await engine(),defaults=e.data();
 for(const a of actions){
  e.loadData(defaults);
  for(const [field,extra] of [['startup',7],['active',6],['recovery',9]])assert.equal(e.api.fg_move_set(5,a.slot,FIELDS.indexOf(field),defaults.characters[5].moves[a.slot][field]+extra),1);
  const m=e.data().characters[5].moves[a.slot],clip=art.attack_animations[String(a.slot)];
  beginWhiff(e,a);
  for(let step=0;step<500&&(e.state().players[0].move===a.slot||e.state().players[0].displayMove===a.slot);step++){
   const f=e.state().players[0];if(f.posePhase!==14)break;const draw=poseAt({...m,enabled:0},Math.max(1,f.move>=0?f.age:f.displayAge),true,clip);
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

test('Generated blade arcs follow active geometry and disappear after the short recovery trail',async()=>{
 const e=await engine(),effects=JSON.parse(readFileSync('art/characters/fillet-v1/production/kit-timing/effects-generation.json'));
 for(const id of Object.keys(effects.actions)){
  const a=actions.find(a=>a.id===id),m=e.data().characters[5].moves[a.slot],clip=art.attack_animations[a.slot];
  for(let t=1;t<m.startup+m.active+m.recovery;t++){
   const tile=art.attack_animation.frames[poseAt(m,t,true,clip).index];
   if(id==='c.S'){
    if(t===m.startup){assert.equal(tile.effect.pose,6);assert.deepEqual(tile.effect.box,[60,64,72,130]);}
    else assert.equal(tile.effect,undefined,'c.S low trail exists only during its actual swept contact');
    continue;
   }
   if(t<m.startup||t>=m.startup+m.active+4){assert.equal(tile.effect,undefined,id+'/'+t);continue;}
   assert.equal(tile.effect.sheet,'knife_fx');
   if(t<m.startup+m.active){
    const boxes=a.hitboxTimeline.keys.findLast(k=>k.frame<=t-m.startup+1).boxes;
    const union=[Math.min(...boxes.map(b=>b[0])),Math.min(...boxes.map(b=>b[1])),Math.max(...boxes.map(b=>b[2])),Math.max(...boxes.map(b=>b[3]))].map(v=>v/100);
    assert.deepEqual(tile.effect.box,union,id+'/'+t);assert.equal(tile.effect.opacity,1);
   }else assert.ok(tile.effect.opacity<.5);
  }
 }
});

test('Legacy Fillet imports opt out of the v1 ground-normal clips',async()=>{
 const e=await engine();e.loadData(JSON.parse(readFileSync('godot/data/workshop/2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json')));
 place(e,1);e.api.fg_preview_begin(0,0);
 while(e.state().players[0].move===0){assert.notEqual(e.state().players[0].posePhase,14);e.step(0,0);}
});


test('Successful throws and Drive captures use their saved pair clock, including freeze and replay',async()=>{
 const e=await engine();
 for(const [id,slot] of [['4P+K',23],['6P+K',24],['5D',13],['236D',45],['214D',46]]){
  place(e,1,id==='5D'?5000:slot>=45?17000:3500);
  if(id==='5D')e.api.fg_preview_status(1,0,180);
  if(slot>=45)e.api.fg_preview_status(1,1,20);
  e.api.fg_preview_begin(0,slot);
  for(let i=0;i<100&&!e.state().pairKind;i++)e.step(0,0);
  assert.ok(e.state().pairKind,id+' must capture');
  assert.equal(e.state().players[0].move,-1,'Capture has its own clock, not an attack age');
  const snapshot=e.snapshot(),replay=[],seen=new Set();
  for(let i=0;i<100;i++){
   const state=e.state(),f=state.players[0];
   if(!state.pairKind)break;
   const clip=art.paired_animations[slot],key=clip.keys.findLast(k=>k.tick<=state.pairClock);
   assert.equal(f.posePhase,14);assert.equal(f.poseIndex,key.pose,id+' C'+state.pairClock);seen.add(state.pairClock);
   replay.push([e.hash,f.poseIndex,state.pairClock]);e.step(0,0);
  }
  assert.ok(seen.has(0)&&seen.size>=20,id+' captures animate through their contract');
  const hash=e.hash;e.restore(snapshot);
  for(const frame of replay){assert.deepEqual([e.hash,e.state().players[0].poseIndex,e.state().pairClock],frame);e.step(0,0);}
  assert.equal(e.hash,hash);
 }
});

test('Command grabs keep their first-active latch through capture and use distinct entry choreography',async()=>{
 const e=await engine(),entries=[];
 const identity=f=>[f.file,f.region,f.pivot,f.body_height];
 for(const [id,slot] of [['236D',45],['214D',46]])for(const facing of [-1,1]){
  const move=e.data().characters[5].moves[slot],clip=art.attack_animations[slot],pair=art.paired_animations[slot];
  assert.deepEqual([move.startup,move.active,move.recovery],[22,2,30]);
  const latch=art.attack_animation.frames[poseAt(move,22,true,clip).index];
  const capture=art.attack_animation.frames[pair.keys[0].pose];
  assert.deepEqual(identity(capture),identity(latch),'No body/knife jump on '+id+' capture');
  assert.match(capture.file,/-v2\.png$/);
  assert.deepEqual(pair.keys.map(k=>k.tick),[0,1,5,9,13,17,21,23,25]);
  place(e,facing,17000);e.api.fg_preview_status(1,1,20);e.api.fg_preview_begin(0,slot);
  for(let i=0;i<60&&!e.state().pairKind;i++)e.step(0,0);
  assert.ok(e.state().pairKind);assert.equal(e.state().pairClock,0);assert.equal(e.state().hitstop,6);
  const start=e.state(),frozenPose=start.players[0].poseIndex;
  for(let i=0;i<6;i++){e.step(0,0);assert.equal(e.state().players[0].poseIndex,frozenPose);assert.equal(e.state().pairClock,0);}
  for(let clock=1;clock<28;clock++){
   e.step(0,0);const state=e.state(),tile=art.attack_animation.frames[state.players[0].poseIndex];
   assert.equal(state.pairClock,clock);assert.equal(state.players[1].health,1000,'Knife accents are not extra damage events');
   assert.equal(state.players[0].y,0);assert.equal(state.players[1].y,0);
   if(clock===13)assert.equal(tile.source_pose,7,'Long-right cut uses its authored event');
   if(clock===17)assert.equal(tile.source_pose,8,'Short-left accent keeps contact');
   if(clock===21)assert.equal(tile.source_pose,9,'Release art starts when the forearm unlocks');
  }
  e.step(0,0);const released=e.state();
  assert.equal(released.pairKind,0);assert.equal(released.hitstop,8);assert.equal(released.players[1].health,925);
  assert.equal(Math.abs(released.players[0].x-released.players[1].x),17000);
  if(facing===1)entries.push(identity(capture));
 }
 assert.notDeepEqual(entries[0],entries[1],'Hop landing and trailing-foot latch have independent drawings');
});
