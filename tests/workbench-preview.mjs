import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Engine,INPUT} from '../web/engine.mjs';
import {createCombatCore} from '../web/generated/fight-core.mjs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
import {Workshop,attackBoxes} from '../web/workbench/model.mjs';
import {makeHitKey,validateHitTimeline} from '../web/hitboxes.mjs';
import {cursorAnchor,cursorIndex} from '../web/workbench/cursor.mjs';
const pack=JSON.parse(await readFile('build/workbench-pack.json','utf8'));
const wasm=await WebAssembly.compile(await readFile('web/generated/fight.wasm'));
const sample=()=>{
  const data=structuredClone(pack.defaults),m=data.characters[5].moves[0];
  Object.assign(m,{active:7,pushback:0,airPushback:0,blockPushback:0,hitstop:0,starterProration:100,comboScaling:0});
  const one={...makeHitKey(1),boxes:[[0,0,30000,20000],[0,0,30000,20000]],damage:20,hitstun:90,blockstun:90,hitstop:0};
  const two={...structuredClone(one),frame:3,hit:2,damage:30};
  m.hitboxTimeline={multiHit:true,keys:[one,two,{...structuredClone(one),frame:5}]};return data;
};
test('Plain JavaScript preview core matches WASM state and rollback with timed multi-hits',async()=>{
  const js=new Engine({exports:createCombatCore()}),wa=new Engine(await WebAssembly.instantiate(wasm)),data=sample();
  for(const engine of [js,wa]){engine.loadData(data);engine.reset();engine.api.fg_preview_place(0,40000,0,0);engine.api.fg_preview_place(1,50000,0,0);}
  assert.equal(js.fingerprint(),wa.fingerprint());let seed=47,snapshot,expected;
  for(let tick=0;tick<1200;tick++){
    seed=(Math.imul(seed,1664525)+1013904223)>>>0;
    const a=tick===0?INPUT.P:tick<100?0:seed&4095,b=tick<100?0:(seed>>>12)&4095;
    js.step(a,b);wa.step(a,b);assert.equal(js.hash,wa.hash,`tick ${tick}`);assert.deepEqual(js.state(),wa.state());
    if(tick===4)snapshot=js.snapshot();if(tick===99)expected=js.hash;
  }
  js.restore(snapshot);for(let i=5;i<100;i++)js.step(0,0);assert.equal(js.hash,expected);
});
test('Preview simulates contact, motion inputs, run carry, air hooks, blocks and FD',()=>{
  const preview=new CombatPreview(pack),before=JSON.stringify(pack.defaults);
  const hit=preview.record(pack.defaults,5,0);assert.equal(hit.totalDamage,28);assert.equal(hit.contacts.length,1);
  const block=preview.record(pack.defaults,5,0,{behavior:'block'});assert.equal(block.totalDamage,0);assert.equal(block.contacts[0].event,2);
  const fd=preview.record(pack.defaults,5,0,{behavior:'fd'});assert.ok(fd.frames.some(f=>f.state.players[1].faultless));
  const run=preview.record(pack.defaults,5,25,{entry:'run'}),stand=preview.record(pack.defaults,5,25);
  assert.ok(run.displacement>stand.displacement);assert.ok(run.frames.some(f=>f.input&INPUT.dash));
  const air=preview.record(pack.defaults,4,29);assert.ok(air.executed&&air.contacts.length);assert.ok(air.frames.some(f=>f.state.players[0].y>0));
  assert.ok(air.frames.some(f=>f.state.players[1].reaction===5),'Hook visibly reels target');
  const left=preview.record(pack.defaults,5,0,{facing:-1});assert.equal(left.totalDamage,hit.totalDamage);
  assert.equal(JSON.stringify(pack.defaults),before,'A preview never changes the draft');
});
test('Multiple boxes remain one hit unless multi-hit is enabled; hit groups are unique',()=>{
  const preview=new CombatPreview(pack),data=sample();
  const multi=preview.record(data,5,0);assert.equal(multi.contacts.length,2);assert.equal(multi.totalDamage,50);
  data.characters[5].moves[0].hitboxTimeline.multiHit=false;
  const single=preview.record(data,5,0);assert.equal(single.contacts.length,1);assert.equal(single.totalDamage,20);
  const gap=sample();gap.characters[5].moves[0].hitboxTimeline.keys[0].boxes=[];
  const trace=preview.record(gap,5,0);assert.equal(trace.contacts[0].tick,7);
});
test('Timelines migrate and round-trip with notes, undo, per-frame geometry and atomic validation',()=>{
  const legacy=structuredClone(pack.defaults);legacy.schema=legacy.coreVersion=13;
  for(const c of legacy.characters)for(const m of c.moves)delete m.hitboxTimeline;
  const w=new Workshop(pack,legacy);assert.equal(w.data.schema,15);w.setNote(5,0,'active','Keep the knife pose.');
  const track=sample().characters[5].moves[0].hitboxTimeline;w.setHitTimeline(5,0,track);
  const imported=new Workshop(pack,JSON.parse(w.export()));assert.deepEqual(imported.move(5,0).hitboxTimeline,track);assert.equal(imported.note(5,0).active,'Keep the knife pose.');
  assert.equal(attackBoxes(imported.move(5,0),5,pack.collisions[5].push).length,2);
  const before=w.snapshot();for(const mutate of [t=>t.keys[1].frame=1,t=>t.keys[0].hit=33,t=>t.keys[0].boxes[0][2]=0,t=>t.keys[0].damage=1001,t=>t.multiHit=1]){
    const bad=structuredClone(track);mutate(bad);assert.throws(()=>validateHitTimeline(bad));assert.throws(()=>w.setHitTimeline(5,0,bad));assert.deepEqual(w.snapshot(),before);
  }
  w.resetMove(5,0);assert.equal(w.move(5,0).hitboxTimeline.keys.length,0);assert.equal(w.note(5,0).active,'Keep the knife pose.');w.undo();assert.deepEqual(w.move(5,0).hitboxTimeline,track);
});
test('Disabling a command normal prevents its execution and cancel destination without deleting it',()=>{
  const data=structuredClone(pack.defaults),m=data.characters[5].moves[8];m.enabled=0;
  const e=new Engine({exports:createCombatCore()});e.loadData(data);e.reset();e.step(INPUT.right|INPUT.P,0);
  assert.equal(e.state().players[0].move,0);assert.equal(e.api.fg_can_cancel(5,0,8,1),0);
  const preview=new CombatPreview(pack).record(data,5,8);assert.equal(preview.geometryOnly,true);assert.equal(preview.executed,false);assert.equal(preview.contacts.length,0);assert.ok(preview.frames.some(f=>f.selectedFrame===m.startup));assert.match(preview.warnings[0],/disabled/);
  m.enabled=1;e.loadData(data);e.reset();e.step(INPUT.right|INPUT.P,0);assert.equal(e.state().players[0].move,8);
});

test('Shared cursor preserves the move frame when contact or approach changes elapsed time',()=>{
  const preview=new CombatPreview(pack),hit=preview.record(pack.defaults,5,0),miss=preview.record(pack.defaults,5,0,{gap:400});
  const index=hit.frames.findIndex(f=>f.selectedFrame===6),anchor=cursorAnchor(hit,index);
  assert.equal(miss.frames[cursorIndex(miss,anchor)].selectedFrame,6);
  assert.notEqual(index,cursorIndex(miss,anchor),'Hitstop changes elapsed tick, not selected move frame');
  const running=preview.record(pack.defaults,5,0,{entry:'run'});
  assert.equal(running.frames[cursorIndex(running,anchor)].selectedFrame,6);
  const freeze=hit.frames.findIndex(f=>f.selectedFrame===5)+2;
  assert.equal(cursorIndex(hit,cursorAnchor(hit,freeze)),freeze,'Keep position within an impact freeze');
  assert.equal(cursorIndex(miss,{tick:99999}),miss.frames.length-1);
});
