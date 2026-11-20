import {legacyPack,legacyData,stripExtensions} from './legacy-data.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Workshop,inputName} from '../web/workbench/model.mjs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
const shippedPack=JSON.parse(await readFile('build/workbench-pack.json','utf8')),pack=legacyPack(shippedPack);
test('Third upload preserves the untouched fighters alongside the new Smoke and Tapper kits',async()=>{
 const original=JSON.parse(await readFile('godot/data/workshop/2026-11-17-batch-03/FightGuild-moves-2026-11-17 _2_.json','utf8'));
 const baseline=JSON.parse(await readFile('godot/data/workshop/2026-11-18-user-smoke/FightGuild-Smoke-Animations.json','utf8'));
 const w=new Workshop(pack,baseline), data=w.snapshot();
 for(let c=0;c<6;++c){if(c===2||c===3)continue;
  assert.deepEqual(data.characters[c].movement,{...original.characters[c].movement,airDashPauseFrames:4,airBackdashPauseFrames:4});
  for(let i=0;i<32;++i)for(const [key,value] of Object.entries(original.characters[c].moves[i])) assert.deepEqual(data.characters[c].moves[i][key],key==='startup'&&original.characters[c].moves[i].category===4&&!original.characters[c].moves[i].motion?2:value,`${c}/${i}/${key}`);
 }
 for(const [key,value] of Object.entries(original._moveWorkshop.notes))assert.deepEqual(data._moveWorkshop.notes[key],value);
 const old=new Workshop(pack,original);assert.equal(old.data.schema,25);assert.equal(old.move(3,35).enabled,0);assert.equal(old.move(3,0).startup,original.characters[3].moves[0].startup);
 w.change(3,40,'grabFrames',30);w.change(3,37,'stanceRequired',2);assert.deepEqual(new Workshop(pack,JSON.parse(w.export())).data,w.data);
 assert.equal(inputName(w.move(3,40)),'st.236D');
});
test('Tapper preview executes his stance attacks, capture/finish, idle and finite step dash',()=>{
 const p=new CombatPreview(pack),data=pack.draft.data;
 for(const facing of [1,-1]){
  const tackle=p.record(data,3,40,{gap:60,facing,behavior:'block'});
  assert.equal(tackle.contacts.length,1);assert.equal(tackle.contacts[0].damage,140);
  assert.ok(tackle.frames.some(f=>f.state.players[1].reaction===6));
  assert.ok(tackle.frames.some(f=>f.state.players[0].poseIndex===30));
  assert.equal(tackle.frames.at(-1).state.players[0].stance,1);
  const exit=p.record(data,3,39,{facing});assert.equal(exit.contacts.length,0);assert.equal(exit.frames.at(-1).state.players[0].stance,0);
  const hook=p.record(data,3,37,{facing,behavior:'block'});assert.equal(hook.contacts[0].event,2);assert.equal(hook.frames.find(f=>f.contact).state.players[1].blockAdvantage,3);
 }
 const roll=p.recordMovement(data,3,0,'rolling');assert.ok(roll.frames.every(f=>f.state.players[0].posePhase===8));assert.equal(new Set(roll.frames.map(f=>f.state.players[0].poseIndex)).size,4);
 const step=p.recordMovement(data,3,0,'forward');assert.ok(step.frames.some(f=>f.state.players[0].posePhase===7));assert.ok(step.frames.every(f=>!f.state.players[0].running));
 assert.equal(pack.art[3].signature_active.frames.length,32);assert.equal(pack.art[3].walk.frames.length,8);
});
