import {LINE_DEFAULTS} from '../web/line-drive.mjs';
import {legacyPack} from './legacy-data.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Workshop,blockAdvantage,moveName} from '../web/workbench/model.mjs';
import {CombatPreview,directionBits} from '../web/workbench/simulation.mjs';
import {Engine,INPUT} from '../web/engine.mjs';
const json=async p=>JSON.parse(await readFile(p,'utf8'));
const pack=legacyPack(await json('build/workbench-pack.json')),data=new Workshop(pack,await json('godot/data/workshop/2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json')).data;
const wasm=await WebAssembly.compile(await readFile('web/generated/fight.wasm'));
const make=async(c,facing=1,distance=data.characters[c].moves[2].proximityRange,source=data)=>{
 const e=new Engine(await WebAssembly.instantiate(wasm));e.loadData(source);e.reset([c,c===4?5:4]);
 e.api.fg_preview_place(0,50000,0,10000);e.api.fg_preview_place(1,50000+facing*distance,0,10000);return e;
};
test('Slash/sweep batch preserves all other tuning, notes, photos and stable slot IDs',async()=>{
 const before=await json('godot/data/workshop/2026-11-19-user/FightGuild-moves-2026-11-19.json');
 for(const c of before.characters)for(const m of c.moves)Object.assign(m,LINE_DEFAULTS);
 for(const key of Object.keys(before).filter(k=>!['characters','_moveWorkshop','schema','coreVersion'].includes(k)))assert.deepEqual(data[key],before[key]);
 for(let c=0;c<6;c++){
  assert.deepEqual(data.characters[c].movement,before.characters[c].movement);
  for(let slot=0;slot<45;slot++)if(![2,6,32].includes(slot))assert.deepEqual(data.characters[c].moves[slot],before.characters[c].moves[slot]);
  if(before.characters[c].moves[32].enabled)assert.deepEqual(data.characters[c].moves[32],before.characters[c].moves[32]);
  assert.equal(data.characters[c].moves[2].id,'5S');assert.equal(moveName(data.characters[c].moves[2]),'f.S');
 }
 for(const [name,note]of Object.entries(before._moveWorkshop.notes))for(const [key,value]of Object.entries(note)){
  if(key==='intent')assert.ok(data._moveWorkshop.notes[name][key].startsWith(value));
  else assert.deepEqual(data._moveWorkshop.notes[name][key],value);
 }
 assert.deepEqual(JSON.parse(new Workshop(pack,data).export()),data);
 const e=await make(5);
 assert.notEqual(e.api.fg_collision_hash()>>>0,1356424751,'Reject the pre-Slash rule fingerprint even with identical pose geometry and move JSON');
});
test('Standing S resolves c.S/f.S at the exact editable boundary in both facings for every fighter',async()=>{
 for(let c=0;c<6;c++)for(const facing of [1,-1])for(const offset of [-1,0,1]){
  const e=await make(c,facing,data.characters[c].moves[2].proximityRange+offset);e.step(INPUT.S,0);
  assert.equal(e.state().players[0].move,offset<=0?32:2,`${c}/${facing}/${offset}`);
 }
 const disabled=structuredClone(data);disabled.characters[5].moves[32].enabled=0;
 const e=await make(5,1,8000,disabled);e.step(INPUT.S,0);assert.equal(e.state().players[0].move,2);
 const simple=structuredClone(data);Object.assign(simple.characters[5].moves[2],{simpleDirection:5,simpleButton:2});
 const p=new CombatPreview(pack);assert.ok(p.record(simple,5,32,{gap:0,simple:true}).executed);
 assert.equal(p.record(simple,5,32,{gap:200,simple:true}).executed,false);
});
test('c.S chains into f.S and sweep on contact; whiff, custom routes, disabled moves and stance still apply',async()=>{
 for(let c=0;c<6;c++)for(const facing of [1,-1])for(const blocked of [false,true]){
  const fixture=structuredClone(data),m=fixture.characters[c].moves[32];Object.assign(m,{pushback:0,blockPushback:0});
  const e=await make(c,facing,7500,fixture),guard=blocked?directionBits(4,-facing):0;
  e.step(INPUT.S,guard);
  for(let t=0;t<80&&!e.state().players[0].contact;t++)e.step(0,guard);
  assert.ok(e.state().players[0].contact,`${c} c.S must contact`);
  while(e.state().hitstop)e.step(0,guard);
  assert.equal(e.api.fg_can_cancel(c,32,2,1),1);assert.equal(e.api.fg_can_cancel(c,32,6,1),1);
  assert.equal(e.api.fg_can_cancel(c,2,32,1),0);assert.equal(e.api.fg_can_cancel(c,32,2,0),0);
  const snapshot=e.snapshot();e.step(INPUT.S,guard);assert.equal(e.state().players[0].move,2);
  const hash=e.hash;e.restore(snapshot);e.step(INPUT.S,guard);assert.equal(e.hash,hash);
  e.restore(snapshot);e.step(INPUT.down|INPUT.S,guard);assert.equal(e.state().players[0].move,6);
 }
 const fixture=structuredClone(data);fixture.characters[5].moves[32].normalRoutes=0;
 const e=await make(5,1,7500,fixture);assert.equal(e.api.fg_can_cancel(5,32,2,1),0);
});
test('Buffered S checks distance when recovery ends, and sequence preview uses the real contextual route',async()=>{
 const e=await make(5,1,40000),m=data.characters[5].moves[0];e.step(INPUT.P,0);
 while(e.state().players[0].age<m.startup+m.active+m.recovery-3)e.step(0,0);
 e.api.fg_preview_place(1,57500,0,0);e.step(INPUT.S,0);assert.equal(e.state().players[0].move,0);
 e.api.fg_preview_place(1,59000,0,0);
 for(let n=0;n<5&&e.state().players[0].move!==2;n++)e.step(0,0);
 assert.equal(e.state().players[0].move,2);
 const p=new CombatPreview(pack),record=p.recordSequence(data,5,32,[{move:32,delay:0},{move:2,delay:0},{move:3,delay:0}],{gap:0});
 assert.ok(record.steps.every(s=>s.start!==undefined),JSON.stringify(record.steps));
 assert.equal(record.steps[1].route,'cancel / buffered link');
 const mismatch=p.record(data,5,32,{gap:200});assert.equal(mismatch.executed,false);assert.ok(mismatch.warnings.some(w=>/spacing/.test(w)));
});
test('All six 2S sweeps hit low, hard-knock down, and allow a real close-range punish on block',async()=>{
 for(let c=0;c<6;c++){
  const m=data.characters[c].moves[6];assert.equal(m.hitLevel,1);assert.equal(m.knockdown,2);assert.equal(m.specialCancel,1);assert.equal(m.jumpCancel,0);
  assert.ok(blockAdvantage(m)<=-12);assert.ok(m.blockstun-m.recovery<=-7);
  for(const facing of [1,-1]){
   const diagonal=structuredClone(data);diagonal.characters[c].moves[10].enabled=1;
   for(const direction of [1,2,3]){
    const input=await make(c,facing,7500,diagonal);input.step(directionBits(direction,facing)|INPUT.S,0);
    assert.equal(input.state().players[0].move,6,`${c}/${facing}/${direction}S: sweep takes priority over 6S`);
   }
   const p=new CombatPreview(pack),hit=p.record(data,c,6,{gap:0,facing});
   assert.ok(hit.contacts.length===1,`${c} sweep connects once`);
   assert.ok(hit.frames.some(f=>f.state.players[1].knockdown===2&&f.state.players[1].reaction===2));
   const separation=pack.collisions[c].push.halfWidth+pack.collisions[c===4?5:4].push.halfWidth;
   // Present the target at the active frame so holding back cannot walk out of
   // range during startup. Test standing guard and the last active frame too.
   for(const late of [false,true]){
    const guardCheck=await make(c,facing,40000);guardCheck.step(INPUT.down|INPUT.S,0);
    while(guardCheck.state().players[0].age<m.startup+(late?m.active-1:0)-1)guardCheck.step(0,0);
    guardCheck.api.fg_preview_place(1,guardCheck.state().players[0].x+facing*separation,0,0);
    guardCheck.step(0,directionBits(late?1:4,-facing));
    assert.equal(guardCheck.state().players[0].event,late?2:1,`${c}/${facing}: low guard at ${late?'last':'first'} active`);
    if(late)assert.ok(guardCheck.state().players[1].blockAdvantage<=-7);
   }
   const e=await make(c,facing,separation);
   const guard=directionBits(1,-facing);e.step(INPUT.down|INPUT.S,guard);
   for(let t=0;t<100&&!e.state().players[1].guarding;t++)e.step(0,guard);
   assert.ok(e.state().players[1].guarding,`${c}: crouch guard`);
   assert.ok(e.state().players[1].blockAdvantage<=-12);
   while(e.state().hitstop||e.state().players[1].stun)e.step(0,guard);
   e.step(0,INPUT.down|INPUT.K); // A fast low reaches a crouching sweep's recovery pose.
   for(let t=0;t<12&&!e.state().players[1].contact;t++)e.step(0,0);
   assert.equal(e.state().players[1].event,4,`${c}/${facing}: sweep must be punishable`);
  }
 }
});
