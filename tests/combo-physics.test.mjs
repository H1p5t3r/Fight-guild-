import {upgradeStepDrive} from '../web/step-drive.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Engine} from '../web/engine.mjs';
import {upgradeComboPhysics} from '../web/combo-rules.mjs';
import {rollbackTrial} from '../web/rollback.mjs';
const module=await WebAssembly.compile(readFileSync('web/generated/fight.wasm'));
const old=JSON.parse(readFileSync('godot/data/workshop/2026-11-20-fillet-otg/FightGuild-Fillet-OTG.json'));
const create=async()=>new Engine(await WebAssembly.instantiate(module));
test('Schema 25 migration preserves authoring data and creates editable velocity/decay controls',async()=>{
 const before=structuredClone(old),data=upgradeComboPhysics(old),e=await create();
 assert.deepEqual(old,before);assert.equal(data.schema,26);assert.equal(data.comboRules.comboPhysics,1);
 assert.deepEqual(data._moveWorkshop,old._moveWorkshop);
 for(const [c,ch]of old.characters.entries())for(const [i,m]of ch.moves.entries()){
  const upgraded=data.characters[c].moves[i];
  for(const [key,value]of Object.entries(m))assert.deepEqual(upgraded[key],value,`${c}/${i}/${key}`);
  assert.equal(upgraded.groundHitSpeed,Math.ceil(m.pushback/6));assert.equal(upgraded.airHitSpeed,Math.ceil(m.airPushback/6));
 }
 e.loadData(data);const {_moveWorkshop,...gameplay}=data;assert.deepEqual(e.data(),upgradeStepDrive(gameplay));
 const fingerprint=e.fingerprint();data.comboRules.launchCarry=35;e.loadData(data);assert.notEqual(e.fingerprint(),fingerprint);
 const valid=e.fingerprint();data.comboRules.airHitDrag=101;assert.throws(()=>e.loadData(data));assert.equal(e.fingerprint(),valid);
 data.comboRules.airHitDrag=98;data.characters[2].moves[7].comboDecay=-1;assert.throws(()=>e.loadData(data));assert.equal(e.fingerprint(),valid);
});
test('Modern decay and velocity snapshots repair delayed and reordered inputs',async()=>{
 for(const latency of [1,6,12]){
  const a=await create(),b=await create();a.reset([4,2]);b.reset([4,2]);
  const result=rollbackTrial(a,b,{frames:1500,latency,jitter:4});
  assert.ok(result.pass,JSON.stringify(result));assert.ok(result.rollbacks>0);
 }
});
