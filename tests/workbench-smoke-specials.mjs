import {STEP_DRIVE_DEFAULTS} from '../web/step-drive.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {CombatPreview} from '../web/workbench/simulation.mjs';

const json=async file=>JSON.parse(await readFile(file,'utf8'));
const pack=await json('build/workbench-pack.json'),data=pack.draft.data,art=pack.art[2];
const baseline=await json('art/characters/smoke-specials-v3/baseline-moves.json');
const before=await json('art/characters/smoke-specials-v3/before.json');
const actions=[[15,145],[16,230],[14,96],[25,246]];
const cue=f=>f.state.players[0].posePhase===14?art.attack_animation.frames[f.state.players[0].poseIndex]:null;

test('Smoke animation registration preserves authored moves and identical near/far projectile art',()=>{
 for(const [slot] of actions)assert.deepEqual(data.characters[2].moves[slot],{...baseline.moves[slot],...STEP_DRIVE_DEFAULTS});
 assert.deepEqual(art.projectile_variants['14'],art.projectile_variants['25']);
 for(const key of ['projectileWidth','projectileHeight'])assert.equal(data.characters[2].moves[14][key],data.characters[2].moves[25][key]);
 assert.equal(data.characters[2].moves[14].projectileOffsetX,15000);
 assert.equal(data.characters[2].moves[25].projectileOffsetX,30000);
});

test('Both facings retain actual hit/block/whiff outcomes, contact hold and timed recovery',()=>{
 const preview=new CombatPreview(pack);
 for(const facing of [1,-1])for(const [slot,gap] of actions)for(const behavior of ['hit','block','whiff']){
  const old=before.find(m=>m.character===2&&m.slot===slot).scenarios[behavior];
  const record=preview.record(data,2,slot,{facing,gap:behavior==='whiff'?450:gap,behavior:behavior==='whiff'?'hit':behavior});
  assert.ok(record.executed);assert.equal(record.contacts.length,old.filter(f=>f.contact).length);
  assert.equal(record.totalDamage,old.at(-1).damage);
  const m=data.characters[2].moves[slot],first=record.frames.find(f=>f.selectedFrame===m.startup);
  assert.match(cue(first).motion_cue,/First-active/);
  assert.ok(record.frames.some(f=>/Follow-through/.test(cue(f)?.motion_cue??'')));
  assert.ok(record.frames.some(f=>/Collect|Withdraw/.test(cue(f)?.motion_cue??'')));
  if(behavior==='whiff')assert.ok(record.frames.every(f=>!f.state.hitstop));
  for(let i=1;i<record.frames.length;i++)if(record.frames[i-1].state.hitstop){
   const p=record.frames[i-1].state.players[0],n=record.frames[i].state.players[0];
   assert.equal(n.age,p.age);assert.equal(n.posePhase,p.posePhase);assert.equal(n.poseIndex,p.poseIndex);
   assert.deepEqual(record.frames[i].state.projectiles,record.frames[i-1].state.projectiles);
  }
 }
});

test('Edited attack phases rescale held poses and keep the large arc/projectile on first active',()=>{
 const preview=new CombatPreview(pack);
 for(const [slot]of actions)for(const short of [false,true]){
  const edited=structuredClone(data),m=edited.characters[2].moves[slot];
  Object.assign(m,{startup:short?5:m.startup+13,active:short?1:17,recovery:short?2:43});
  const record=preview.record(edited,2,slot,{gap:450});
  for(const frame of record.frames.filter(f=>f.selectedFrame>0&&f.selectedFrame<m.startup)){
   assert.doesNotMatch(cue(frame)?.motion_cue??'',/First-active/);
   assert.ok(!frame.state.projectiles.length);
   const effect=cue(frame)?.effect;if(effect)assert.ok(effect.box[2]<=80,'No full attack arc during startup');
  }
  const first=record.frames.find(f=>f.selectedFrame===m.startup);
  assert.match(cue(first).motion_cue,/First-active/);
  if(m.projectileKind)assert.equal(first.state.projectiles.length,1);
  else assert.ok(cue(first).effect.box[2]>=250,'Contact shows the authored reach');
 }
});

test('Rollback restores Smoke body, effect cue and projectile lifetime through contact freeze',()=>{
 const preview=new CombatPreview(pack),e=preview.engine;
 for(const [slot,gap]of actions){
  e.loadData(data);e.reset([2,5]);e.api.fg_preview_place(0,40000,0,0);e.api.fg_preview_place(1,40000+(gap+54)*100,0,0);e.step(0,0);e.api.fg_preview_begin(0,slot);
  for(let i=0;i<120&&!e.state().hitstop;i++)e.step(0,0);
  assert.ok(e.state().hitstop);const snap=e.snapshot(),trace=[];
  for(let i=0;i<75;i++){e.step(0,0);trace.push(e.state());}
  e.restore(snap);
  for(const expected of trace){e.step(0,0);assert.deepEqual(e.state(),expected);}
 }
});
