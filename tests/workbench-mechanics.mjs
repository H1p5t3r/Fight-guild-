import {legacyPack,legacyData,stripExtensions} from './legacy-data.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Workshop} from '../web/workbench/model.mjs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
import {MECHANIC_FIELDS} from '../web/mechanics-data.mjs';
const shippedPack=JSON.parse(await readFile('build/workbench-pack.json','utf8')),pack=legacyPack(shippedPack);
test('Batch 2 upgrades without losing any submitted value or art note',async()=>{
 const original=JSON.parse(await readFile('godot/data/workshop/2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json','utf8'));
 const w=new Workshop(pack,original), upgraded=w.snapshot();
 assert.equal(upgraded.schema,26);assert.deepEqual(upgraded._moveWorkshop,original._moveWorkshop);
 for(const [c,ch] of original.characters.entries())for(const [i,m] of ch.moves.entries())for(const [k,v] of Object.entries(m))assert.deepEqual(upgraded.characters[c].moves[i][k],v,`${ch.name} ${m.id} ${k}`);
 assert.equal(w.move(4,13).mechanic,1);assert.equal(w.move(4,22).mechanic,1);assert.equal(w.move(5,13).mechanic,2);
 w.change(5,13,'bleedBlockPercent',35);w.change(5,13,'variantStartup',18);
 assert.equal(new Workshop(pack,w.snapshot()).move(5,13).bleedBlockPercent,35);
 const invalid=w.snapshot();invalid.characters[5].moves[13].variantStartup=1;assert.throws(()=>new Workshop(pack,invalid));
});
test('Preview simulates application, pull, cash-out and timeout with real core state',async()=>{
 const preview=new CombatPreview(pack),legacy=new Workshop(pack,JSON.parse(await readFile('godot/data/workshop/2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json','utf8'))).data;
 for(const face of [1,-1]){
  const pull=preview.record(legacy,4,13,{mechanic:'followup',facing:face});
  assert.equal(pull.contacts.length,1,'Pull does not manufacture a second hit');
  const active=pull.frames.find(f=>f.state.players[1].tetherUsed);
  assert.ok(active);assert.equal(active.state.players[0].variant,1);assert.ok(active.state.players[1].vx*face<0);
  assert.equal(active.boxes[0].hit.length,0,'Non-damaging pull has no strike hitbox');
  const cash=preview.record(pack.draft.data,5,13,{mechanic:'followup',facing:face});
  assert.equal(cash.contacts.length,2);assert.ok(cash.contacts[1].damage>60);
  assert.ok(cash.frames.some(f=>f.state.players[0].variant===2&&f.state.players[0].y>0));
  assert.equal(cash.frames.at(-1).state.players[1].greyLife,0);
 }
 const expire=preview.record(pack.draft.data,5,13,{mechanic:'expire'});
 const last=expire.frames.at(-1).state.players[1];assert.equal(last.health,955);assert.equal(last.bleedTime,0);assert.equal(last.greyLife,0);
 const off=structuredClone(pack.draft.data);off.characters[5].moves[13].mechanic=0;
 const noStatus=preview.record(off,5,13,{mechanic:'followup'});assert.ok(noStatus.frames.every(f=>!f.state.players[1].bleedTime));assert.equal(noStatus.contacts.length,1);
});
test('Authored mechanic fields survive core round-trip and deterministic snapshot restore',()=>{
 const p=new CombatPreview(pack),e=p.engine;e.loadData(pack.draft.data);
 for(const c of [4,5])for(const k of MECHANIC_FIELDS)assert.equal(e.data().characters[c].moves[13][k],pack.draft.data.characters[c].moves[13][k]);
 e.reset([5,4]);e.api.fg_preview_place(1,48000,0,10000);e.step(256,0);for(let i=0;i<35;++i)e.step(0,0);
 assert.ok(e.state().players[1].bleedTime);const snapshot=e.snapshot();for(let i=0;i<80;++i)e.step(0,0);const hash=e.hash;e.restore(snapshot);for(let i=0;i<80;++i)e.step(0,0);assert.equal(e.hash,hash);
});
