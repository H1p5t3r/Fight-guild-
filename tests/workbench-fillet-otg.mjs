import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
import {inactiveReason} from '../web/workbench/field-layout.mjs';

const pack=JSON.parse(readFileSync('build/workbench-pack.json'));
const data=pack.draft.data;
const queue=slots=>slots.map((move,i)=>({move,delay:i===slots.length-1?6:0}));

test('Shared editor sequence confirms all three knockdown routes into real Wound captures',()=>{
 const p=new CombatPreview(pack);
 for(const target of [0,1,2,3,4,5])for(const facing of [-1,1])for(const slots of [[6,13],[15,26,13],[15,27,13]]){
  const r=p.recordSequence(data,5,slots[0],queue(slots),{target,facing,gap:0});
  assert.deepEqual(r.warnings,[],`${target}/${facing}/${slots}`);
  assert.ok(r.steps.every(s=>s.start!==undefined));
  assert.ok(r.frames.some(f=>f.state.pairKind===3),'Natural Downed capture, without a pre-downed fixture');
  assert.ok(r.frames.some(f=>f.state.players[1].bleedTime===420),'Applies bleed at release');
  assert.equal(r.steps.at(-1).route,'cancel / buffered link');
 }
});

test('Editor shows named special windows and does not turn a blocked sweep into a Wound cancel',()=>{
 const m=data.characters[5].moves[6];assert.equal(m.specialCancel,0);
 assert.equal(inactiveReason('specialCancelStart',m),'');
 assert.equal(inactiveReason('specialCancelEnd',m),'');
 const p=new CombatPreview(pack),r=p.recordSequence(data,5,6,queue([6,13]),{behavior:'crouch',gap:0});
 assert.ok(r.frames.some(f=>f.state.players[0].event===2),'Sweep is blocked low');
 assert.ok(!r.frames.some(f=>f.state.pairKind===3||f.state.players[1].bleedTime));
 assert.equal(r.steps.at(-1).route,'after recovery');
 const start=r.steps.at(-1).start;
 assert.ok(r.frames[start-1].state.players[0].move<0,'No recovery escape on block');
});
