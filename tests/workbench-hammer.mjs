import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Engine,INPUT} from '../web/engine.mjs';
import {Workshop} from '../web/workbench/model.mjs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
import {STEP_DRIVE_DEFAULTS} from '../web/step-drive.mjs';
const json=async path=>JSON.parse(await readFile(path,'utf8'));
const pack=await json('build/workbench-pack.json'),data=pack.draft.data;
test('Hammer kit preserves other fighters, old imports, and authored art briefs',async()=>{
 const old=await json('godot/data/workshop/2026-11-20-combo-decay/FightGuild-Combo-Decay.json');
 for(const [c,ch]of old.characters.entries())if(c!==1)assert.deepEqual(data.characters[c],{...ch,moves:ch.moves.map(m=>({...m,...STEP_DRIVE_DEFAULTS}))});
 const before=structuredClone(old),w=new Workshop(pack,old);
 assert.deepEqual(old,before);assert.equal(w.data.schema,27);
 assert.deepEqual(w.data._moveWorkshop,old._moveWorkshop);
 assert.deepEqual(w.data.characters[1],{...old.characters[1],moves:old.characters[1].moves.map(m=>({...m,...STEP_DRIVE_DEFAULTS}))});
 assert.equal(data.characters[1].moves.filter(m=>m.enabled).length,23);
 assert.equal(data.characters[1].moves[13].mechanic,5);
 const tuned=new Workshop(pack,data);tuned.change(1,13,'driveDistance',23000);tuned.change(1,13,'drivePlus',7);
 const p=new CombatPreview(pack);p.engine.loadData(tuned.data);assert.equal(p.engine.data().characters[1].moves[13].drivePlus,7);
 assert.deepEqual(new Workshop(pack,JSON.parse(tuned.export())).data,tuned.data);
});
test('Drive previews execute real contextual normals, carry velocity, and have no attack box',()=>{
 const p=new CombatPreview(pack);
 for(const facing of [-1,1]){
  const single=p.record(data,1,13,{facing,gap:230});
  assert.equal(single.contacts.length,0);assert.equal(single.totalDamage,0);
  assert.ok(single.frames.every(f=>!f.boxes[0].hit.length));
  const follow=p.record(data,1,13,{facing,gap:230,mechanic:'followup',behavior:'block'});
  const enhanced=follow.frames.find(f=>f.state.players[0].driveBonus===4);
  assert.ok(enhanced);assert.ok([2,32].includes(enhanced.state.players[0].move));
  assert.ok(enhanced.state.players[0].vx*facing>0);
  assert.ok(follow.frames.some(f=>f.state.players[0].event===2),'enhanced normal should be blocked');
 }
});
test('All Hammer moves use held load / first-active snap in both facings',()=>{
 const p=new CombatPreview(pack),e=p.engine;
 for(const facing of [-1,1])for(const [slot,m]of data.characters[1].moves.entries()){
  if(!m.enabled)continue;e.loadData(data);e.reset([1,5]);
  e.api.fg_preview_place(0,facing===1?20000:80000,m.air?25000:0,10000);
  e.api.fg_preview_place(1,facing===1?80000:20000,0,10000);
  assert.ok(e.api.fg_preview_begin(0,slot));let last,first;
  for(let tick=1;tick<=m.startup;++tick){e.step(0,0);const f=e.state().players[0];if(tick===m.startup-1)last=f;if(tick===m.startup)first=f;}
  assert.equal(last.posePhase,14,m.id);assert.equal(first.posePhase,14,m.id);assert.notEqual(last.poseIndex,first.poseIndex,m.id);
  const sheet=pack.art[1].attack_animation,frame=sheet.frames[first.poseIndex];
  if(frame.effect)assert.ok(pack.art[1][frame.effect.sheet],m.id+' effect must ship with the browser package');
 }
});
test('JS and WASM preserve Drive resource and boost through snapshot replay',async()=>{
 const js=new CombatPreview(pack).engine,wasm=new Engine(await WebAssembly.instantiate(await WebAssembly.compile(await readFile('web/generated/fight.wasm'))));
 for(const face of [-1,1]){
  for(const e of [js,wasm]){e.loadData(data);e.reset([1,5]);e.api.fg_preview_place(0,50000,0,10000);e.api.fg_preview_place(1,50000+face*35000,0,10000);}
  let saves;for(let tick=0;tick<90;++tick){const input=tick===0?INPUT.D:tick===9?INPUT.P:0;js.step(input,0);wasm.step(input,0);assert.equal(js.hash,wasm.hash);if(tick===12)saves=[js.snapshot(),wasm.snapshot()];}
  const expected=js.hash;for(const [i,e]of [js,wasm].entries()){e.restore(saves[i]);for(let tick=13;tick<90;++tick)e.step(0,0);assert.equal(e.hash,expected);}
 }
});
