import {comboMoveDefaults} from '../web/combo-rules.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Engine,INPUT} from '../web/engine.mjs';
import {Workshop} from '../web/workbench/model.mjs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
import {LINE_DEFAULTS} from '../web/line-drive.mjs';
const json=async p=>JSON.parse(await readFile(p,'utf8'));
const pack=await json('build/workbench-pack.json'),baseline=await json('art/characters/shark-kit-v2/baseline-moves.json');
const wasm=await WebAssembly.compile(await readFile('web/generated/fight.wasm'));
test('Shark retains every submitted non-Drive move, disabled slot and movement value',()=>{
 const c=pack.draft.data.characters[4];assert.equal(c.moves.filter(m=>m.enabled).length,26);
 assert.deepEqual(c.movement,baseline.movement);
 for(const [slot,m]of baseline.moves.entries())if(![12,13,21,22].includes(slot))assert.deepEqual(c.moves[slot],{...m,...LINE_DEFAULTS,...comboMoveDefaults(m)},m.id);
 for(const slot of [12,14,15,16])assert.equal(c.moves[slot].enabled,0);
 assert.equal(c.moves[29].button,2,'Keep the saved S mapping despite its legacy j.214P slot ID');
 assert.equal(c.moves[6].knockdown,2,'2S remains the hard-knockdown sweep');
});
test('Schema-23 imports and reset preserve old Drive behavior, notes and newly required defaults',async()=>{
 const old=await json('godot/data/workshop/2026-11-19-fillet-v1/FightGuild-Fillet-v1.json'),copy=structuredClone(old),w=new Workshop(pack,old);
 assert.equal(w.data.schema,26);assert.deepEqual(old,copy);assert.deepEqual(w.data._moveWorkshop,old._moveWorkshop);
 for(const [c,ch]of old.characters.entries())for(const [i,m]of ch.moves.entries())for(const [k,v]of Object.entries(m))assert.deepEqual(w.move(c,i)[k],v,`${c}/${i}/${k}`);
 assert.equal(w.move(4,13).mechanic,1);
 const older=await json('godot/data/workshop/2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json'),legacy=new Workshop(pack,older);
 legacy.resetMove(5,0);assert.equal(JSON.parse(legacy.export()).characters[5].moves[0].tetherDuration,180);
});
test('New line fields round-trip, validate atomically, and stay editable per action',()=>{
 const w=new Workshop(pack,pack.draft.data);w.change(4,13,'tetherDuration',90);w.change(4,22,'tetherGap',8500);w.change(4,22,'tetherFrames',16);
 const e=new CombatPreview(pack).engine;e.loadData(w.data);assert.equal(e.data().characters[4].moves[13].tetherDuration,90);
 assert.equal(e.data().characters[4].moves[22].tetherGap,8500);assert.deepEqual(new Workshop(pack,JSON.parse(w.export())).data,w.data);
 const before=w.export();assert.throws(()=>w.change(4,13,'tetherDuration',0));assert.equal(w.export(),before);
});
test('Editor follows actual tag → reel inputs and separates unmarked and marked utility previews',()=>{
 const p=new CombatPreview(pack);
 for(const facing of [-1,1]){
  const tag=p.record(pack.draft.data,4,13,{facing,mechanic:'followup',target:5,gap:60});
  assert.ok(tag.frames.some(f=>f.state.players[1].tetherTime>0));
  assert.ok(tag.frames.some(f=>f.state.players[0].move===22));
  assert.ok(tag.frames.some(f=>f.state.players[1].linePullTime>0));
  for(const slot of [22]){
   const unmarked=p.record(pack.draft.data,4,slot,{facing,mechanic:'single',target:5,gap:170});
   const marked=p.record(pack.draft.data,4,slot,{facing,mechanic:'followup',target:5,gap:170});
   assert.ok(!unmarked.frames.some(f=>f.state.players[1].linePullTime));
   assert.ok(marked.frames.some(f=>f.state.players[1].linePullTime));
   assert.equal(marked.totalDamage,0);assert.equal(marked.contacts.length,0);
   assert.ok(marked.frames.every(f=>!f.state.players[1].stun&&!f.state.players[1].linePullHeld));
  }
 }
});
test('Plain JS and WASM replay tag and line actions identically in both facings',async()=>{
 const js=new CombatPreview(pack).engine,wa=new Engine(await WebAssembly.instantiate(wasm));
 for(const face of [-1,1])for(const choice of [INPUT.down,face>0?INPUT.right:INPUT.left]){
  for(const e of [js,wa]){e.loadData(pack.draft.data);e.reset([4,5]);e.api.fg_preview_place(0,50000,0,10000);e.api.fg_preview_place(1,50000+face*12000,0,10000);}
  let saves;
  for(let tick=0;tick<130;++tick){const input=tick===0?INPUT.D:tick===65?choice|INPUT.D:0;js.step(input,0);wa.step(input,0);assert.equal(js.hash,wa.hash,`${face}/${choice}/${tick}`);if(tick===40)saves=[js.snapshot(),wa.snapshot()];}
  const expected=js.hash;
  for(const [i,e]of [js,wa].entries()){e.restore(saves[i]);for(let tick=41;tick<130;++tick)e.step(tick===65?choice|INPUT.D:0,0);assert.equal(e.hash,expected);}
 }
});


test('Schema-24 migration retires Chase without losing custom tuning or art notes',()=>{
 const old=structuredClone(pack.draft.data);old.schema=old.coreVersion=24;
 const chase=old.characters[4].moves[12];chase.enabled=1;chase.mechanic=5;chase.tetherSpeed=1789;
 old._moveWorkshop.notes['Shark/6D']={label:'Saved chase study',active:'Keep my pose reference.'};
 const before=structuredClone(old),w=new Workshop(pack,old);
 assert.equal(w.data.schema,26);assert.deepEqual(old,before);
 assert.deepEqual(w.move(4,12),{...chase,...comboMoveDefaults(chase),enabled:0,mechanic:0});
 assert.deepEqual(w.data._moveWorkshop,old._moveWorkshop);
 const e=new CombatPreview(pack).engine;e.loadData(old);assert.equal(e.move(4,12).enabled,0);assert.equal(e.move(4,12).mechanic,0);
});

test('Holding guard or Faultless Defense cannot stop an attached pull or create a block event',()=>{
 const p=new CombatPreview(pack);
 for(const facing of [-1,1])for(const behavior of ['block','fd']){
  const r=p.record(pack.draft.data,4,22,{facing,behavior,mechanic:'followup',target:0,gap:170});
  const pulled=r.frames.filter(f=>f.state.players[1].linePullTime);
  assert.ok(pulled.length>0);assert.equal(r.contacts.length,0);assert.equal(r.totalDamage,0);
  assert.ok(pulled.every(f=>!f.state.players[1].stun&&!f.state.players[1].linePullHeld&&!f.state.hitstop));
  const first=r.frames[0].state.players,last=r.frames.at(-1).state.players;
  assert.ok(Math.abs(first[1].x-first[0].x)>Math.abs(last[1].x-last[0].x));
 }
});
