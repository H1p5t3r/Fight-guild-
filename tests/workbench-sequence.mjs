import {legacyPack,legacyData,stripExtensions} from './legacy-data.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Workshop} from '../web/workbench/model.mjs';
import {CombatPreview,directionBits} from '../web/workbench/simulation.mjs';
import {Engine,INPUT} from '../web/engine.mjs';
import {cursorAnchor,cursorIndex} from '../web/workbench/cursor.mjs';
const shippedPack=JSON.parse(await readFile('build/workbench-pack.json','utf8')),pack=legacyPack(shippedPack);
const queue=(ids,delay=0)=>ids.map((move,i)=>({move,delay:i===1?delay:0}));
function fixture(){
 const data=structuredClone(pack.defaults);
 for(const slot of [0,1,3,8,17])Object.assign(data.characters[5].moves[slot],{startup:5,active:3,recovery:15,damage:20,hitstun:15,hitstop:6,pushback:0,airPushback:0,blockPushback:0,reach:20000,hitboxBack:0,bottom:0,height:20000,knockdown:0,launch:0,airLaunch:0,advance:0,travelSpeed:0,hitboxTimeline:{multiHit:false,keys:[]}});
 return data;
}
test('Sequence queues round-trip per fighter with undo, and reject malformed imports atomically',()=>{
 const w=new Workshop(pack,pack.draft.data),before=w.snapshot();
 w.setSequence(5,queue([0,1,8],7));w.setSequence(4,queue([32,3]));
 const saved=JSON.parse(w.export());assert.deepEqual(new Workshop(pack,saved).sequence(5),queue([0,1,8],7));
 assert.deepEqual(saved.characters,before.characters);assert.deepEqual(saved._moveWorkshop.notes,before._moveWorkshop.notes);
 w.undo();assert.deepEqual(w.sequence(4),[]);w.redo();assert.deepEqual(w.sequence(4),queue([32,3]));
 const stable=w.snapshot();
 for(const bad of [[{move:99,delay:0}],[{move:0,delay:-1}],Array.from({length:13},()=>({move:0,delay:0}))]){
  const file=structuredClone(stable);file._moveWorkshop.sequences.Fillet=bad;
  assert.throws(()=>w.import(file));assert.deepEqual(w.data,stable);
 }
});
test('Automatic timing follows real gatlings, supports delayed links, and never forces a whiff cancel',()=>{
 const data=fixture(),p=new CombatPreview(pack),before=structuredClone(data);
 const immediate=p.recordSequence(data,5,0,queue([0,1,8]),{gap:0});
 assert.equal(immediate.steps.filter(s=>s.start!==undefined).length,3);assert.equal(immediate.contacts.length,3);assert.equal(immediate.maxCombo,3);
 const delayed=p.recordSequence(data,5,0,queue([0,1,8],30),{gap:0});
 assert.equal(delayed.steps.filter(s=>s.start!==undefined).length,3);assert.ok(delayed.steps[1].start>immediate.steps[1].start+20);assert.ok(delayed.maxCombo<immediate.maxCombo);
 const whiff=p.recordSequence(data,5,0,queue([0,1]),{gap:450});
 assert.equal(whiff.contacts.length,0);assert.ok(whiff.steps[1].start>=whiff.steps[0].start+22);
 const illegal=p.recordSequence(data,5,3,queue([3,0]),{gap:0});
 assert.equal(illegal.steps.length,2);assert.ok(illegal.steps[1].start>=illegal.steps[0].start+22);
 assert.deepEqual(data,before);
 const middle=immediate.steps[1].start;
 assert.equal(cursorIndex(immediate,cursorAnchor(immediate,middle)),middle,'Repeated move frames must not rewind the sequence cursor');
});
test('Repeated moves start distinct attacks through hitstop; disabled and contextual inputs report failures',()=>{
 const data=fixture(),p=new CombatPreview(pack),record=p.recordSequence(data,5,0,queue([0,0,0]),{gap:0});
 assert.equal(record.contacts.length,3);assert.ok(record.steps.every((s,i)=>s.start!==undefined&&(!i||s.start>record.steps[i-1].start)));
 data.characters[5].moves[0].enabled=0;
 const disabled=p.recordSequence(data,5,0,queue([0,1]),{gap:0});assert.equal(disabled.executed,false);assert.equal(disabled.contacts.length,0);assert.match(disabled.warnings[0],/disabled/);
 const stance=p.recordSequence(pack.draft.data,3,35,queue([35]),{gap:0});assert.equal(stance.executed,false);assert.ok(stance.warnings.length);
});
test('Jump-cancel sequences use a real jump input, and first-step delays are editable',()=>{
 const data=fixture(),p=new CombatPreview(pack);
 data.characters[5].moves[1].jumpCancel=1;
 const record=p.recordSequence(data,5,1,queue([1,17]),{gap:0});
 assert.equal(record.steps.filter(s=>s.start!==undefined).length,2);assert.ok(record.frames.some(f=>f.input&INPUT.up));
 assert.ok(record.frames[record.steps[1].start].state.players[0].y>0);
 const delayed=p.recordSequence(data,5,0,[{move:0,delay:12}],{gap:0});assert.equal(delayed.steps[0].start,13);
});
test('The current Fillet rekka routes, Tapper stance entries and Smoke projectile run through their actual commands',()=>{
 const p=new CombatPreview(pack),data=pack.draft.data;
 for(const ids of [[15,26,27],[15,27]]){
  const r=p.recordSequence(data,5,ids[0],queue(ids),{gap:0});
  assert.equal(r.steps.filter(s=>s.start!==undefined).length,ids.length);assert.equal(r.maxCombo,ids.length);assert.deepEqual(r.warnings,[]);
 }
 for(const ids of [[13,37,38,39],[24,37]]){
  const r=p.recordSequence(data,3,ids[0],queue(ids),{gap:0});assert.deepEqual(r.warnings,[]);
  assert.ok(r.frames[r.steps[1].start].state.players[0].stance,'Drive and normal throw both lead into rolling stance');
  if(ids.at(-1)===39)assert.equal(r.frames.at(-1).state.players[0].stance,0,'2D exits the stance');
 }
 const projectile=p.recordSequence(data,2,14,queue([14]),{gap:0});assert.deepEqual(projectile.warnings,[]);
 assert.ok(projectile.frames.some(f=>f.state.projectiles.length));assert.ok(projectile.contacts.length);
 const simple=p.recordSequence(data,5,0,queue([0,1,15,27]),{gap:0,simple:true});
 assert.equal(simple.steps.filter(s=>s.start!==undefined).length,4);assert.ok(simple.frames.some(f=>f.input&INPUT.simple));
});
test('Saved sequence inputs reproduce the exact WASM state in both facings, including guarding',async()=>{
 const wasm=new Engine((await WebAssembly.instantiate(await readFile('web/generated/fight.wasm'))).instance),data=fixture(),p=new CombatPreview(pack);
 for(const facing of [1,-1])for(const behavior of ['hit','block']){
  const record=p.recordSequence(data,5,0,queue([0,1,8],3),{gap:0,facing,behavior});
  assert.deepEqual(p.recordSequence(data,5,0,queue([0,1,8],3),{gap:0,facing,behavior}),record);
  wasm.loadData(data);wasm.reset([5,4]);const origin=facing===1?45000:55000,gap=pack.collisions[5].push.halfWidth+pack.collisions[4].push.halfWidth;
  wasm.api.fg_preview_place(0,origin,0,10000);wasm.api.fg_preview_place(1,origin+facing*gap,0,10000);
  for(const frame of record.frames.slice(1)){
   wasm.step(frame.input,behavior==='block'?directionBits(4,wasm.state().players[1].facing):0);
   assert.deepEqual(wasm.state(),frame.state);
  }
  assert.equal(wasm.attackSerial(),3);
 }
});
